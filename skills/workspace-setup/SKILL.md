---
name: workspace-setup
description: Set up this beaglebone-ai64 workspace on a new or existing PC with the personal code-locker GitHub identity (SSH key, host alias, scoped git identity), clone recursively, and verify no work identity leaks. Use when moving to another machine, when clone/push fails with "Permission denied (publickey)", or when commits show the wrong author.
---

# Workspace setup (personal identity, any PC)

This repo and its submodules (`code-locker/u-boot`, `code-locker/arm64-multiplatform`)
belong to the **personal** GitHub account `code-locker`. The machine may also
have a work GitHub identity as its default SSH key / global email — it must
never be used here.

**This repo is public.** Personal email, key fingerprint, and the key itself
live only on each PC — never commit them.

## Local pieces (per PC, outside the repo)

| Piece | Where | Effect |
|---|---|---|
| personal SSH private key | `~/.ssh/id_ed25519_codelocker` (chmod 600) | registered on the code-locker account |
| `codelocker-ssh` | `~/.local/bin/codelocker-ssh` | checks the key's fingerprint, writes the pieces below, loads the key into ssh-agent, tests GitHub |
| `Host github-codelocker` | `~/.ssh/config` | `IdentitiesOnly yes` → only that key is offered |
| `url."git@github-codelocker:code-locker/".insteadOf = git@github.com:code-locker/` | `~/.gitconfig` | all code-locker SSH URLs (incl. `.gitmodules`) use the alias |
| `…pushInsteadOf = https://github.com/code-locker/` | `~/.gitconfig` | HTTPS-cloned repos push via the alias |
| `includeIf "gitdir:<workspace>/"` → `~/.gitconfig-codelocker` | `~/.gitconfig` | personal name/email only under the workspace dir |

## New PC — steps

```bash
# from a PC that already has them:
scp oldpc:~/.ssh/id_ed25519_codelocker      ~/.ssh/ && chmod 600 ~/.ssh/id_ed25519_codelocker
scp oldpc:~/.local/bin/codelocker-ssh       ~/.local/bin/
# edit CODELOCKER_WORKSPACE default in the script if the workspace path differs
codelocker-ssh                               # → "active: Hi code-locker!"

mkdir -p <workspace> && cd <workspace>
git clone --recurse-submodules -b develop git@github.com:code-locker/beaglebone-ai64.git
```

Each session: run `codelocker-ssh` once to load the key (`codelocker-ssh --off` unloads it).

## Verify (always, before the first commit on a machine)

```bash
git config user.name                       # → code-locker
ssh -T git@github-codelocker               # → Hi code-locker!
git -C sources/u-boot config user.name     # submodules inherit it too
git remote -v; git -C sources/u-boot remote -v
```

## Gotchas

- `ssh -T git@github.com` greeting a *different* user means the default key is
  someone else's — expected; only `github-codelocker` must say code-locker.
- `includeIf gitdir:` needs the trailing `/` and an absolute (or `~/`) path;
  if the workspace moves, run `CODELOCKER_WORKSPACE=<new dir>/ codelocker-ssh`.
- Don't run `gh auth setup-git` / `gh pr create` here if `gh` is logged into another
  account — it would act as that account.
- `Permission denied (publickey)` on a submodule = key not loaded or not the
  registered one; run `codelocker-ssh` (it checks the fingerprint).
