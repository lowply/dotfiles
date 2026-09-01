package main

import (
	"bytes"
	"os"
	"path/filepath"
	"strings"
	"testing"
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

func TestParseMemoFileAcceptsEmptyOrMissingRepository(t *testing.T) {
	for _, test := range []struct {
		name      string
		transform func(string) string
	}{
		{
			name: "Empty",
			transform: func(content string) string {
				return strings.Replace(content, `repository: "lowply/dotfiles"`, `repository: ""`, 1)
			},
		},
		{
			name: "Missing",
			transform: func(content string) string {
				return strings.Replace(content, "repository: \"lowply/dotfiles\"\n", "", 1)
			},
		},
	} {
		t.Run(test.name, func(t *testing.T) {
			data, err := marshalMemoFile(testMemo("abc12345", "unscoped", "Unscoped memo", "Body."))
			if err != nil {
				t.Fatal(err)
			}
			path := filepath.Join(t.TempDir(), "memo.md")
			if err := os.WriteFile(path, []byte(test.transform(string(data))), 0o600); err != nil {
				t.Fatal(err)
			}
			parsed, err := parseMemoFile(path)
			if err != nil {
				t.Fatal(err)
			}
			if parsed.Repository != "" {
				t.Fatalf("repository = %q, want empty", parsed.Repository)
			}
		})
	}
}

func TestMarshalUnscopedMemoEmitsEmptyRepository(t *testing.T) {
	item := testMemo("abc12345", "unscoped", "Unscoped memo", "")
	item.Repository = ""
	data, err := marshalMemoFile(item)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(data), "repository: \"\"\n") {
		t.Fatalf("missing empty repository metadata: %q", data)
	}
}

func TestMemoCodecEmitsExistingCanonicalFormat(t *testing.T) {
	item := testMemo("abc12345", "canonical-format", "Canonical format", "Body.")
	data, err := (memoCodec{}).Marshal(recordFromMemo(item))
	if err != nil {
		t.Fatal(err)
	}
	want := "---\n" +
		"memo_id: \"abc12345\"\n" +
		"repository: \"lowply/dotfiles\"\n" +
		"name: \"canonical-format\"\n" +
		"summary: \"Canonical format\"\n" +
		"status: \"wip\"\n" +
		"created_at: \"" + item.CreatedAt + "\"\n" +
		"updated_at: \"" + item.UpdatedAt + "\"\n" +
		"---\n\nBody."
	if string(data) != want {
		t.Fatalf("canonical data changed:\nwant %q\ngot  %q", want, data)
	}
}

func TestDefaultMemoDirectoryUsesEnvironmentOverride(t *testing.T) {
	override := filepath.Join(t.TempDir(), "custom-memos")
	t.Setenv("MEMO_DIR", override)
	got, err := defaultMemoDirectory()
	if err != nil {
		t.Fatal(err)
	}
	if got != override {
		t.Fatalf("directory = %q, want %q", got, override)
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
