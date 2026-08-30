package main

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"time"

	"gopkg.in/yaml.v3"
)

var (
	errMemoChangedDuringRead = errors.New("memo changed while being read")
	afterMemoRead            func()
	beforeMemoStatusReplace  func()
)

type memoFile struct {
	memo
	Path    string
	Size    int64
	ModTime int64
}

type memoFrontmatter struct {
	ID         string `yaml:"memo_id"`
	Repository string `yaml:"repository"`
	Name       string `yaml:"name"`
	Summary    string `yaml:"summary"`
	Status     string `yaml:"status"`
	CreatedAt  string `yaml:"created_at"`
	UpdatedAt  string `yaml:"updated_at"`
}

func defaultMemoDirectory() (string, error) {
	home, err := os.UserHomeDir()
	if err != nil {
		return "", fmt.Errorf("resolve home directory: %w", err)
	}
	return filepath.Join(home, ".copilot", "memo"), nil
}

func parseMemoFile(filePath string) (memoFile, error) {
	var lastErr error
	for range 3 {
		item, err := parseMemoFileOnce(filePath)
		if !errors.Is(err, errMemoChangedDuringRead) {
			return item, err
		}
		lastErr = err
	}
	return memoFile{}, lastErr
}

func parseMemoFileOnce(filePath string) (memoFile, error) {
	absolutePath, err := filepath.Abs(filePath)
	if err != nil {
		return memoFile{}, fmt.Errorf("resolve %s: %w", filePath, err)
	}
	file, err := os.Open(absolutePath)
	if err != nil {
		return memoFile{}, fmt.Errorf("open %s: %w", absolutePath, err)
	}
	defer file.Close()
	before, err := file.Stat()
	if err != nil {
		return memoFile{}, fmt.Errorf("stat open memo %s: %w", absolutePath, err)
	}

	data, err := io.ReadAll(file)
	if err != nil {
		return memoFile{}, fmt.Errorf("read %s: %w", absolutePath, err)
	}
	frontmatterData, body, err := splitMemoDocument(data)
	if err != nil {
		return memoFile{}, fmt.Errorf("parse %s: %w", absolutePath, err)
	}
	var frontmatter memoFrontmatter
	if err := yaml.Unmarshal(frontmatterData, &frontmatter); err != nil {
		return memoFile{}, fmt.Errorf("parse %s frontmatter: %w", absolutePath, err)
	}
	if afterMemoRead != nil {
		afterMemoRead()
	}
	after, err := file.Stat()
	if err != nil {
		return memoFile{}, fmt.Errorf("stat read memo %s: %w", absolutePath, err)
	}
	pathInfo, err := os.Stat(absolutePath)
	if err != nil {
		return memoFile{}, fmt.Errorf("stat %s: %w", absolutePath, err)
	}
	if before.Size() != after.Size() ||
		before.ModTime() != after.ModTime() ||
		!os.SameFile(after, pathInfo) {
		return memoFile{}, fmt.Errorf("%w: %s", errMemoChangedDuringRead, absolutePath)
	}
	item := memo{
		ID:         strings.TrimSpace(frontmatter.ID),
		Repository: strings.TrimSpace(frontmatter.Repository),
		Name:       strings.TrimSpace(frontmatter.Name),
		Summary:    strings.TrimSpace(frontmatter.Summary),
		Body:       string(body),
		Status:     strings.TrimSpace(frontmatter.Status),
		CreatedAt:  strings.TrimSpace(frontmatter.CreatedAt),
		UpdatedAt:  strings.TrimSpace(frontmatter.UpdatedAt),
	}
	if err := validateCanonicalMemo(&item); err != nil {
		return memoFile{}, fmt.Errorf("parse %s: %w", absolutePath, err)
	}
	return memoFile{
		memo:    item,
		Path:    absolutePath,
		Size:    after.Size(),
		ModTime: after.ModTime().UnixNano(),
	}, nil
}

func splitMemoDocument(data []byte) ([]byte, []byte, error) {
	line, next, ok := nextMemoLine(data, 0)
	if !ok || string(line) != "---" {
		return nil, nil, fmt.Errorf("missing YAML frontmatter")
	}
	frontmatterStart := next
	for next <= len(data) {
		lineStart := next
		line, next, ok = nextMemoLine(data, lineStart)
		if !ok {
			break
		}
		if string(line) != "---" {
			continue
		}
		bodyStart := next
		if bytes.HasPrefix(data[bodyStart:], []byte("\r\n")) {
			bodyStart += 2
		} else if bytes.HasPrefix(data[bodyStart:], []byte("\n")) {
			bodyStart++
		}
		return data[frontmatterStart:lineStart], data[bodyStart:], nil
	}
	return nil, nil, fmt.Errorf("unterminated YAML frontmatter")
}

func nextMemoLine(data []byte, start int) ([]byte, int, bool) {
	if start >= len(data) {
		return nil, start, false
	}
	end := bytes.IndexByte(data[start:], '\n')
	if end < 0 {
		return bytes.TrimSuffix(data[start:], []byte("\r")), len(data), true
	}
	end += start
	return bytes.TrimSuffix(data[start:end], []byte("\r")), end + 1, true
}

