package main

import (
	"database/sql"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	_ "modernc.org/sqlite"
)

const schemaVersion = 2

var (
	errUnsupportedLegacyDatabase = errors.New("legacy memo database schema version 1 is unsupported")
	errLegacyCommandRemoved      = errors.New("legacy memo command is unavailable")
)

type store struct {
	db *sql.DB
}

type memo struct {
	ID         string `json:"id"`
	Repository string `json:"repository"`
	Name       string `json:"name"`
	Summary    string `json:"summary"`
	Body       string `json:"body"`
	Status     string `json:"status"`
	CreatedAt  string `json:"created_at"`
	UpdatedAt  string `json:"updated_at"`
}

type indexedFile struct {
	ID      string
	Size    int64
	ModTime int64
}

type searchResult struct {
	ID          string  `json:"id"`
	Repository  string  `json:"repository"`
	Name        string  `json:"name"`
	Summary     string  `json:"summary"`
	Status      string  `json:"status"`
	CreatedAt   string  `json:"created_at"`
	UpdatedAt   string  `json:"updated_at"`
	Path        string  `json:"path"`
	MatchReason string  `json:"match_reason,omitempty"`
	Rank        float64 `json:"rank,omitempty"`
}

func defaultDatabasePath() (string, error) {
	if configured := os.Getenv("MEMO_DB_PATH"); configured != "" {
		return configured, nil
	}
	directory, err := defaultMemoDirectory()
	if err != nil {
		return "", err
	}
	return filepath.Join(directory, "memo.db"), nil
}

func openStore(databasePath string) (*store, error) {
	return openIndex(databasePath)
}

func openIndex(databasePath string) (*store, error) {
	if databasePath == "" {
		var err error
		databasePath, err = defaultDatabasePath()
		if err != nil {
			return nil, err
		}
	}
	directory := filepath.Dir(databasePath)
	if err := os.MkdirAll(directory, 0o700); err != nil {
		return nil, fmt.Errorf("create memo directory: %w", err)
	}
	if err := os.Chmod(directory, 0o700); err != nil {
		return nil, fmt.Errorf("secure memo directory: %w", err)
	}
	db, err := sql.Open("sqlite", databasePath)
	if err != nil {
		return nil, fmt.Errorf("open memo index: %w", err)
	}
	db.SetMaxOpenConns(1)
	if _, err := db.Exec(`PRAGMA foreign_keys = ON; PRAGMA busy_timeout = 5000; PRAGMA journal_mode = WAL;`); err != nil {
		db.Close()
		return nil, fmt.Errorf("configure memo index: %w", err)
	}
	result := &store{db: db}
	if err := result.migrate(); err != nil {
		db.Close()
		return nil, err
	}
	if err := os.Chmod(databasePath, 0o600); err != nil {
		db.Close()
		return nil, fmt.Errorf("secure memo index: %w", err)
	}
	return result, nil
}

func (s *store) close() error {
	return s.db.Close()
}

func (s *store) migrate() error {
	var hasMigrations int
	if err := s.db.QueryRow(`SELECT COUNT(*) FROM sqlite_master
		WHERE type = 'table' AND name = 'schema_migrations'`).Scan(&hasMigrations); err != nil {
		return fmt.Errorf("inspect memo index schema: %w", err)
	}
	if hasMigrations > 0 {
		var current int
		if err := s.db.QueryRow(`SELECT COALESCE(MAX(version), 0) FROM schema_migrations`).Scan(&current); err != nil {
			return fmt.Errorf("read schema version: %w", err)
		}
		if current == 1 {
			return errUnsupportedLegacyDatabase
		}
		if current > schemaVersion {
			return fmt.Errorf("memo database schema version %d is newer than supported version %d", current, schemaVersion)
		}
		if current == schemaVersion {
			return nil
		}
	}

	tx, err := s.db.Begin()
	if err != nil {
		return fmt.Errorf("begin index schema: %w", err)
	}
	defer tx.Rollback()
	if err := applySchemaV2(tx); err != nil {
		return err
	}
	if _, err := tx.Exec(`INSERT INTO schema_migrations(version, applied_at) VALUES(?, ?)`,
		schemaVersion, formatTimestamp(time.Now())); err != nil {
		return fmt.Errorf("record index schema: %w", err)
	}
	if err := tx.Commit(); err != nil {
		return fmt.Errorf("commit index schema: %w", err)
	}
	return nil
}

