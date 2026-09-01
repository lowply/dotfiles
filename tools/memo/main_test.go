package main

import (
	"bytes"
	"database/sql"
	"encoding/json"
	"errors"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"testing"
)

type readerWithHook struct {
	reader io.Reader
	hook   func()
}

type errorReader struct{}

func (errorReader) Read([]byte) (int, error) {
	return 0, errors.New("read failed")
}

func runGitAt(t *testing.T, directory string, args ...string) {
	t.Helper()
	command := exec.Command("git", append([]string{"-C", directory}, args...)...)
	if output, err := command.CombinedOutput(); err != nil {
		t.Fatalf("git %v: %v\n%s", args, err, output)
	}
}

func withWorkingDirectory(t *testing.T, directory string) {
	t.Helper()
	previous, err := os.Getwd()
	if err != nil {
		t.Fatal(err)
	}
	if err := os.Chdir(directory); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		if err := os.Chdir(previous); err != nil {
			t.Error(err)
		}
	})
}

func (r *readerWithHook) Read(buffer []byte) (int, error) {
	if r.hook != nil {
		r.hook()
		r.hook = nil
	}
	return r.reader.Read(buffer)
}

func TestSteadyStateCommandSurface(t *testing.T) {
	for _, command := range []string{"create", "search", "get", "show", "list", "done", "remove", "rm"} {
		var output bytes.Buffer
		if err := run([]string{command, "--help"}, strings.NewReader(""), &output); err != nil {
			t.Fatalf("%s help: %v", command, err)
		}
	}
	for _, removed := range []string{"update", "import", "export", "import-markdown", "migrate-sqlite"} {
		err := run([]string{removed, "--help"}, strings.NewReader(""), io.Discard)
		if err == nil || !strings.Contains(err.Error(), "unknown command") {
			t.Fatalf("%s unexpectedly remains available: %v", removed, err)
		}
	}
}

func TestGetWritesOnlyCanonicalPathAsJSON(t *testing.T) {
	home := t.TempDir()
	t.Setenv("HOME", home)
	path := filepath.Join(home, ".copilot", "memo", "memo.md")
	writeMemoAt(t, path, testMemo("abc12345", "get-memo", "Get memo", "Body must not be returned."))

	var output bytes.Buffer
	if err := run([]string{"get", "abc12345"}, strings.NewReader(""), &output); err != nil {
		t.Fatal(err)
	}
	var result map[string]any
	if err := json.Unmarshal(output.Bytes(), &result); err != nil {
		t.Fatal(err)
	}
	if len(result) != 1 || result["path"] != path {
		t.Fatalf("unexpected get result: %#v", result)
	}
}

func TestGetRejectsUnknownID(t *testing.T) {
	t.Setenv("HOME", t.TempDir())
	err := run([]string{"get", "missing"}, strings.NewReader(""), io.Discard)
	if err == nil || !strings.Contains(err.Error(), `no memo found with ID "missing"`) {
		t.Fatalf("error = %v, want missing memo error", err)
	}
}

func TestGetRequiresOneID(t *testing.T) {
	for _, args := range [][]string{{"get"}, {"get", "first", "second"}} {
		err := run(args, strings.NewReader(""), io.Discard)
		if err == nil || err.Error() != "usage: memo get <id>" {
			t.Fatalf("run(%q) error = %v, want get usage", args, err)
		}
	}
}

func TestShowWritesMemoBodyOnly(t *testing.T) {
	home := t.TempDir()
	t.Setenv("HOME", home)
	path := filepath.Join(home, ".copilot", "memo", "memo.md")
	body := "# Heading\n\nBody without a trailing newline."
	writeMemoAt(t, path, testMemo("abc12345", "show-memo", "Show memo", body))

	var output bytes.Buffer
	if err := run([]string{"show", "abc12345"}, strings.NewReader(""), &output); err != nil {
		t.Fatal(err)
	}
	if output.String() != body {
		t.Fatalf("show output = %q, want body %q", output.String(), body)
	}
}

