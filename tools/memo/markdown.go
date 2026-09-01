package main

import (
	"bytes"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/lowply/markdownstore"
	"gopkg.in/yaml.v3"
)

var (
	afterMemoRead   func()
	beforeMemoWrite func()
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

type memoCodec struct{}

func defaultMemoDirectory() (string, error) {
	if configured := strings.TrimSpace(os.Getenv("MEMO_DIR")); configured != "" {
		return filepath.Abs(filepath.Clean(configured))
	}
	home, err := os.UserHomeDir()
	if err != nil {
		return "", fmt.Errorf("resolve home directory: %w", err)
	}
	return filepath.Join(home, ".copilot", "memo"), nil
}

func (memoCodec) Parse(_ string, frontmatterData, body []byte) (markdownstore.Document, error) {
	var frontmatter memoFrontmatter
	if err := yaml.Unmarshal(frontmatterData, &frontmatter); err != nil {
		return markdownstore.Document{}, fmt.Errorf("parse frontmatter: %w", err)
	}
	if afterMemoRead != nil {
		afterMemoRead()
	}
	item := memo{
		ID: strings.TrimSpace(frontmatter.ID), Repository: strings.TrimSpace(frontmatter.Repository),
		Name: strings.TrimSpace(frontmatter.Name), Summary: strings.TrimSpace(frontmatter.Summary),
		Body: string(body), Status: strings.TrimSpace(frontmatter.Status),
		CreatedAt: strings.TrimSpace(frontmatter.CreatedAt),
		UpdatedAt: strings.TrimSpace(frontmatter.UpdatedAt),
	}
	if err := validateCanonicalMemo(&item); err != nil {
		return markdownstore.Document{}, err
	}
	return documentFromMemo(item), nil
}

func (memoCodec) Marshal(document markdownstore.Document) ([]byte, error) {
	item := memoFromDocument(document)
	if err := validateCanonicalMemo(&item); err != nil {
		return nil, err
	}
	var output bytes.Buffer
	if err := writeMarkdown(&output, item); err != nil {
		return nil, err
	}
	if beforeMemoWrite != nil {
		beforeMemoWrite()
	}
	return output.Bytes(), nil
}

func documentFromMemo(item memo) markdownstore.Document {
	return markdownstore.Document{
		ID: item.ID,
		Metadata: map[string]string{
			"repository": item.Repository,
			"name":       item.Name,
			"summary":    item.Summary,
			"status":     item.Status,
			"created_at": item.CreatedAt,
			"updated_at": item.UpdatedAt,
		},
		Body:        item.Body,
		SortKey:     item.CreatedAt,
		SearchSlots: []string{item.Repository, item.Name, item.Summary, item.Body},
	}
}

func recordFromMemo(item memo) markdownstore.Document {
	return documentFromMemo(item)
}

func memoFromDocument(document markdownstore.Document) memo {
	return memo{
		ID: document.ID, Repository: document.Metadata["repository"],
		Name: document.Metadata["name"], Summary: document.Metadata["summary"],
		Body: document.Body, Status: document.Metadata["status"],
		CreatedAt: document.Metadata["created_at"], UpdatedAt: document.Metadata["updated_at"],
	}
}

func entryFromMemoFile(item memoFile) markdownstore.Entry {
	return markdownstore.Entry{
		Document: documentFromMemo(item.memo), Path: item.Path,
		Fingerprint: markdownstore.Fingerprint{Size: item.Size, ModTimeNS: item.ModTime},
	}
}

func memoFileFromEntry(entry markdownstore.Entry) memoFile {
	return memoFile{
		memo: memoFromDocument(entry.Document), Path: entry.Path,
		Size: entry.Fingerprint.Size, ModTime: entry.Fingerprint.ModTimeNS,
	}
}

func parseMemoFile(filePath string) (memoFile, error) {
	entry, err := markdownstore.ReadFile(
		filePath, memoCodec{}, memoMetadataFields(), memoSearchWeights, "memo",
	)
	if err != nil {
		return memoFile{}, err
	}
	return memoFileFromEntry(entry), nil
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
	return first == second
}

func marshalMemoFile(item memo) ([]byte, error) {
	return (memoCodec{}).Marshal(documentFromMemo(item))
}

func writeMemoFileAtomic(filePath string, item memo) error {
	data, err := marshalMemoFile(item)
	if err != nil {
		return err
	}
	return markdownstore.WriteFileAtomic(filePath, data)
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
