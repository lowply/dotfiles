package main

import (
	"database/sql"
	"encoding/json"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func newTestStore(t *testing.T) *store {
	t.Helper()
	index, err := openIndex(filepath.Join(t.TempDir(), "memo.db"))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		if err := index.close(); err != nil {
			t.Error(err)
		}
	})
	return index
}

func testMemo(id, name, summary, body string) memo {
	now := formatTimestamp(time.Now())
	return memo{
		ID:         id,
		Repository: "lowply/dotfiles",
		Name:       name,
		Summary:    summary,
		Body:       body,
		Status:     "wip",
		CreatedAt:  now,
		UpdatedAt:  now,
	}
}

func testIndexedMemoFile(t *testing.T, id, name, summary, body string) memoFile {
	t.Helper()
	item := testMemo(id, name, summary, body)
	path := writeTestMemoFile(t, item)
	parsed, err := parseMemoFile(path)
	if err != nil {
		t.Fatal(err)
	}
	return parsed
}

func TestIndexSearchIncludesCanonicalPath(t *testing.T) {
	index := newTestStore(t)
	item := testIndexedMemoFile(t, "memo-1", "sqlite-index", "Use SQLite for ranked search", "Searchable body.")
	if err := index.replaceIndexRecords([]memoFile{item}, nil); err != nil {
		t.Fatal(err)
	}
	results, err := index.search("ranked search", "wip", 5)
	if err != nil {
		t.Fatal(err)
	}
	if len(results) != 1 || results[0].Path != item.Path || results[0].MatchReason != "full_text" {
		t.Fatalf("unexpected results: %#v", results)
	}
	encoded, err := json.Marshal(results[0])
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(string(encoded), `"body"`) {
		t.Fatalf("search leaked body: %s", encoded)
	}
}

func TestIndexExactIDStatusAndListOrder(t *testing.T) {
	index := newTestStore(t)
	older := testIndexedMemoFile(t, "older", "older", "Older summary", "Older body")
	older.CreatedAt = "2026-08-20T00:00:00Z"
	older.UpdatedAt = older.CreatedAt
	newer := testIndexedMemoFile(t, "newer", "newer", "Newer summary", "Newer body")
	newer.CreatedAt = "2026-08-21T00:00:00Z"
	newer.UpdatedAt = newer.CreatedAt
	newer.Status = "done"
	if err := index.replaceIndexRecords([]memoFile{older, newer}, nil); err != nil {
		t.Fatal(err)
	}
	results, err := index.search("newer", "done", 5)
	if err != nil || len(results) != 1 || results[0].MatchReason != "id" {
		t.Fatalf("exact results = %#v, err = %v", results, err)
	}
	items, err := index.list("")
	if err != nil {
		t.Fatal(err)
	}
	if len(items) != 2 || items[0].ID != "older" || items[1].ID != "newer" {
		t.Fatalf("unexpected list order: %#v", items)
	}
	done, err := index.list("done")
	if err != nil || len(done) != 1 || done[0].ID != "newer" {
		t.Fatalf("done list = %#v, err = %v", done, err)
	}
}

func TestIndexReplacesAndRemovesCanonicalRecords(t *testing.T) {
	index := newTestStore(t)
	item := testIndexedMemoFile(t, "memo-1", "sqlite-index", "Initial summary", "Initial body.")
	if err := index.replaceIndexRecords([]memoFile{item}, nil); err != nil {
		t.Fatal(err)
	}
	item.Summary = "Changed summary"
	item.Body = "Changed body."
	if err := writeMemoFileAtomic(item.Path, item.memo); err != nil {
		t.Fatal(err)
	}
	var err error
	item, err = parseMemoFile(item.Path)
	if err != nil {
		t.Fatal(err)
	}
	if err := index.replaceIndexRecords([]memoFile{item}, nil); err != nil {
		t.Fatal(err)
	}
	if _, err := index.search("Changed", "", 5); err != nil {
		t.Fatal(err)
	}
	if err := index.replaceIndexRecords(nil, []string{item.Path}); err != nil {
		t.Fatal(err)
	}
	if _, err := index.search("Changed", "", 5); err == nil {
		t.Fatal("removed record remained searchable")
	}
}

func TestStoreRejectsUnsupportedLegacySchema(t *testing.T) {
	path := filepath.Join(t.TempDir(), "memo.db")
	database, err := sql.Open("sqlite", path)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := database.Exec(`CREATE TABLE schema_migrations(version INTEGER PRIMARY KEY, applied_at TEXT NOT NULL);
		INSERT INTO schema_migrations(version, applied_at) VALUES(1, '2026-08-22T00:00:00Z')`); err != nil {
		t.Fatal(err)
	}
	if err := database.Close(); err != nil {
		t.Fatal(err)
	}
	_, err = openIndex(path)
	if err == nil || !strings.Contains(err.Error(), "legacy memo database schema version 1 is unsupported") {
		t.Fatalf("error = %v, want unsupported legacy schema error", err)
	}
	if strings.Contains(err.Error(), "migrate-sqlite") {
		t.Fatalf("error refers to removed command: %v", err)
	}
}
