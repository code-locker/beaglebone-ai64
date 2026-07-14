# GitHub setup — one-time

This repo was scaffolded locally. Finish publishing it under
**github.com/code-locker** with the steps below. Two things need your GitHub
account (they can't be done for you): creating the repos/forks and pushing.

> `gh` CLI is not installed on this machine. Either install it
> (`sudo apt install gh` or https://cli.github.com) and `gh auth login`, or use
> the GitHub web UI where noted.

## 1. Fork the two upstreams you'll modify

Fork on github.com (the "Fork" button), or with `gh`:

```bash
gh repo fork beagleboard/u-boot --clone=false
gh repo fork RobertCNelson/arm64-multiplatform --clone=false
```

Result: `code-locker/u-boot` and `code-locker/arm64-multiplatform`.

> optee_os, trusted-firmware-a, and ti-linux-firmware are **not** forked — they're
> cloned at pinned versions by `scripts/fetch-firmware.sh`. Fork them later only
> if you decide to PR them too.

## 2. Create the monorepo on GitHub

Web UI: New repo → name `beaglebone-ai64`, **Public**, do **not** add README/license
(this repo already has them). Or with `gh` (run from the repo root, after step 3
initializes git):

```bash
gh repo create code-locker/beaglebone-ai64 --public --source=. --remote=origin --push=false
```

## 3. Initialize git locally (if not already done)

```bash
cd beaglebone-ai64
git init -b main
git add .
git commit -m "Initial BeagleBone AI-64 workspace scaffold"
git remote add origin https://github.com/code-locker/beaglebone-ai64.git
```

## 4. Wire the submodules to your forks

```bash
GH_USER=code-locker ./scripts/add-submodules.sh
git add .gitmodules sources
git commit -m "Add u-boot & kernel-build submodules pinned to build versions"
```

(This reuses your existing local clones in `Courses/BBB/build/` as a reference so
it doesn't re-download ~9 GB. Override with `REF_UBOOT=` / `REF_KBUILD=` if those
paths differ.)

## 5. Push main + create develop

```bash
git push -u origin main

git switch -c develop
git push -u origin develop
```

Then on GitHub → Settings → set **default branch = main**, and Branches → add a
protection rule on `main` if you want PR-only merges.

## 6. Verify a fresh clone builds

```bash
cd /tmp
git clone --recursive https://github.com/code-locker/beaglebone-ai64.git
cd beaglebone-ai64 && ./scripts/bootstrap.sh
```

---

### Notes
- If a submodule push is rejected for size, confirm you're pushing to **your fork**,
  not upstream, and that large build artifacts aren't staged.
- Keep `develop` as your working branch; merge to `main` only at releases
  (see [CONTRIBUTING.md](CONTRIBUTING.md)).
