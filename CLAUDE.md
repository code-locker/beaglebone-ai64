# CLAUDE.md — beaglebone-ai64

Personal BeagleBone AI-64 (TI TDA4VM / J721E) workspace: boot chain (TF-A +
OP-TEE + U-Boot), arm64 kernel, and my own applications. See README.md for
layout and `versions.lock` for pinned upstream commits.

## Identity — personal project only

- GitHub owner: **code-locker**. Commit identity comes from the local, untracked
  `~/.gitconfig-codelocker` (applied via `includeIf`) — this repo is public, so
  never write personal emails, key fingerprints, or key material into it.
- **Never** use any work/office identity, email, repo, host, or SSH key here.
  Before committing/pushing, check `git config user.name` is `code-locker`.
- Git goes through the SSH alias `github-codelocker` (key `~/.ssh/id_ed25519_codelocker`).
  Activate it with the local (not in repo) `codelocker-ssh` script — see `skills/workspace-setup/`.

## Workflow

- `develop` is the working branch; `main` only gets release merges.
- Work on `feat/<thing>` / `fix/<thing>` off `develop`, PR into `develop`
  (CI auto-deletes the merged branch). Details: `skills/git-workflow/`.
- Never commit build outputs or images (`build/`, `*.img*`, boot binaries).
- Moving a submodule or firmware pin ⇒ update `versions.lock` in the same commit.

## Skills — keep adding them

Claude skills live in `skills/<name>/SKILL.md` (`.claude/skills` is a symlink to
`skills/`, so they load automatically on any clone). Whenever a task teaches
something reusable — a build fix, a board bring-up step, a kernel/driver
procedure, a test recipe — create or update a skill and add it to
`skills/README.md`. Follow `skills/add-skill/SKILL.md`.
