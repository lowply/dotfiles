package main

import (
	"errors"
	"os"
	"path/filepath"
	"strings"

	"github.com/lowply/markdownstore"
)

var errLegacyCommandRemoved = errors.New("legacy memo command is unavailable")

var memoSearchWeights = []float64{0.5, 1, 2, 1}

type store struct {
	inner *markdownstore.Store
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
	ID          string   `json:"id"`
	Repository  string   `json:"repository"`
	Name        string   `json:"name"`
	Summary     string   `json:"summary"`
	Status      string   `json:"status"`
	CreatedAt   string   `json:"created_at"`
	UpdatedAt   string   `json:"updated_at"`
	Path        string   `json:"path"`
	MatchReason string   `json:"match_reason,omitempty"`
	Rank        *float64 `json:"rank,omitempty"`
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
	directory, err := defaultMemoDirectory()
	if err != nil {
		return nil, err
	}
	if databasePath == "" {
		databasePath, err = defaultDatabasePath()
		if err != nil {
			return nil, err
		}
	} else if os.Getenv("MEMO_DIR") == "" {
		directory = filepath.Dir(databasePath)
	}
	return openIndexAt(directory, databasePath)
}

func openIndexAt(directory, databasePath string) (*store, error) {
	inner, err := markdownstore.Open(markdownstore.Config{
		Directory: directory, DatabasePath: databasePath, Pattern: "*.md",
		EntityName: "memo", SchemaID: "memo/1", Fields: memoMetadataFields(),
		SearchWeights: memoSearchWeights, Codec: memoCodec{},
	})
	if err != nil {
		return nil, err
	}
	return &store{inner: inner}, nil
}

func (s *store) close() error {
	return s.inner.Close()
}

func (s *store) replaceIndexRecords(changed []memoFile, removed []string) error {
	entries := make([]markdownstore.Entry, 0, len(changed))
	for _, item := range changed {
		entries = append(entries, entryFromMemoFile(item))
	}
	return s.inner.ReplaceIndexRecords(entries, removed)
}

func (s *store) getByID(id string) (searchResult, error) {
	result, err := s.inner.Get(id, nil)
	if err != nil {
		return searchResult{}, err
	}
	return searchResultFromLibrary(result, false), nil
}

func (s *store) hasID(id string) (bool, error) {
	return s.inner.HasID(id)
}

func (s *store) search(query, status string, limit int) ([]searchResult, error) {
	results, err := s.inner.Search(markdownstore.SearchQuery{
		Text: query, Filters: statusFilter(status), Limit: limit,
	})
	if err != nil {
		return nil, err
	}
	return searchResultsFromLibrary(results, true), nil
}

func (s *store) list(status string) ([]searchResult, error) {
	results, err := s.inner.List(statusFilter(status))
	if err != nil {
		return nil, err
	}
	return searchResultsFromLibrary(results, false), nil
}

func searchResultsFromLibrary(results []markdownstore.Result, includeRank bool) []searchResult {
	converted := make([]searchResult, 0, len(results))
	for _, result := range results {
		converted = append(converted, searchResultFromLibrary(result, includeRank))
	}
	return converted
}

func searchResultFromLibrary(result markdownstore.Result, includeRank bool) searchResult {
	converted := searchResult{
		ID: result.ID, Repository: result.Metadata["repository"], Name: result.Metadata["name"],
		Summary: result.Metadata["summary"], Status: result.Metadata["status"],
		CreatedAt: result.Metadata["created_at"], UpdatedAt: result.Metadata["updated_at"],
		Path:        result.Path,
		MatchReason: result.MatchReason,
	}

	if includeRank && result.MatchReason == "full_text" {
		rank := result.Rank
		converted.Rank = &rank
	}
	return converted
}

func statusFilter(status string) map[string]string {
	if status == "" {
		return nil
	}
	return map[string]string{"status": status}
}

func memoMetadataFields() []markdownstore.MetadataField {
	return []markdownstore.MetadataField{
		{Name: "repository"},
		{Name: "name", Required: true},
		{Name: "summary", Required: true},
		{Name: "status", Required: true},
		{Name: "created_at", Required: true},
		{Name: "updated_at", Required: true},
	}
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
