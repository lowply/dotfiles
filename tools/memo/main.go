package main

import (
	"bufio"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"text/tabwriter"
	"time"

	"github.com/lowply/markdownstore"
)

var generateMemoID = newMemoID

func main() {
	if err := run(os.Args[1:], os.Stdin, os.Stdout); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func run(args []string, stdin io.Reader, stdout io.Writer) error {
	if len(args) == 0 {
		return usageError()
	}
	if args[0] == "help" {
		if len(args) == 1 {
			_, err := fmt.Fprintln(stdout, usageText)
			return err
		}
		if len(args) != 2 {
			return fmt.Errorf("usage: memo help [command]")
		}
		return writeCommandHelp(stdout, args[1])
	}
	if len(args) == 2 && (args[1] == "--help" || args[1] == "-h") {
		return writeCommandHelp(stdout, args[0])
	}
	switch args[0] {
	case "create":
		return runCreate(args[1:], stdin, stdout)
	case "search":
		return runSearch(args[1:], stdout)
	case "get":
		return runGet(args[1:], stdout)
	case "show":
		return runShow(args[1:], stdout)
	case "list":
		return runList(args[1:], stdout)
	case "done":
		return runDone(args[1:], stdout)
	case "remove", "rm":
		return runRemove(args[1:], stdin, stdout)
	default:
		return fmt.Errorf("unknown command %q\n\n%w", args[0], usageError())
	}
}

const usageText = `usage: memo <command> [options]

commands:
  create          create a canonical Markdown memo
  search          search all canonical Markdown memos
  get             get one memo's path by ID
  show            print one memo's body by ID
  list            list all canonical Markdown memos
  done            mark a memo done by ID
  remove, rm      delete a memo by ID
  help            show command help

run "memo help <command>" or "memo <command> --help" for details`

var commandHelp = map[string]string{
	"create": `usage: memo create [--repository <owner/name> | --no-repository] <title>

Create a wip memo. Piped or redirected stdin becomes the memo body; terminal stdin creates an empty body. By default, the repository is detected from remote.origin.url when available; otherwise the memo is unscoped. The title becomes the searchable summary and its kebab-case form becomes the memo name.

options:
  --repository     explicitly associate the memo with an owner/name repository
  --no-repository  create an unscoped memo even when a repository can be detected`,
	"search": `usage: memo search [--limit <count>] [--status <wip|done>] -- <query>

Reconcile canonical Markdown files, then search repository names, memo names, summaries, and bodies. Every query term must match.

options:
  --limit   maximum result count from 1 to 100 (default: 5)
  --status  optional wip or done filter`,
	"get": `usage: memo get <id>

Reconcile canonical Markdown files, then return the exact ID's path as JSON.`,
	"show": `usage: memo show [--raw] <id>

Reconcile canonical Markdown files, then print the body of the memo with the exact ID.

options:
  --raw  print the complete canonical file, including YAML frontmatter`,
	"list": `usage: memo list [--status <wip|done>]

Reconcile and list canonical Markdown memos, oldest first.

options:
  --status  optional wip or done filter`,
	"done": `usage: memo done <id>

Atomically mark one canonical Markdown memo done and refresh its updated timestamp.`,
	"remove": `usage: memo remove [--force] <id>

Delete one canonical Markdown memo and its search index record. Confirmation is required unless --force is set.`,
	"rm": `usage: memo rm [--force] <id>

Alias for memo remove.`,
}

func usageError() error {
	return errors.New(usageText)
}

func writeCommandHelp(writer io.Writer, command string) error {
	help, ok := commandHelp[command]
	if !ok {
		return fmt.Errorf("unknown command %q\n\n%w", command, usageError())
	}
	_, err := fmt.Fprintln(writer, help)
	return err
}

func indexContext() (*store, string, error) {
	directory, err := defaultMemoDirectory()
	if err != nil {
		return nil, "", err
	}
	databasePath, err := defaultDatabasePath()
	if err != nil {
		return nil, "", err
	}
	index, err := openIndexAt(directory, databasePath)
	if err != nil {
		return nil, "", err
	}
	if err := reconcile(directory, index); err != nil {
		index.close()
		return nil, "", err
	}
	return index, directory, nil
}

func runCreate(args []string, stdin io.Reader, stdout io.Writer) error {
	flags := flag.NewFlagSet("create", flag.ContinueOnError)
	flags.SetOutput(io.Discard)
	repositoryOverride := flags.String("repository", "", "repository owner/name")
	noRepository := flags.Bool("no-repository", false, "create an unscoped memo")
	if err := flags.Parse(args); err != nil {
		return err
	}
	if flags.NArg() != 1 {
		return fmt.Errorf("usage: memo create [--repository <owner/name> | --no-repository] <title>")
	}
	repositoryOverrideSet := false
	flags.Visit(func(item *flag.Flag) {
		if item.Name == "repository" {
			repositoryOverrideSet = true
		}
	})
	if repositoryOverrideSet && *noRepository {
		return fmt.Errorf("--repository and --no-repository cannot be used together")
	}
	title := strings.TrimSpace(flags.Arg(0))
	if title == "" {
		return fmt.Errorf("memo title must not be empty")
	}
	name, err := titleToName(title)
	if err != nil {
		return err
	}
	body, err := readMemoBody(stdin)
	if err != nil {
		return err
	}
	directory, err := defaultMemoDirectory()
	if err != nil {
		return err
	}
	repositoryName := ""
	switch {
	case repositoryOverrideSet:
		repositoryName = strings.TrimSpace(*repositoryOverride)
		owner, name, err := parseRepositoryName(repositoryName)
		if err != nil {
			return err
		}
		repositoryName = owner + "/" + name
	case !*noRepository:
		repositoryName, err = resolveRepository()
		if err != nil {
			return err
		}
	}
	index, _, err := indexContext()
	if err != nil {
		return err
	}
	defer index.close()
	now := time.Now()
	id := ""
	for range 100 {
		candidate, err := generateMemoID()
		if err != nil {
			return err
		}
		exists, err := index.hasID(candidate)
		if err != nil {
			return err
		}
		if !exists {
			id = candidate
			break
		}
	}
	if id == "" {
		return fmt.Errorf("could not generate a unique memo ID")
	}
	item := memo{
		ID:         id,
		Repository: repositoryName,
		Name:       name,
		Summary:    title,
		Body:       body,
		Status:     "wip",
		CreatedAt:  formatTimestamp(now),
		UpdatedAt:  formatTimestamp(now),
	}
	path, err := canonicalMemoPath(directory, now, item)
	if err != nil {
		return err
	}
	if _, err := index.inner.Create(path, recordFromMemo(item)); err != nil {
		return err
	}
	created, err := index.getByID(id)
	if err != nil {
		return err
	}
	return writeJSON(stdout, created)
}

func readMemoBody(stdin io.Reader) (string, error) {
	if file, ok := stdin.(*os.File); ok {
		info, err := file.Stat()
		if err != nil {
			return "", fmt.Errorf("inspect stdin: %w", err)
		}
		if info.Mode()&os.ModeCharDevice != 0 {
			return "", nil
		}
	}
	body, err := io.ReadAll(stdin)
	if err != nil {
		return "", fmt.Errorf("read memo body from stdin: %w", err)
	}
	return string(body), nil
}

func titleToName(title string) (string, error) {
	var result strings.Builder
	separator := false
	for _, character := range strings.ToLower(strings.TrimSpace(title)) {
		if (character >= 'a' && character <= 'z') || (character >= '0' && character <= '9') {
			if separator && result.Len() > 0 {
				result.WriteByte('-')
			}
			result.WriteRune(character)
			separator = false
		} else {
			separator = true
		}
	}
	name := result.String()
	if name == "" {
		return "", fmt.Errorf("memo title must contain a letter or number")
	}
	return name, nil
}

func canonicalMemoPath(directory string, createdAt time.Time, item memo) (string, error) {
	parts := []string{
		createdAt.UTC().Format("2006-01-02"),
		item.ID,
	}
	if item.Repository != "" {
		owner, repository, err := parseRepositoryName(item.Repository)
		if err != nil {
			return "", err
		}
		parts = append(parts, owner, repository)
	}
	parts = append(parts, item.Name)
	filename := strings.Join(parts, "-") + ".md"
	return filepath.Join(directory, filename), nil
}

func runSearch(args []string, stdout io.Writer) error {
	flags := flag.NewFlagSet("search", flag.ContinueOnError)
	flags.SetOutput(io.Discard)
	limit := flags.Int("limit", 5, "maximum result count")
	status := flags.String("status", "", "filter by wip or done")
	if err := flags.Parse(args); err != nil {
		return err
	}
	query := strings.TrimSpace(strings.Join(flags.Args(), " "))
	if query == "" {
		return fmt.Errorf("search query must not be empty")
	}
	if *limit < 1 || *limit > 100 {
		return fmt.Errorf("limit must be between 1 and 100")
	}
	if err := validateOptionalStatus(*status); err != nil {
		return err
	}
	index, _, err := indexContext()
	if err != nil {
		return err
	}
	defer index.close()
	results, err := index.search(query, *status, *limit)
	if err != nil {
		return err
	}
	return writeJSON(stdout, results)
}

func runGet(args []string, stdout io.Writer) error {
	if len(args) != 1 || args[0] == "" {
		return fmt.Errorf("usage: memo get <id>")
	}
	index, _, err := indexContext()
	if err != nil {
		return err
	}
	defer index.close()
	item, err := index.getByID(args[0])
	if err != nil {
		return err
	}
	return writeJSON(stdout, struct {
		Path string `json:"path"`
	}{Path: item.Path})
}

func runShow(args []string, stdout io.Writer) error {
	flags := flag.NewFlagSet("show", flag.ContinueOnError)
	flags.SetOutput(io.Discard)
	raw := flags.Bool("raw", false, "print YAML frontmatter and body")
	if err := flags.Parse(args); err != nil {
		return err
	}
	if flags.NArg() != 1 || flags.Arg(0) == "" {
		return fmt.Errorf("usage: memo show [--raw] <id>")
	}
	index, _, err := indexContext()
	if err != nil {
		return err
	}
	defer index.close()
	item, err := index.getByID(flags.Arg(0))
	if err != nil {
		return err
	}
	var data []byte
	if *raw {
		data, err = os.ReadFile(item.Path)
		if err != nil {
			return fmt.Errorf("read memo %s: %w", item.Path, err)
		}
	} else {
		parsed, err := parseMemoFile(item.Path)
		if err != nil {
			return err
		}
		data = []byte(parsed.Body)
	}
	written, err := stdout.Write(data)
	if err != nil {
		return fmt.Errorf("write memo %s: %w", item.Path, err)
	}
	if written != len(data) {
		return fmt.Errorf("write memo %s: %w", item.Path, io.ErrShortWrite)
	}
	return nil
}

func runList(args []string, stdout io.Writer) error {
	flags := flag.NewFlagSet("list", flag.ContinueOnError)
	flags.SetOutput(io.Discard)
	status := flags.String("status", "", "filter by wip or done")
	if err := flags.Parse(args); err != nil {
		return err
	}
	if flags.NArg() != 0 {
		return fmt.Errorf("list does not accept positional arguments")
	}
	if err := validateOptionalStatus(*status); err != nil {
		return err
	}
	index, _, err := indexContext()
	if err != nil {
		return err
	}
	defer index.close()
	items, err := index.list(*status)
	if err != nil {
		return err
	}
	writer := tabwriter.NewWriter(stdout, 0, 4, 2, ' ', 0)
	if _, err := fmt.Fprintln(writer, "CREATED\tSTATUS\tREPOSITORY\tID\tNAME\tSUMMARY\tPATH"); err != nil {
		return fmt.Errorf("write memo table: %w", err)
	}
	for _, item := range items {
		repository := item.Repository
		if repository == "" {
			repository = "-"
		}
		if _, err := fmt.Fprintf(writer, "%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
			item.CreatedAt, item.Status, repository, item.ID, item.Name, item.Summary, item.Path); err != nil {
			return fmt.Errorf("write memo table: %w", err)
		}
	}
	if err := writer.Flush(); err != nil {
		return fmt.Errorf("write memo table: %w", err)
	}
	return nil
}

func runDone(args []string, stdout io.Writer) error {
	if len(args) != 1 || args[0] == "" {
		return fmt.Errorf("usage: memo done <id>")
	}
	index, _, err := indexContext()
	if err != nil {
		return err
	}
	defer index.close()
	item, err := index.getByID(args[0])
	if err != nil {
		return err
	}
	if _, err := index.inner.Update(item.Path, func(document markdownstore.Document) (markdownstore.Document, error) {
		document.Metadata["status"] = "done"
		document.Metadata["updated_at"] = formatTimestamp(time.Now())
		return document, nil
	}); err != nil {
		return err
	}
	item, err = index.getByID(args[0])
	if err != nil {
		return err
	}
	return writeJSON(stdout, item)
}

func runRemove(args []string, stdin io.Reader, stdout io.Writer) error {
	flags := flag.NewFlagSet("remove", flag.ContinueOnError)
	flags.SetOutput(io.Discard)
	force := flags.Bool("force", false, "skip confirmation")
	if err := flags.Parse(args); err != nil {
		return err
	}
	if flags.NArg() != 1 || flags.Arg(0) == "" {
		return fmt.Errorf("usage: memo remove [--force] <id>")
	}

	index, _, err := indexContext()
	if err != nil {
		return err
	}
	defer index.close()
	item, err := index.getByID(flags.Arg(0))
	if err != nil {
		return err
	}
	snapshot, err := parseMemoFile(item.Path)
	if err != nil {
		return err
	}
	if snapshot.ID != item.ID {
		return fmt.Errorf("memo changed before removal: %s", item.Path)
	}
	if !*force {
		if _, err := fmt.Fprintf(stdout, "Remove memo %s (%s) at %s? [y/N] ",
			snapshot.ID, snapshot.Summary, snapshot.Path); err != nil {
			return fmt.Errorf("write removal confirmation: %w", err)
		}
		answer, readErr := bufio.NewReader(stdin).ReadString('\n')
		if readErr != nil && !errors.Is(readErr, io.EOF) {
			return fmt.Errorf("read removal confirmation: %w", readErr)
		}
		if !strings.EqualFold(strings.TrimSpace(answer), "y") {
			_, err := fmt.Fprintln(stdout, "Removal cancelled.")
			return err
		}
	}

	current, err := parseMemoFile(snapshot.Path)
	if err != nil {
		return err
	}
	if !equalMemo(current.memo, snapshot.memo) {
		return fmt.Errorf("memo changed before removal: %s", snapshot.Path)
	}
	if err := index.inner.Remove(snapshot.Path, markdownstore.Fingerprint{
		Size: snapshot.Size, ModTimeNS: snapshot.ModTime,
	}); err != nil {
		if errors.Is(err, markdownstore.ErrChanged) {
			return fmt.Errorf("memo changed before removal: %s", snapshot.Path)
		}
		return err
	}
	if _, err := fmt.Fprintf(stdout, "Removed %s\n", snapshot.Path); err != nil {
		return fmt.Errorf("write removal result: %w", err)
	}
	return nil
}

func validateName(name string) error {
	if name == "" {
		return fmt.Errorf("memo name must not be empty")
	}
	parts := strings.Split(name, "-")
	for _, part := range parts {
		if part == "" {
			return fmt.Errorf("memo name must be kebab-case")
		}
		for _, character := range part {
			if (character < 'a' || character > 'z') && (character < '0' || character > '9') {
				return fmt.Errorf("memo name must be kebab-case")
			}
		}
	}
	return nil
}

func validateMemoID(id string) error {
	if id == "" {
		return fmt.Errorf("memo ID must not be empty")
	}
	for _, character := range id {
		if (character < 'a' || character > 'z') &&
			(character < 'A' || character > 'Z') &&
			(character < '0' || character > '9') &&
			character != '-' && character != '_' {
			return fmt.Errorf("memo ID may contain only letters, numbers, hyphens, and underscores")
		}
	}
	return nil
}

func validateOptionalStatus(status string) error {
	if status != "" && status != "wip" && status != "done" {
		return fmt.Errorf("status must be wip or done")
	}
	return nil
}

func newMemoID() (string, error) {
	random := make([]byte, 4)
	if _, err := rand.Read(random); err != nil {
		return "", fmt.Errorf("generate memo ID: %w", err)
	}
	return hex.EncodeToString(random), nil
}

func formatTimestamp(value time.Time) string {
	return value.UTC().Truncate(time.Second).Format(time.RFC3339)
}

func writeMarkdown(writer io.Writer, item memo) error {
	lines := []string{
		"---",
		"memo_id: " + strconv.Quote(item.ID),
		"repository: " + strconv.Quote(item.Repository),
		"name: " + strconv.Quote(item.Name),
		"summary: " + strconv.Quote(item.Summary),
		"status: " + strconv.Quote(item.Status),
		"created_at: " + strconv.Quote(item.CreatedAt),
		"updated_at: " + strconv.Quote(item.UpdatedAt),
		"---",
		"",
		item.Body,
	}
	if _, err := fmt.Fprint(writer, strings.Join(lines, "\n")); err != nil {
		return fmt.Errorf("write Markdown memo: %w", err)
	}
	return nil
}

func writeJSON(writer io.Writer, value any) error {
	encoder := json.NewEncoder(writer)
	encoder.SetEscapeHTML(false)
	encoder.SetIndent("", "  ")
	if err := encoder.Encode(value); err != nil {
		return fmt.Errorf("write JSON output: %w", err)
	}
	return nil
}