func TestShowRawWritesCanonicalMemoVerbatim(t *testing.T) {
	home := t.TempDir()
	t.Setenv("HOME", home)
	path := filepath.Join(home, ".copilot", "memo", "memo.md")
	writeMemoAt(t, path, testMemo("abc12345", "show-memo", "Show memo", "Raw body."))
	expected, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}

	var output bytes.Buffer
	if err := run([]string{"show", "--raw", "abc12345"}, strings.NewReader(""), &output); err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(output.Bytes(), expected) {
		t.Fatalf("raw show output = %q, want canonical file %q", output.Bytes(), expected)
	}
}

func TestShowRejectsUnknownID(t *testing.T) {
	t.Setenv("HOME", t.TempDir())
	err := run([]string{"show", "missing"}, strings.NewReader(""), io.Discard)
	if err == nil || !strings.Contains(err.Error(), `no memo found with ID "missing"`) {
		t.Fatalf("error = %v, want missing memo error", err)
	}
}

func TestShowRequiresOneID(t *testing.T) {
	for _, args := range [][]string{{"show"}, {"show", "--raw"}, {"show", "first", "second"}} {
		err := run(args, strings.NewReader(""), io.Discard)
		if err == nil || err.Error() != "usage: memo show [--raw] <id>" {
			t.Fatalf("run(%q) error = %v, want show usage", args, err)
		}
	}
}

func TestCreateWritesEmptyCanonicalMemoAndIndexesPath(t *testing.T) {
	home := t.TempDir()
	t.Setenv("HOME", home)
	repositoryRoot := t.TempDir()
	runGit := func(args ...string) {
		t.Helper()
		command := exec.Command("git", append([]string{"-C", repositoryRoot}, args...)...)
		if output, err := command.CombinedOutput(); err != nil {
			t.Fatalf("git %v: %v\n%s", args, err, output)
		}
	}
	runGit("init", "--quiet")
	runGit("remote", "add", "origin", "git@github.com:lowply/dotfiles.git")
	previous, err := os.Getwd()
	if err != nil {
		t.Fatal(err)
	}
	if err := os.Chdir(repositoryRoot); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { os.Chdir(previous) })

	var output bytes.Buffer
	if err := run([]string{"create", "This is a title"}, strings.NewReader(""), &output); err != nil {
		t.Fatal(err)
	}
	var created searchResult
	if err := json.Unmarshal(output.Bytes(), &created); err != nil {
		t.Fatal(err)
	}
	if created.Name != "this-is-a-title" ||
		created.Summary != "This is a title" ||
		created.Repository != "lowply/dotfiles" ||
		created.Status != "wip" {
		t.Fatalf("unexpected created memo: %#v", created)
	}
	expectedDirectory := filepath.Join(home, ".copilot", "memo")
	expectedSuffix := "-" + created.ID + "-lowply-dotfiles-this-is-a-title.md"
	if filepath.Dir(created.Path) != expectedDirectory ||
		!strings.HasSuffix(created.Path, expectedSuffix) {
		t.Fatalf("unexpected canonical path: %q", created.Path)
	}
	item, err := parseMemoFile(created.Path)
	if err != nil {
		t.Fatal(err)
	}
	if item.Body != "" || item.Name != created.Name || item.Summary != created.Summary {
		t.Fatalf("unexpected canonical memo: %#v", item)
	}

	index, err := openIndex(filepath.Join(expectedDirectory, "memo.db"))
	if err != nil {
		t.Fatal(err)
	}
	defer index.close()
	indexed, err := index.getByID(created.ID)
	if err != nil {
		t.Fatal(err)
	}
	if indexed.Path != created.Path {
		t.Fatalf("indexed path = %q, want %q", indexed.Path, created.Path)
	}
}