func applySchemaV2(tx *sql.Tx) error {
	statements := []string{
		`CREATE TABLE schema_migrations (
			version INTEGER PRIMARY KEY,
			applied_at TEXT NOT NULL
		)`,
		`CREATE TABLE memos (
			path TEXT PRIMARY KEY,
			file_size INTEGER NOT NULL,
			mod_time_ns INTEGER NOT NULL,
			id TEXT NOT NULL UNIQUE,
			repository TEXT NOT NULL,
			name TEXT NOT NULL,
			summary TEXT NOT NULL,
			body TEXT NOT NULL,
			status TEXT NOT NULL CHECK(status IN ('wip', 'done')),
			created_at TEXT NOT NULL,
			updated_at TEXT NOT NULL
		)`,
		`CREATE INDEX memos_status ON memos(status)`,
		`CREATE VIRTUAL TABLE memo_fts USING fts5(
			repository,
			name,
			summary,
			body,
			content='memos',
			content_rowid='rowid',
			tokenize='unicode61'
		)`,
		`CREATE TRIGGER memos_after_insert AFTER INSERT ON memos BEGIN
			INSERT INTO memo_fts(rowid, repository, name, summary, body)
			VALUES (new.rowid, new.repository, new.name, new.summary, new.body);
		END`,
		`CREATE TRIGGER memos_after_delete AFTER DELETE ON memos BEGIN
			INSERT INTO memo_fts(memo_fts, rowid, repository, name, summary, body)
			VALUES ('delete', old.rowid, old.repository, old.name, old.summary, old.body);
		END`,
		`CREATE TRIGGER memos_after_update AFTER UPDATE ON memos BEGIN
			INSERT INTO memo_fts(memo_fts, rowid, repository, name, summary, body)
			VALUES ('delete', old.rowid, old.repository, old.name, old.summary, old.body);
			INSERT INTO memo_fts(rowid, repository, name, summary, body)
			VALUES (new.rowid, new.repository, new.name, new.summary, new.body);
		END`,
	}
	for _, statement := range statements {
		if _, err := tx.Exec(statement); err != nil {
			return fmt.Errorf("apply index schema version 2: %w", err)
		}
	}
	return nil
}

func (s *store) indexedFiles() (map[string]indexedFile, error) {
	rows, err := s.db.Query(`SELECT path, id, file_size, mod_time_ns FROM memos`)
	if err != nil {
		return nil, fmt.Errorf("list indexed files: %w", err)
	}
	defer rows.Close()
	result := make(map[string]indexedFile)
	for rows.Next() {
		var path string
		var item indexedFile
		if err := rows.Scan(&path, &item.ID, &item.Size, &item.ModTime); err != nil {
			return nil, fmt.Errorf("read indexed file: %w", err)
		}
		result[path] = item
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("list indexed files: %w", err)
	}
	return result, nil
}

func (s *store) replaceIndexRecords(changed []memoFile, removed []string) error {
	tx, err := s.db.Begin()
	if err != nil {
		return fmt.Errorf("begin index update: %w", err)
	}
	defer tx.Rollback()
	for _, path := range removed {
		if _, err := tx.Exec(`DELETE FROM memos WHERE path = ?`, path); err != nil {
			return fmt.Errorf("remove indexed memo %s: %w", path, err)
		}
	}
	for _, item := range changed {
		if _, err := tx.Exec(`DELETE FROM memos WHERE path = ?`, item.Path); err != nil {
			return fmt.Errorf("replace indexed memo %s: %w", item.Path, err)
		}
	}
	for _, item := range changed {
		_, err := tx.Exec(`INSERT INTO memos(
			path, file_size, mod_time_ns, id, repository, name, summary, body,
			status, created_at, updated_at
		) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		ON CONFLICT(path) DO UPDATE SET
			file_size = excluded.file_size,
			mod_time_ns = excluded.mod_time_ns,
			id = excluded.id,
			repository = excluded.repository,
			name = excluded.name,
			summary = excluded.summary,
			body = excluded.body,
			status = excluded.status,
			created_at = excluded.created_at,
			updated_at = excluded.updated_at`,
			item.Path, item.Size, item.ModTime, item.ID, item.Repository, item.Name,
			item.Summary, item.Body, item.Status, item.CreatedAt, item.UpdatedAt)
		if err != nil {
			return fmt.Errorf("index memo %s: %w", item.Path, err)
		}
	}
	if err := tx.Commit(); err != nil {
		return fmt.Errorf("commit index update: %w", err)
	}
	return nil
}

func (s *store) getByID(id string) (searchResult, error) {
	var result searchResult
	err := s.db.QueryRow(`SELECT id, repository, name, summary, status,
		created_at, updated_at, path FROM memos WHERE id = ?`, id).Scan(
		&result.ID, &result.Repository, &result.Name, &result.Summary, &result.Status,
		&result.CreatedAt, &result.UpdatedAt, &result.Path)
	if errors.Is(err, sql.ErrNoRows) {
		return searchResult{}, fmt.Errorf("no memo found with ID %q", id)
	}
	if err != nil {
		return searchResult{}, fmt.Errorf("get indexed memo: %w", err)
	}
	return result, nil
}

func (s *store) hasID(id string) (bool, error) {
	var exists int
	if err := s.db.QueryRow(`SELECT EXISTS(SELECT 1 FROM memos WHERE id = ?)`, id).Scan(&exists); err != nil {
		return false, fmt.Errorf("check memo ID: %w", err)
	}
	return exists == 1, nil
}