func validateCanonicalMemo(item *memo) error {
	required := []struct {
		name  string
		value string
	}{
		{"memo_id", item.ID},
		{"name", item.Name},
		{"summary", item.Summary},
		{"status", item.Status},
		{"created_at", item.CreatedAt},
		{"updated_at", item.UpdatedAt},
	}
	for _, field := range required {
		if strings.TrimSpace(field.value) == "" {
			return fmt.Errorf("%s must not be empty", field.name)
		}
	}
	if err := validateMemoID(item.ID); err != nil {
		return err
	}
	if item.Repository != "" {
		if _, _, err := parseRepositoryName(item.Repository); err != nil {
			return err
		}
	}
	if err := validateName(item.Name); err != nil {
		return err
	}
	if item.Status != "wip" && item.Status != "done" {
		return fmt.Errorf("invalid status %q", item.Status)
	}
	createdAt, err := normalizeLegacyTime(item.CreatedAt)
	if err != nil {
		return fmt.Errorf("created_at: %w", err)
	}
	updatedAt, err := normalizeLegacyTime(item.UpdatedAt)
	if err != nil {
		return fmt.Errorf("updated_at: %w", err)
	}
	item.Summary = strings.TrimSpace(item.Summary)
	item.CreatedAt = createdAt
	item.UpdatedAt = updatedAt
	return nil
}

func equalMemo(first, second memo) bool {
	return first.ID == second.ID &&
		first.Repository == second.Repository &&
		first.Name == second.Name &&
		first.Summary == second.Summary &&
		first.Body == second.Body &&
		first.Status == second.Status &&
		first.CreatedAt == second.CreatedAt &&
		first.UpdatedAt == second.UpdatedAt
}

func marshalMemoFile(item memo) ([]byte, error) {
	if err := validateCanonicalMemo(&item); err != nil {
		return nil, err
	}
	var output bytes.Buffer
	if err := writeMarkdown(&output, item); err != nil {
		return nil, err
	}
	return output.Bytes(), nil
}

func writeMemoFileAtomic(filePath string, item memo) error {
	data, err := marshalMemoFile(item)
	if err != nil {
		return err
	}
	directory := filepath.Dir(filePath)
	temporaryPath, err := createMemoTemporary(directory, data)
	if err != nil {
		return err
	}
	defer os.Remove(temporaryPath)
	if err := os.Rename(temporaryPath, filePath); err != nil {
		return fmt.Errorf("save memo: %w", err)
	}
	return nil
}

func writeNewMemoFileAtomic(filePath string, item memo) (memoFile, error) {
	if _, err := os.Stat(filePath); err == nil {
		return memoFile{}, fmt.Errorf("memo path already exists: %s", filePath)
	} else if !os.IsNotExist(err) {
		return memoFile{}, fmt.Errorf("inspect memo path %s: %w", filePath, err)
	}
	if err := writeMemoFileAtomic(filePath, item); err != nil {
		return memoFile{}, err
	}
	return parseMemoFile(filePath)
}

func markMemoFileDone(filePath string, now time.Time) (memoFile, error) {
	item, err := parseMemoFile(filePath)
	if err != nil {
		return memoFile{}, err
	}
	updated := item.memo
	updated.Status = "done"
	updated.UpdatedAt = formatTimestamp(now)
	data, err := marshalMemoFile(updated)
	if err != nil {
		return memoFile{}, err
	}
	temporary, err := createMemoTemporary(filepath.Dir(item.Path), data)
	if err != nil {
		return memoFile{}, err
	}
	defer os.Remove(temporary)
	if beforeMemoStatusReplace != nil {
		beforeMemoStatusReplace()
	}
	current, err := parseMemoFile(item.Path)
	if err != nil {
		return memoFile{}, err
	}
	if current.Size != item.Size || current.ModTime != item.ModTime || !equalMemo(current.memo, item.memo) {
		return memoFile{}, fmt.Errorf("memo changed while marking done: %s", item.Path)
	}
	if err := os.Rename(temporary, item.Path); err != nil {
		return memoFile{}, fmt.Errorf("save memo status: %w", err)
	}
	result, err := parseMemoFile(item.Path)
	if err != nil {
		return memoFile{}, err
	}
	return result, nil
}

func createMemoTemporary(directory string, data []byte) (string, error) {
	if err := ensureMemoDirectory(directory); err != nil {
		return "", err
	}

	temporary, err := os.CreateTemp(directory, ".memo-write-*")
	if err != nil {
		return "", fmt.Errorf("create temporary memo: %w", err)
	}
	path := temporary.Name()
	if err := temporary.Chmod(0o600); err != nil {
		temporary.Close()
		os.Remove(path)
		return "", fmt.Errorf("secure temporary memo: %w", err)
	}
	if _, err := temporary.Write(data); err != nil {
		temporary.Close()
		os.Remove(path)
		return "", fmt.Errorf("write temporary memo: %w", err)
	}
	if err := temporary.Close(); err != nil {
		os.Remove(path)
		return "", fmt.Errorf("close temporary memo: %w", err)
	}
	return path, nil
}

func ensureMemoDirectory(directory string) error {
	if err := os.MkdirAll(directory, 0o700); err != nil {
		return fmt.Errorf("create memo directory: %w", err)
	}
	if err := os.Chmod(directory, 0o700); err != nil {
		return fmt.Errorf("secure memo directory: %w", err)
	}
	return nil
}

func normalizeLegacyTime(value string) (string, error) {
	layouts := []string{time.RFC3339Nano, time.RFC3339, "2006-01-02T15:04:05-0700"}
	for _, layout := range layouts {
		parsed, err := time.Parse(layout, value)
		if err == nil {
			return formatTimestamp(parsed), nil
		}
	}
	return "", fmt.Errorf("invalid ISO8601 timestamp %q", value)
}