func TestCreateOutsideGitCreatesUnscopedMemo(t *testing.T) {
	home := t.TempDir()
	t.Setenv("HOME", home)
	workingDirectory := t.TempDir()
	withWorkingDirectory(t, workingDirectory)

	var output bytes.Buffer
	if err := run([]string{"create", "General research"}, strings.NewReader(""), &output); err != nil {
		t.Fatal(err)
	}
	var created searchResult
	if err := json.Unmarshal(output.Bytes(), &created); err != nil {
		t.Fatal(err)
	}
	if created.Repository != "" {
		t.Fatalf("repository = %q, want empty", created.Repository)
	}
	expectedSuffix := "-" + created.ID + "-general-research.md"
	if !strings.HasSuffix(created.Path, expectedSuffix) {
		t.Fatalf("canonical path = %q, want suffix %q", created.Path, expectedSuffix)
	}
	item, err := parseMemoFile(created.Path)
	if err != nil {
		t.Fatal(err)
	}
	if item.Repository != "" {
		t.Fatalf("canonical repository = %q, want empty", item.Repository)
	}
}

func TestCreateUsesPipedStdinAsMemoBody(t *testing.T) {
	home := t.TempDir()
	t.Setenv("HOME", home)
	withWorkingDirectory(t, t.TempDir())
	body := "# Findings\n\nPreserve this body exactly.\n"

	var output bytes.Buffer
	if err := run([]string{"create", "--no-repository", "Piped research"}, strings.NewReader(body), &output); err != nil {
		t.Fatal(err)
	}
	var created searchResult
	if err := json.Unmarshal(output.Bytes(), &created); err != nil {
		t.Fatal(err)
	}
	item, err := parseMemoFile(created.Path)
	if err != nil {
		t.Fatal(err)
	}
	if item.Body != body {
		t.Fatalf("body = %q, want %q", item.Body, body)
	}
}