func (s *store) search(query, status string, limit int) ([]searchResult, error) {
	exactQuery := `SELECT id, repository, name, summary, status, created_at, updated_at, path
		FROM memos WHERE id = ?`
	exactArgs := []any{query}
	if status != "" {
		exactQuery += ` AND status = ?`
		exactArgs = append(exactArgs, status)
	}
	exactQuery += ` ORDER BY updated_at DESC LIMIT ?`
	exactArgs = append(exactArgs, limit)
	rows, err := s.db.Query(exactQuery, exactArgs...)
	if err != nil {
		return nil, fmt.Errorf("search memo by ID: %w", err)
	}
	var exactResults []searchResult
	for rows.Next() {
		var result searchResult
		if err := rows.Scan(&result.ID, &result.Repository, &result.Name, &result.Summary,
			&result.Status, &result.CreatedAt, &result.UpdatedAt, &result.Path); err != nil {
			rows.Close()
			return nil, fmt.Errorf("read exact memo result: %w", err)
		}
		result.MatchReason = "id"
		exactResults = append(exactResults, result)
	}
	if err := rows.Close(); err != nil {
		return nil, fmt.Errorf("close exact memo results: %w", err)
	}
	if len(exactResults) > 0 {
		return exactResults, nil
	}

	fts := buildFTSQuery(query)
	if fts == "" {
		return nil, fmt.Errorf("search query must not be empty")
	}
	searchQuery := `SELECT m.id, m.repository, m.name, m.summary, m.status,
			m.created_at, m.updated_at, m.path,
			bm25(memo_fts, 0.5, 1.0, 2.0, 1.0)
		FROM memo_fts
		JOIN memos m ON m.rowid = memo_fts.rowid
		WHERE memo_fts MATCH ?`
	searchArgs := []any{fts}
	if status != "" {
		searchQuery += ` AND m.status = ?`
		searchArgs = append(searchArgs, status)
	}
	searchQuery += ` ORDER BY bm25(memo_fts, 0.5, 1.0, 2.0, 1.0), m.updated_at DESC LIMIT ?`
	searchArgs = append(searchArgs, limit)
	rows, err = s.db.Query(searchQuery, searchArgs...)
	if err != nil {
		return nil, fmt.Errorf("search memos: %w", err)
	}
	defer rows.Close()
	var results []searchResult
	for rows.Next() {
		var result searchResult
		if err := rows.Scan(&result.ID, &result.Repository, &result.Name, &result.Summary,
			&result.Status, &result.CreatedAt, &result.UpdatedAt, &result.Path, &result.Rank); err != nil {
			return nil, fmt.Errorf("read memo search result: %w", err)
		}
		result.MatchReason = "full_text"
		results = append(results, result)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("search memos: %w", err)
	}
	if len(results) == 0 {
		return nil, fmt.Errorf("no memo match for query %q", query)
	}
	return results, nil
}

func (s *store) list(status string) ([]searchResult, error) {
	query := `SELECT id, repository, name, summary, status, created_at, updated_at, path FROM memos`
	var args []any
	if status != "" {
		query += ` WHERE status = ?`
		args = append(args, status)
	}
	query += ` ORDER BY created_at ASC, rowid ASC`
	rows, err := s.db.Query(query, args...)
	if err != nil {
		return nil, fmt.Errorf("list memos: %w", err)
	}
	defer rows.Close()
	var results []searchResult
	for rows.Next() {
		var result searchResult
		if err := rows.Scan(&result.ID, &result.Repository, &result.Name, &result.Summary,
			&result.Status, &result.CreatedAt, &result.UpdatedAt, &result.Path); err != nil {
			return nil, fmt.Errorf("read memo list result: %w", err)
		}
		results = append(results, result)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("list memos: %w", err)
	}
	return results, nil
}

func buildFTSQuery(query string) string {
	terms := strings.Fields(query)
	quoted := make([]string, 0, len(terms))
	for _, term := range terms {
		term = strings.ReplaceAll(term, `"`, `""`)
		if term != "" {
			quoted = append(quoted, `"`+term+`"`)
		}
	}
	return strings.Join(quoted, " AND ")
}

func (s *store) create(repository, memo, *string) error {
	return errLegacyCommandRemoved
}

func (s *store) importMemo(repository, memo) error {
	return errLegacyCommandRemoved
}

func (s *store) get(string, string) (memo, error) {
	return memo{}, errLegacyCommandRemoved
}

func (s *store) update(string, string, *string, *string, *string) (memo, error) {
	return memo{}, errLegacyCommandRemoved
}

func (s *store) markDone(string) (memo, error) {
	return memo{}, errLegacyCommandRemoved
}

func (s *store) removeByID(string) (memo, error) {
	return memo{}, errLegacyCommandRemoved
}
