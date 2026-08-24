package main

import (
	"bytes"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func writeTestMemoFile(t *testing.T, item memo) string {
	t.Helper()
	path := filepath.Join(t.TempDir(), "memo.md")
	data, err := marshalMemoFile(item)
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, data, 0o600); err != nil {
		t.Fatal(err)
	}
	return path
}

func TestParseMemoFileReturnsCanonicalPathAndMemo(t *testing.T) {
	path := writeTestMemoFile(t, testMemo(
		"abc12345",
		"markdown-source",
		"Canonical summary",
		"# Heading\n\nBody.",
	))

	got, err := parseMemoFile(path)
	if err != nil {
		t.Fatal(err)
	}
	absolute, err := filepath.Abs(path)
	if err != nil {
		t.Fatal(err)
	}
	if got.Path != absolute || got.ID != "abc12345" || got.Body != "# Heading\n\nBody." {
		t.Fatalf("unexpected memo file: %#v", got)
	}
	if got.Size == 0 || got.ModTime == 0 {
		t.Fatalf("missing fingerprint: %#v", got)
	}
}

func TestParseMemoFileRejectsInvalidCanonicalFields(t *testing.T) {
	valid := testMemo("abc12345", "markdown-source", "Canonical summary", "Body.")
	tests := []struct {
		name    string
		replace string
		with    string
		want    string
	}{
		{name: "ID", replace: `memo_id: "abc12345"`, with: `memo_id: ""`, want: "memo_id"},
		{name: "Repository", replace: `repository: "lowply/dotfiles"`, with: `repository: "invalid"`, want: "owner/name"},
		{name: "Name", replace: `name: "markdown-source"`, with: `name: "Not Valid"`, want: "kebab-case"},
		{name: "Summary", replace: `summary: "Canonical summary"`, with: `summary: ""`, want: "summary"},
		{name: "Status", replace: `status: "wip"`, with: `status: "open"`, want: "invalid status"},
		{name: "CreatedAt", replace: "created_at:", with: "created_at: not-a-time #", want: "created_at"},
		{name: "UpdatedAt", replace: "updated_at:", with: "updated_at: not-a-time #", want: "updated_at"},
	}
	data, err := marshalMemoFile(valid)
	if err != nil {
		t.Fatal(err)
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			content := strings.Replace(string(data), test.replace, test.with, 1)
			path := filepath.Join(t.TempDir(), "invalid.md")
			if err := os.WriteFile(path, []byte(content), 0o600); err != nil {
				t.Fatal(err)
			}
			if _, err := parseMemoFile(path); err == nil || !strings.Contains(err.Error(), test.want) {
				t.Fatalf("error = %v, want text %q", err, test.want)
			}
		})
	}
}

func TestParseMemoFileAcceptsEmptyBody(t *testing.T) {
	item := testMemo("abc12345", "markdown-source", "Canonical summary", "")
	data, err := marshalMemoFile(item)
	if err != nil {
		t.Fatal(err)
	}
	path := filepath.Join(t.TempDir(), "empty.md")
	if err := os.WriteFile(path, data, 0o600); err != nil {
		t.Fatal(err)
	}
	parsed, err := parseMemoFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if parsed.Body != "" {
		t.Fatalf("body = %q, want empty", parsed.Body)
	}
}

func TestMemoFileRoundTripPreservesBodyWhitespace(t *testing.T) {
	item := testMemo("abc12345", "whitespace", "Whitespace summary",
		"    indented first line\n\nTrailing blanks follow\n\n")
	path := writeTestMemoFile(t, item)

	parsed, err := parseMemoFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if parsed.Body != item.Body {
		t.Fatalf("body changed:\nwant %q\ngot  %q", item.Body, parsed.Body)
	}
}

func TestMemoFileRoundTripPreservesMissingFinalNewline(t *testing.T) {
	item := testMemo("abc12345", "whitespace", "Whitespace summary", "no final newline")
	data, err := marshalMemoFile(item)
	if err != nil {
		t.Fatal(err)
	}
	data = bytes.TrimSuffix(data, []byte("\n"))
	path := filepath.Join(t.TempDir(), "memo.md")
	if err := os.WriteFile(path, data, 0o600); err != nil {
		t.Fatal(err)
	}

	parsed, err := parseMemoFile(path)
	if err != nil {
		t.Fatal(err)
	}
	rewritten, err := marshalMemoFile(parsed.memo)
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(rewritten, data) {
		t.Fatalf("memo changed:\nwant %q\ngot  %q", data, rewritten)
	}
}

func TestMarkMemoFileDonePreservesIdentityAndBody(t *testing.T) {
	item := testMemo("abc12345", "markdown-source", "Canonical summary", "# Heading\n\nBody.")
	item.CreatedAt = "2026-08-22T01:00:00Z"
	item.UpdatedAt = item.CreatedAt
	path := writeTestMemoFile(t, item)

	got, err := markMemoFileDone(path, time.Date(2026, 8, 22, 2, 0, 0, 0, time.UTC))
	if err != nil {
		t.Fatal(err)
	}
	if got.Status != "done" || got.UpdatedAt != "2026-08-22T02:00:00Z" {
		t.Fatalf("unexpected status update: %#v", got)
	}
	if got.ID != item.ID || got.CreatedAt != item.CreatedAt || got.Body != item.Body {
		t.Fatalf("immutable content changed: %#v", got)
	}
	info, err := os.Stat(path)
	if err != nil {
		t.Fatal(err)
	}
	if info.Mode().Perm() != 0o600 {
		t.Fatalf("mode = %v", info.Mode().Perm())
	}
}

func TestParseMemoFileRetriesAfterAtomicReplacement(t *testing.T) {
	path := writeTestMemoFile(t, testMemo("abc12345", "original", "Original summary", "Original body"))
	replacement := testMemo("abc12345", "replacement", "Replacement summary", "Replacement body")
	replaced := false
	afterMemoRead = func() {
		if replaced {
			return
		}
		replaced = true
		if err := writeMemoFileAtomic(path, replacement); err != nil {
			t.Fatal(err)
		}
	}
	t.Cleanup(func() { afterMemoRead = nil })

	got, err := parseMemoFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if got.Name != replacement.Name || got.Body != replacement.Body {
		t.Fatalf("parsed stale content: %#v", got)
	}
}

func TestMarkMemoFileDoneRefusesConcurrentEdit(t *testing.T) {
	path := writeTestMemoFile(t, testMemo("abc12345", "original", "Original summary", "Original body"))
	replacement := testMemo("abc12345", "replacement", "Replacement summary", "Replacement body")
	beforeMemoStatusReplace = func() {
		if err := writeMemoFileAtomic(path, replacement); err != nil {
			t.Fatal(err)
		}
		beforeMemoStatusReplace = nil
	}
	t.Cleanup(func() { beforeMemoStatusReplace = nil })

	if _, err := markMemoFileDone(path, time.Now()); err == nil || !strings.Contains(err.Error(), "changed while marking done") {
		t.Fatalf("unexpected error: %v", err)
	}
	got, err := parseMemoFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if got.Name != replacement.Name || got.Body != replacement.Body || got.Status != "wip" {
		t.Fatalf("concurrent edit was overwritten: %#v", got)
	}
}
