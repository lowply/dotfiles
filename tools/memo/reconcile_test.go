package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func writeMemoAt(t *testing.T, path string, item memo) {
	t.Helper()
	if err := writeMemoFileAtomic(path, item); err != nil {
		t.Fatal(err)
	}
}

func assertSearchResult(t *testing.T, index *store, query, path string) {
	t.Helper()
	results, err := index.search(query, "", 5)
	if err != nil {
		t.Fatal(err)
	}
	if len(results) != 1 || results[0].Path != path {
		t.Fatalf("unexpected search results: %#v", results)
	}
}

func TestReconcileTracksDirectFileLifecycle(t *testing.T) {
	directory := t.TempDir()
	index, err := openIndex(filepath.Join(t.TempDir(), "memo.db"))
	if err != nil {
		t.Fatal(err)
	}
	defer index.close()
	path := filepath.Join(directory, "2026-08-22-abc12345-lowply-dotfiles-direct-edit.md")
	writeMemoAt(t, path, testMemo("abc12345", "direct-edit", "Initial summary", "Initial body"))

	if err := reconcile(directory, index); err != nil {
		t.Fatal(err)
	}
	assertSearchResult(t, index, "Initial", path)

	item := testMemo("abc12345", "direct-edit", "Changed summary", "Changed body")
	item.UpdatedAt = "2026-08-22T02:00:00Z"
	writeMemoAt(t, path, item)
	if err := reconcile(directory, index); err != nil {
		t.Fatal(err)
	}
	assertSearchResult(t, index, "Changed", path)

	renamed := filepath.Join(directory, "renamed.md")
	if err := os.Rename(path, renamed); err != nil {
		t.Fatal(err)
	}
	if err := reconcile(directory, index); err != nil {
		t.Fatal(err)
	}
	assertSearchResult(t, index, "Changed", renamed)

	if err := os.Remove(renamed); err != nil {
		t.Fatal(err)
	}
	if err := reconcile(directory, index); err != nil {
		t.Fatal(err)
	}
	if _, err := index.search("Changed", "", 5); err == nil {
		t.Fatal("deleted canonical file remained searchable")
	}
}

func TestReconcileSkipsUnchangedFiles(t *testing.T) {
	directory := t.TempDir()
	index, err := openIndex(filepath.Join(t.TempDir(), "memo.db"))
	if err != nil {
		t.Fatal(err)
	}
	defer index.close()
	writeMemoAt(t, filepath.Join(directory, "memo.md"), testMemo("abc12345", "unchanged", "Stable summary", "Stable body"))
	if err := reconcile(directory, index); err != nil {
		t.Fatal(err)
	}

	calls := 0
	afterMemoRead = func() {
		calls++
	}
	t.Cleanup(func() { afterMemoRead = nil })
	if err := reconcile(directory, index); err != nil {
		t.Fatal(err)
	}
	if calls != 0 {
		t.Fatalf("unchanged files parsed %d times", calls)
	}
}

func TestReconcileRejectsMalformedAndDuplicateFilesWithoutMutation(t *testing.T) {
	directory := t.TempDir()
	index, err := openIndex(filepath.Join(t.TempDir(), "memo.db"))
	if err != nil {
		t.Fatal(err)
	}

	defer index.close()
	original := filepath.Join(directory, "original.md")
	writeMemoAt(t, original, testMemo("original1", "original", "Original summary", "Original body"))
	if err := reconcile(directory, index); err != nil {
		t.Fatal(err)
	}

	first := filepath.Join(directory, "first.md")
	second := filepath.Join(directory, "second.md")
	writeMemoAt(t, first, testMemo("duplicate", "first", "First summary", "First body"))
	writeMemoAt(t, second, testMemo("duplicate", "second", "Second summary", "Second body"))
	bad := filepath.Join(directory, "bad.md")
	if err := os.WriteFile(bad, []byte("not a memo"), 0o600); err != nil {
		t.Fatal(err)
	}

	err = reconcile(directory, index)
	if err == nil || !strings.Contains(err.Error(), bad) {
		t.Fatalf("unexpected malformed error: %v", err)
	}
	if _, err := index.search("Original", "", 5); err != nil {
		t.Fatalf("existing index mutated after validation failure: %v", err)
	}

	if err := os.Remove(bad); err != nil {
		t.Fatal(err)
	}
	err = reconcile(directory, index)
	if err == nil || !strings.Contains(err.Error(), first) || !strings.Contains(err.Error(), second) {
		t.Fatalf("unexpected duplicate error: %v", err)
	}
}

func TestReconcileAllowsChangedFileToReleaseItsPreviousID(t *testing.T) {
	directory := t.TempDir()
	index, err := openIndex(filepath.Join(t.TempDir(), "memo.db"))
	if err != nil {
		t.Fatal(err)
	}

	defer index.close()
	firstPath := filepath.Join(directory, "first.md")
	writeMemoAt(t, firstPath, testMemo("old-id", "first", "First", "Body"))
	if err := reconcile(directory, index); err != nil {
		t.Fatal(err)
	}

	writeMemoAt(t, firstPath, testMemo("new-id", "first", "First", "Body"))
	secondPath := filepath.Join(directory, "second.md")
	writeMemoAt(t, secondPath, testMemo("old-id", "second", "Second", "Body"))
	if err := reconcile(directory, index); err != nil {
		t.Fatal(err)
	}
	if _, err := index.getByID("new-id"); err != nil {
		t.Fatal(err)
	}
	if _, err := index.getByID("old-id"); err != nil {
		t.Fatal(err)
	}
}

func TestReconcileAllowsChangedFilesToSwapIDs(t *testing.T) {
	directory := t.TempDir()
	index, err := openIndex(filepath.Join(t.TempDir(), "memo.db"))
	if err != nil {
		t.Fatal(err)
	}
	defer index.close()
	firstPath := filepath.Join(directory, "first.md")
	secondPath := filepath.Join(directory, "second.md")
	writeMemoAt(t, firstPath, testMemo("first-id", "first", "First", "Body"))
	writeMemoAt(t, secondPath, testMemo("second-id", "second", "Second", "Body"))
	if err := reconcile(directory, index); err != nil {
		t.Fatal(err)
	}

	writeMemoAt(t, firstPath, testMemo("second-id", "first", "First", "Body"))
	writeMemoAt(t, secondPath, testMemo("first-id", "second", "Second", "Body"))
	if err := reconcile(directory, index); err != nil {
		t.Fatal(err)
	}
	first, err := index.getByID("first-id")
	if err != nil {
		t.Fatal(err)
	}
	if first.Path != secondPath {
		t.Fatalf("first-id path = %q, want %q", first.Path, secondPath)
	}
	second, err := index.getByID("second-id")
	if err != nil {
		t.Fatal(err)
	}
	if second.Path != firstPath {
		t.Fatalf("second-id path = %q, want %q", second.Path, firstPath)
	}
}
