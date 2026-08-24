package main

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"sort"
)

var parseCanonicalMemo = parseMemoFile

func reconcile(directory string, index *store) error {
	paths, err := filepath.Glob(filepath.Join(directory, "*.md"))
	if err != nil {
		return fmt.Errorf("list canonical memos: %w", err)
	}
	sort.Strings(paths)
	indexed, err := index.indexedFiles()
	if err != nil {
		return err
	}

	current := make(map[string]bool, len(paths))
	changed := make([]memoFile, 0)
	var parseErrors []error
	for _, path := range paths {
		absolute, err := filepath.Abs(filepath.Clean(path))
		if err != nil {
			parseErrors = append(parseErrors, fmt.Errorf("resolve %s: %w", path, err))
			continue
		}
		current[absolute] = true
		info, err := os.Stat(absolute)
		if err != nil {
			parseErrors = append(parseErrors, fmt.Errorf("stat %s: %w", absolute, err))
			continue
		}
		existing, ok := indexed[absolute]
		if ok && existing.Size == info.Size() && existing.ModTime == info.ModTime().UnixNano() {
			continue
		}
		item, err := parseCanonicalMemo(absolute)
		if err != nil {
			parseErrors = append(parseErrors, err)
			continue
		}
		changed = append(changed, item)
	}
	if len(parseErrors) > 0 {
		return errors.Join(parseErrors...)
	}

	removed := make([]string, 0)
	idPaths := make(map[string][]string)
	for path, item := range indexed {
		if !current[path] {
			removed = append(removed, path)
			continue
		}
		idPaths[item.ID] = append(idPaths[item.ID], path)
	}
	for _, item := range changed {
		previousID := item.ID
		if previous, ok := indexed[item.Path]; ok {
			previousID = previous.ID
		}
		for i, path := range idPaths[previousID] {
			if path == item.Path {
				idPaths[previousID] = append(idPaths[previousID][:i], idPaths[previousID][i+1:]...)
				break
			}
		}
		idPaths[item.ID] = append(idPaths[item.ID], item.Path)
	}
	sort.Strings(removed)
	var duplicateErrors []error
	for id, duplicatePaths := range idPaths {
		if len(duplicatePaths) < 2 {
			continue
		}
		sort.Strings(duplicatePaths)
		duplicateErrors = append(duplicateErrors,
			fmt.Errorf("duplicate memo ID %q in %s", id, joinPaths(duplicatePaths)))
	}
	if len(duplicateErrors) > 0 {
		return errors.Join(duplicateErrors...)
	}
	return index.replaceIndexRecords(changed, removed)
}

func joinPaths(paths []string) string {
	result := ""
	for index, path := range paths {
		if index > 0 {
			result += " and "
		}
		result += path
	}
	return result
}
