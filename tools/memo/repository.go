package main

import (
	"errors"
	"fmt"
	"net/url"
	"os/exec"
	"path"
	"strings"
)

type repository struct {
	Root  string
	Owner string
	Name  string
}

func resolveRepository() (string, error) {
	root, err := gitOutput("rev-parse", "--show-toplevel")
	if err != nil {
		var exitError *exec.ExitError
		if errors.As(err, &exitError) {
			return "", nil
		}
		return "", fmt.Errorf("detect Git repository: %w", err)
	}

	remote, err := gitOutput("-C", root, "config", "--get", "remote.origin.url")
	if err != nil {
		var exitError *exec.ExitError
		if errors.As(err, &exitError) && exitError.ExitCode() == 1 {
			return "", nil
		}
		return "", fmt.Errorf("resolve remote.origin.url: %w", err)
	}
	if remote == "" {
		return "", nil
	}

	owner, name, err := parseRemoteURL(remote)
	if err != nil {
		return "", err
	}
	return owner + "/" + name, nil
}

func gitOutput(args ...string) (string, error) {
	output, err := exec.Command("git", args...).Output()
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(output)), nil
}

func parseRemoteURL(remote string) (string, string, error) {
	remote = strings.TrimSpace(remote)
	if remote == "" {
		return "", "", fmt.Errorf("could not parse repository owner/name")
	}

	repoPath := ""
	if strings.Contains(remote, "://") {
		parsed, err := url.Parse(remote)
		if err != nil {
			return "", "", fmt.Errorf("could not parse remote.origin.url: %w", err)
		}
		repoPath = parsed.Path
	} else if colon := strings.Index(remote, ":"); colon >= 0 {
		repoPath = remote[colon+1:]
	} else {
		repoPath = remote
	}

	repoPath = strings.TrimSuffix(strings.Trim(path.Clean(repoPath), "/"), ".git")
	parts := strings.Split(repoPath, "/")
	if len(parts) < 2 {
		return "", "", fmt.Errorf("could not parse repository owner/name")
	}
	owner := parts[len(parts)-2]
	name := parts[len(parts)-1]
	if owner == "" || name == "" || owner == "." || name == "." {
		return "", "", fmt.Errorf("could not parse repository owner/name")
	}
	return owner, name, nil
}

func parseRepositoryName(value string) (string, string, error) {
	parts := strings.Split(value, "/")
	if len(parts) != 2 || parts[0] == "" || parts[1] == "" {
		return "", "", fmt.Errorf("repository must use owner/name format")
	}
	return parts[0], parts[1], nil
}