func TestCreateReturnsStdinReadError(t *testing.T) {
	t.Setenv("HOME", t.TempDir())
	withWorkingDirectory(t, t.TempDir())

	err := run([]string{"create", "--no-repository", "Unreadable body"}, errorReader{}, io.Discard)
	if err == nil || !strings.Contains(err.Error(), "read memo body from stdin") {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestCreateInGitRepositoryWithoutRemoteCreatesUnscopedMemo(t *testing.T) {
	home := t.TempDir()
	t.Setenv("HOME", home)
	repositoryRoot := t.TempDir()
	runGitAt(t, repositoryRoot, "init", "--quiet")
	withWorkingDirectory(t, repositoryRoot)

	var output bytes.Buffer
	if err := run([]string{"create", "Local research"}, strings.NewReader(""), &output); err != nil {
		t.Fatal(err)
	}
	var created searchResult
	if err := json.Unmarshal(output.Bytes(), &created); err != nil {
		t.Fatal(err)
	}
	if created.Repository != "" {
		t.Fatalf("repository = %q, want empty", created.Repository)
	}
}

func TestCreateAcceptsExplicitRepositoryOutsideGit(t *testing.T) {
	home := t.TempDir()
	t.Setenv("HOME", home)
	withWorkingDirectory(t, t.TempDir())

	var output bytes.Buffer
	if err := run([]string{"create", "--repository", "lowply/research", "Explicit repository"}, strings.NewReader(""), &output); err != nil {
		t.Fatal(err)
	}
	var created searchResult
	if err := json.Unmarshal(output.Bytes(), &created); err != nil {
		t.Fatal(err)
	}
	if created.Repository != "lowply/research" {
		t.Fatalf("repository = %q, want lowply/research", created.Repository)
	}
	if !strings.Contains(filepath.Base(created.Path), "-lowply-research-explicit-repository.md") {
		t.Fatalf("unexpected canonical path: %q", created.Path)
	}
}

func TestCreateCanForceUnscopedMemoInsideRepository(t *testing.T) {
	home := t.TempDir()
	t.Setenv("HOME", home)
	repositoryRoot := t.TempDir()
	runGitAt(t, repositoryRoot, "init", "--quiet")
	runGitAt(t, repositoryRoot, "remote", "add", "origin", "git@github.com:lowply/dotfiles.git")
	withWorkingDirectory(t, repositoryRoot)

	var output bytes.Buffer
	if err := run([]string{"create", "--no-repository", "Unscoped research"}, strings.NewReader(""), &output); err != nil {
		t.Fatal(err)
	}
	var created searchResult
	if err := json.Unmarshal(output.Bytes(), &created); err != nil {
		t.Fatal(err)
	}
	if created.Repository != "" {
		t.Fatalf("repository = %q, want empty", created.Repository)
	}
}

func TestCreateRejectsConflictingRepositoryOptions(t *testing.T) {
	err := run([]string{
		"create", "--repository", "lowply/dotfiles", "--no-repository", "Conflicting options",
	}, strings.NewReader(""), io.Discard)
	if err == nil || !strings.Contains(err.Error(), "--repository and --no-repository cannot be used together") {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestCreateRejectsInvalidExplicitRepository(t *testing.T) {
	err := run([]string{
		"create", "--repository", "not-an-nwo", "Invalid repository",
	}, strings.NewReader(""), io.Discard)
	if err == nil || !strings.Contains(err.Error(), "repository must use owner/name format") {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestCreateRejectsMalformedConfiguredRemote(t *testing.T) {
	t.Setenv("HOME", t.TempDir())
	repositoryRoot := t.TempDir()
	runGitAt(t, repositoryRoot, "init", "--quiet")
	runGitAt(t, repositoryRoot, "remote", "add", "origin", "not-a-repository")
	withWorkingDirectory(t, repositoryRoot)

	err := run([]string{"create", "Malformed remote"}, strings.NewReader(""), io.Discard)
	if err == nil || !strings.Contains(err.Error(), "could not parse repository owner/name") {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestCreateRetriesDuplicateMemoID(t *testing.T) {
	home := t.TempDir()
	t.Setenv("HOME", home)
	repositoryRoot := t.TempDir()
	runGit := func(args ...string) {
		t.Helper()
		command := exec.Command("git", append([]string{"-C", repositoryRoot}, args...)...)
		if output, err := command.CombinedOutput(); err != nil {
			t.Fatalf("git %v: %v\n%s", args, err, output)
		}
	}
	runGit("init", "--quiet")
	runGit("remote", "add", "origin", "git@github.com:lowply/dotfiles.git")
	previous, err := os.Getwd()
	if err != nil {
		t.Fatal(err)
	}
	if err := os.Chdir(repositoryRoot); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { os.Chdir(previous) })

	directory := filepath.Join(home, ".copilot", "memo")
	existing := testMemo("duplicate-id", "existing", "Existing summary", "")
	writeMemoAt(t, filepath.Join(directory, "existing.md"), existing)
	ids := []string{"duplicate-id", "unique-id"}
	originalGenerator := generateMemoID
	generateMemoID = func() (string, error) {
		id := ids[0]
		ids = ids[1:]
		return id, nil
	}
	t.Cleanup(func() { generateMemoID = originalGenerator })

	var output bytes.Buffer
	if err := run([]string{"create", "Unique title"}, strings.NewReader(""), &output); err != nil {
		t.Fatal(err)
	}
	var created searchResult
	if err := json.Unmarshal(output.Bytes(), &created); err != nil {
		t.Fatal(err)
	}
	if created.ID != "unique-id" {
		t.Fatalf("created ID = %q, want unique-id", created.ID)
	}
	matches, err := filepath.Glob(filepath.Join(directory, "*duplicate-id-unique-title.md"))
	if err != nil {
		t.Fatal(err)
	}
	if len(matches) != 0 {
		t.Fatalf("duplicate-ID file was created: %v", matches)
	}
}

func TestListDisplaysDashForUnscopedMemo(t *testing.T) {
	home := t.TempDir()
	t.Setenv("HOME", home)
	path := filepath.Join(home, ".copilot", "memo", "memo.md")
	item := testMemo("abc12345", "general", "General memo", "")
	item.Repository = ""
	writeMemoAt(t, path, item)

	var output bytes.Buffer
	if err := run([]string{"list"}, strings.NewReader(""), &output); err != nil {
		t.Fatal(err)
	}
	lines := strings.Split(strings.TrimSpace(output.String()), "\n")
	if len(lines) != 2 {
		t.Fatalf("unexpected list output: %q", output.String())
	}
	fields := strings.Fields(lines[1])
	if len(fields) < 3 || fields[2] != "-" {
		t.Fatalf("list output does not mark unscoped repository: %q", output.String())
	}
}

func TestUnscopedMemoSupportsSearchDoneAndRemove(t *testing.T) {
	home := t.TempDir()
	t.Setenv("HOME", home)
	path := filepath.Join(home, ".copilot", "memo", "memo.md")
	item := testMemo("abc12345", "general-lifecycle", "General lifecycle", "Unscoped body")
	item.Repository = ""
	writeMemoAt(t, path, item)

	var output bytes.Buffer
	if err := run([]string{"search", "--", "Unscoped"}, strings.NewReader(""), &output); err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(output.String(), strconv.Quote(path)) {
		t.Fatalf("search result missing unscoped memo: %q", output.String())
	}

	output.Reset()
	if err := run([]string{"done", "abc12345"}, strings.NewReader(""), &output); err != nil {
		t.Fatal(err)
	}
	done, err := parseMemoFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if done.Status != "done" || done.Repository != "" {
		t.Fatalf("unexpected completed memo: %#v", done)
	}

	if err := run([]string{"remove", "--force", "abc12345"}, strings.NewReader(""), io.Discard); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(path); !os.IsNotExist(err) {
		t.Fatalf("unscoped memo remains after removal: %v", err)
	}
}

func TestNewMemoIDUsesEightHexCharacters(t *testing.T) {
	id, err := newMemoID()
	if err != nil {
		t.Fatal(err)
	}
	if matched, err := regexp.MatchString(`^[0-9a-f]{8}$`, id); err != nil {
		t.Fatal(err)
	} else if !matched {
		t.Fatalf("newMemoID() = %q, want eight lowercase hexadecimal characters", id)
	}
}

func TestCreateIgnoresLegacyCreateLock(t *testing.T) {
	home := t.TempDir()
	t.Setenv("HOME", home)
	directory := filepath.Join(home, ".copilot", "memo")
	if err := os.MkdirAll(directory, 0o700); err != nil {
		t.Fatal(err)
	}
	lockPath := filepath.Join(directory, ".create.lock")
	if err := os.WriteFile(lockPath, nil, 0o600); err != nil {
		t.Fatal(err)
	}

	repositoryRoot := t.TempDir()
	runGit := func(args ...string) {
		t.Helper()
		command := exec.Command("git", append([]string{"-C", repositoryRoot}, args...)...)
		if output, err := command.CombinedOutput(); err != nil {
			t.Fatalf("git %v: %v\n%s", args, err, output)
		}
	}
	runGit("init", "--quiet")
	runGit("remote", "add", "origin", "git@github.com:lowply/dotfiles.git")
	previous, err := os.Getwd()
	if err != nil {
		t.Fatal(err)
	}
	if err := os.Chdir(repositoryRoot); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { os.Chdir(previous) })

	if err := runCreate([]string{"Concurrent title"}, strings.NewReader(""), io.Discard); err != nil {
		t.Fatal(err)
	}
	matches, err := filepath.Glob(filepath.Join(directory, "*.md"))
	if err != nil {
		t.Fatal(err)
	}
	if len(matches) != 1 {
		t.Fatalf("created files = %v, want one memo", matches)
	}
}

func TestDoneIgnoresLegacyMemoLock(t *testing.T) {
	home := t.TempDir()
	t.Setenv("HOME", home)
	path := filepath.Join(home, ".copilot", "memo", "memo.md")
	writeMemoAt(t, path, testMemo("abc12345", "locked", "Locked memo", "Body"))
	if err := os.WriteFile(path+".lock", nil, 0o600); err != nil {
		t.Fatal(err)
	}

	if err := run([]string{"done", "abc12345"}, strings.NewReader(""), io.Discard); err != nil {
		t.Fatal(err)
	}
	item, err := parseMemoFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if item.Status != "done" {
		t.Fatalf("status = %q, want done", item.Status)
	}
}

func TestDoneUpdatesCanonicalFileAndSearchIndex(t *testing.T) {
	home := t.TempDir()
	t.Setenv("HOME", home)
	directory := filepath.Join(home, ".copilot", "memo")
	path := filepath.Join(directory, "2026-08-22-abc12345-lowply-dotfiles-status.md")
	writeMemoAt(t, path, testMemo("abc12345", "status", "Status summary", "Body"))

	var output bytes.Buffer
	if err := run([]string{"done", "abc12345"}, strings.NewReader(""), &output); err != nil {
		t.Fatal(err)
	}

	got, err := parseMemoFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if got.Status != "done" {
		t.Fatalf("status = %q", got.Status)
	}
	if !strings.Contains(output.String(), `"path": `+strconv.Quote(path)) {
		t.Fatalf("missing canonical path: %s", output.String())
	}

	output.Reset()
	if err := run([]string{"search", "--status", "done", "--", "Status"}, strings.NewReader(""), &output); err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(output.String(), strconv.Quote(path)) {
		t.Fatalf("updated index missing path: %s", output.String())
	}
}

func TestDoneRefusesConcurrentEdit(t *testing.T) {
	home := t.TempDir()
	t.Setenv("HOME", home)
	path := filepath.Join(home, ".copilot", "memo", "memo.md")
	writeMemoAt(t, path, testMemo("abc12345", "original", "Original summary", "Original body"))
	if err := run([]string{"list"}, strings.NewReader(""), io.Discard); err != nil {
		t.Fatal(err)
	}
	replacement := testMemo("abc12345", "replacement", "Replacement summary", "Replacement body")
	beforeMemoWrite = func() {
		beforeMemoWrite = nil
		writeMemoAt(t, path, replacement)
	}
	t.Cleanup(func() { beforeMemoWrite = nil })

	err := run([]string{"done", "abc12345"}, strings.NewReader(""), io.Discard)
	if err == nil || !strings.Contains(err.Error(), "changed while updating memo") {
		t.Fatalf("done error = %v, want changed memo error", err)
	}
	got, parseErr := parseMemoFile(path)
	if parseErr != nil {
		t.Fatal(parseErr)
	}
	if got.Name != replacement.Name || got.Body != replacement.Body || got.Status != "wip" {
		t.Fatalf("concurrent edit was overwritten: %#v", got)
	}
}

func TestRemoveRequiresConfirmation(t *testing.T) {
	home := t.TempDir()
	t.Setenv("HOME", home)
	path := filepath.Join(home, ".copilot", "memo", "memo.md")
	writeMemoAt(t, path, testMemo("abc12345", "kept", "Keep this memo", "Body"))

	var output bytes.Buffer
	if err := run([]string{"remove", "abc12345"}, strings.NewReader("\n"), &output); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(path); err != nil {
		t.Fatalf("memo removed without confirmation: %v", err)
	}
	if !strings.Contains(output.String(), "Remove memo abc12345") ||
		!strings.Contains(output.String(), "Removal cancelled") {
		t.Fatalf("unexpected confirmation output: %q", output.String())
	}
}

func TestRemoveDeletesCanonicalFileAndIndexRecord(t *testing.T) {
	home := t.TempDir()
	t.Setenv("HOME", home)
	directory := filepath.Join(home, ".copilot", "memo")
	path := filepath.Join(directory, "memo.md")
	writeMemoAt(t, path, testMemo("abc12345", "removed", "Remove this memo", "Body"))

	var output bytes.Buffer
	if err := run([]string{"remove", "abc12345"}, strings.NewReader("y\n"), &output); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(path); !os.IsNotExist(err) {
		t.Fatalf("memo file still exists: %v", err)
	}
	index, err := openIndex(filepath.Join(directory, "memo.db"))
	if err != nil {
		t.Fatal(err)
	}
	defer index.close()
	if _, err := index.getByID("abc12345"); err == nil {
		t.Fatal("removed memo remains indexed")
	}
}

func TestRemoveForceAliasSkipsConfirmation(t *testing.T) {
	home := t.TempDir()
	t.Setenv("HOME", home)
	path := filepath.Join(home, ".copilot", "memo", "memo.md")
	writeMemoAt(t, path, testMemo("abc12345", "forced", "Force remove", "Body"))

	if err := run([]string{"rm", "--force", "abc12345"}, strings.NewReader(""), io.Discard); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(path); !os.IsNotExist(err) {
		t.Fatalf("memo file still exists: %v", err)
	}
}

func TestRemoveIgnoresLegacyMemoLock(t *testing.T) {
	home := t.TempDir()
	t.Setenv("HOME", home)
	path := filepath.Join(home, ".copilot", "memo", "memo.md")
	writeMemoAt(t, path, testMemo("abc12345", "locked", "Locked memo", "Body"))
	if err := os.WriteFile(path+".lock", nil, 0o600); err != nil {
		t.Fatal(err)
	}

	if err := run([]string{"remove", "--force", "abc12345"}, strings.NewReader(""), io.Discard); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(path); !os.IsNotExist(err) {
		t.Fatalf("memo file still exists: %v", err)
	}
}

func TestRemoveRefusesMemoChangedDuringConfirmation(t *testing.T) {
	home := t.TempDir()
	t.Setenv("HOME", home)
	path := filepath.Join(home, ".copilot", "memo", "memo.md")
	writeMemoAt(t, path, testMemo("abc12345", "original", "Original summary", "Original body"))
	replacement := testMemo("abc12345", "changed", "Changed summary", "Changed body")
	input := &readerWithHook{
		reader: strings.NewReader("y\n"),
		hook: func() {
			writeMemoAt(t, path, replacement)
		},
	}

	err := run([]string{"remove", "abc12345"}, input, io.Discard)
	if err == nil || !strings.Contains(err.Error(), "changed before removal") {
		t.Fatalf("remove error = %v, want changed memo error", err)
	}
	got, parseErr := parseMemoFile(path)
	if parseErr != nil {
		t.Fatal(parseErr)
	}
	if got.Name != replacement.Name || got.Body != replacement.Body {
		t.Fatalf("changed memo was not preserved: %#v", got)
	}
}

func TestRemoveRefusesMemoChangedWithoutFingerprintChange(t *testing.T) {
	home := t.TempDir()
	t.Setenv("HOME", home)
	path := filepath.Join(home, ".copilot", "memo", "memo.md")
	writeMemoAt(t, path, testMemo("abc12345", "original", "Original summary", "Original body"))
	originalInfo, err := os.Stat(path)
	if err != nil {
		t.Fatal(err)
	}
	replacement := testMemo("abc12345", "replaced", "Replaced summary", "Changed body!")
	input := &readerWithHook{
		reader: strings.NewReader("y\n"),
		hook: func() {
			writeMemoAt(t, path, replacement)
			replacementInfo, statErr := os.Stat(path)
			if statErr != nil {
				t.Fatal(statErr)
			}
			if replacementInfo.Size() != originalInfo.Size() {
				t.Fatalf("replacement size = %d, want %d", replacementInfo.Size(), originalInfo.Size())
			}
			if chtimesErr := os.Chtimes(path, originalInfo.ModTime(), originalInfo.ModTime()); chtimesErr != nil {
				t.Fatal(chtimesErr)
			}
		},
	}

	err = run([]string{"remove", "abc12345"}, input, io.Discard)
	if err == nil || !strings.Contains(err.Error(), "changed before removal") {
		t.Fatalf("remove error = %v, want changed memo error", err)
	}
	got, parseErr := parseMemoFile(path)
	if parseErr != nil {
		t.Fatal(parseErr)
	}
	if got.Name != replacement.Name || got.Body != replacement.Body {
		t.Fatalf("changed memo was not preserved: %#v", got)
	}
}

func TestSearchReconcilesDirectEditsAndRebuildsDeletedIndex(t *testing.T) {
	home := t.TempDir()
	t.Setenv("HOME", home)
	directory := filepath.Join(home, ".copilot", "memo")
	path := filepath.Join(directory, "2026-08-22-abc12345-lowply-dotfiles-direct.md")
	item := testMemo("abc12345", "direct", "Initial summary", "Initial body")
	writeMemoAt(t, path, item)

	var output bytes.Buffer
	if err := run([]string{"search", "--", "Initial"}, strings.NewReader(""), &output); err != nil {
		t.Fatal(err)
	}
	item.Summary = "Changed summary"
	item.Body = "Changed body"
	item.UpdatedAt = "2026-08-22T02:00:00Z"
	writeMemoAt(t, path, item)
	output.Reset()
	if err := run([]string{"search", "--", "Changed"}, strings.NewReader(""), &output); err != nil {
		t.Fatal(err)
	}

	databasePath := filepath.Join(directory, "memo.db")
	if err := os.Remove(databasePath); err != nil {
		t.Fatal(err)
	}
	for _, suffix := range []string{"-wal", "-shm"} {
		if err := os.Remove(databasePath + suffix); err != nil && !os.IsNotExist(err) {
			t.Fatal(err)
		}
	}
	output.Reset()
	if err := run([]string{"search", "--", "Changed"}, strings.NewReader(""), &output); err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(output.String(), strconv.Quote(path)) {
		t.Fatalf("rebuilt search missing path: %s", output.String())
	}
}

func TestListIncludesCanonicalPath(t *testing.T) {
	home := t.TempDir()
	t.Setenv("HOME", home)
	path := filepath.Join(home, ".copilot", "memo", "memo.md")
	writeMemoAt(t, path, testMemo("abc12345", "listed", "Listed summary", "Body"))

	var output bytes.Buffer
	if err := run([]string{"list"}, strings.NewReader(""), &output); err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(output.String(), "PATH") || !strings.Contains(output.String(), path) {
		t.Fatalf("list omitted canonical path:\n%s", output.String())
	}
}

func TestCreateSupportsSeparateMemoDirectoryAndDatabasePath(t *testing.T) {
	root := t.TempDir()
	directory := filepath.Join(root, "canonical")
	databasePath := filepath.Join(root, "index", "memo.db")
	t.Setenv("MEMO_DIR", directory)
	t.Setenv("MEMO_DB_PATH", databasePath)
	withWorkingDirectory(t, t.TempDir())

	var output bytes.Buffer
	if err := run([]string{"create", "--no-repository", "Configured paths"}, strings.NewReader(""), &output); err != nil {
		t.Fatal(err)
	}
	var created searchResult
	if err := json.Unmarshal(output.Bytes(), &created); err != nil {
		t.Fatal(err)
	}
	if filepath.Dir(created.Path) != directory {
		t.Fatalf("canonical path = %q, want directory %q", created.Path, directory)
	}
	if _, err := os.Stat(databasePath); err != nil {
		t.Fatalf("database path was not used: %v", err)
	}
}

func TestCreateRebuildsIncompatibleDatabase(t *testing.T) {
	root := t.TempDir()
	directory := filepath.Join(root, "canonical")
	databasePath := filepath.Join(root, "index", "memo.db")
	if err := os.MkdirAll(directory, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.MkdirAll(filepath.Dir(databasePath), 0o755); err != nil {
		t.Fatal(err)
	}
	database, err := sql.Open("sqlite", databasePath)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := database.Exec(`CREATE TABLE schema_migrations(version INTEGER PRIMARY KEY, applied_at TEXT NOT NULL);
		INSERT INTO schema_migrations(version, applied_at) VALUES(999, '2026-08-31T00:00:00Z')`); err != nil {
		t.Fatal(err)
	}
	if err := database.Close(); err != nil {
		t.Fatal(err)
	}
	t.Setenv("MEMO_DIR", directory)
	t.Setenv("MEMO_DB_PATH", databasePath)
	withWorkingDirectory(t, t.TempDir())

	var output bytes.Buffer
	err = run([]string{"create", "--no-repository", "Rebuilt"}, strings.NewReader(""), &output)
	if err != nil {
		t.Fatal(err)
	}
	info, err := os.Stat(directory)
	if err != nil {
		t.Fatal(err)
	}
	if info.Mode().Perm() != 0o700 {
		t.Fatalf("directory mode = %o, want 0700", info.Mode().Perm())
	}
}
