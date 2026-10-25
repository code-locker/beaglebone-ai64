---
name: git-workflow
description: Commit, branch, push, and PR in the beaglebone-ai64 repo and its u-boot / arm64-multiplatform submodules with the personal code-locker identity — develop-based feature branches, submodule pointer bumps, versions.lock updates, upstream PRs, and syncing work between PCs. Use before any commit, push, PR, submodule bump, or when switching machines.
---

# Git workflow

Full rules: `CONTRIBUTING.md`.

## Pre-flight (every commit)

```bash
git config user.name       # must be code-locker (personal identity) — stop otherwise
git status                 # nothing from build/, no *.img / *.bin staged
```

Wrong identity → `workspace-setup`. Never use a work identity, email, or repo.

## Day-to-day

```bash
git switch develop && git pull
git switch -c feat/<thing>             # or fix/<thing>
# ... commit ...
git push -u origin feat/<thing>
gh pr create --repo code-locker/beaglebone-ai64 --base develop   # only if gh is logged in as code-locker
```

Otherwise open the PR on github.com. Merged branches into `develop` are
auto-deleted by `.github/workflows/delete-develop-branches.yml`.
`main` changes only at a release (`git merge --no-ff develop` + tag).

## Submodule changes (u-boot / kernel)

1. Commit + push inside `sources/<sub>` on a branch (goes to `code-locker/<sub>`).
2. In the superproject: `git add sources/<sub>`, update its sha in `versions.lock`,
   commit both together.
3. Push the submodule **before** the superproject, or other clones get a
   pointer to a commit that doesn't exist on GitHub.

Upstream PRs: from `code-locker/u-boot` → `beagleboard/u-boot`,
`code-locker/arm64-multiplatform` → `RobertCNelson/arm64-multiplatform`.

## Continuing on another PC

Before leaving a PC: push every branch in the superproject **and** submodules
(`git push --recurse-submodules=on-demand`).
On the other PC: set up per `workspace-setup`, then

```bash
git fetch && git switch <branch> && git pull
git submodule update --init --recursive
```
