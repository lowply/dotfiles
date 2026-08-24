package main

import "testing"

func TestParseRemoteURL(t *testing.T) {
	t.Parallel()
	tests := []struct {
		name   string
		remote string
		owner  string
		repo   string
	}{
		{name: "SSH", remote: "git@github.com:lowply/dotfiles.git", owner: "lowply", repo: "dotfiles"},
		{name: "HTTPS", remote: "https://github.com/lowply/dotfiles.git", owner: "lowply", repo: "dotfiles"},
		{name: "SSH URL", remote: "ssh://git@github.com/lowply/dotfiles.git", owner: "lowply", repo: "dotfiles"},
	}
	for _, test := range tests {
		test := test
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			owner, repo, err := parseRemoteURL(test.remote)
			if err != nil {
				t.Fatal(err)
			}
			if owner != test.owner || repo != test.repo {
				t.Fatalf("got %s/%s, want %s/%s", owner, repo, test.owner, test.repo)
			}
		})
	}
}

func TestParseRemoteURLRejectsInvalidPath(t *testing.T) {
	t.Parallel()
	if _, _, err := parseRemoteURL("dotfiles"); err == nil {
		t.Fatal("expected invalid repository path to fail")
	}
}
