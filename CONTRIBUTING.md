# Contributing & workflow

## Branch model

| Branch    | Purpose                                                        |
|-----------|---------------------------------------------------------------|
| `main`    | Stable. **Only** updated by merging `develop` at a release.    |
| `develop` | Default working branch. All day-to-day changes land here.     |

Typical cycle:

```bash
git switch develop
# ... work, commit ...
git push origin develop

# at a release:
git switch main
git merge --no-ff develop
git tag -a vX.Y -m "Release vX.Y"
git push origin main --tags
```

For larger changes use short-lived feature branches off `develop`
(`feature/<thing>`), open a PR into `develop`, then merge.

## Changing u-boot or the kernel (and PR-ing upstream)

The u-boot and kernel-build trees are **git submodules** under `sources/`,
pointing at your forks (`code-locker/u-boot`, `code-locker/arm64-multiplatform`).
Because they're real clones of your forks, you can branch/commit/push/PR normally
from inside them.

### 1. Make the change in the submodule

```bash
cd sources/u-boot
git switch -c fix/bbai64-something          # branch off your fork
# ... edit, build via ../../scripts/build-uboot.sh, test on board ...
git commit -am "bbai64: fix something"
git push origin fix/bbai64-something        # pushes to code-locker/u-boot
```

### 2. Open the PR upstream

On GitHub, open a PR from `code-locker/u-boot:fix/bbai64-something` into the
upstream base (`beagleboard/u-boot`). Keep your fork's default branch in sync:

```bash
git remote add upstream https://github.com/beagleboard/u-boot.git   # once
git fetch upstream
git rebase upstream/<base-branch>
```

(Same pattern for `sources/arm64-multiplatform` → `RobertCNelson/arm64-multiplatform`.)

### 3. Record the new submodule pointer in this repo

After the submodule commit you build/test against, pin it here:

```bash
cd ../..                     # back to repo root
git add sources/u-boot       # records the new submodule SHA
# update versions.lock to match
git commit -m "Bump u-boot submodule to <sha>"
git push origin develop
```

## Rules

- **Never commit build outputs or images.** `build/`, `deploy/`, `*.img*`, and
  boot binaries are git-ignored — keep it that way.
- Update `versions.lock` whenever you move a submodule or bump a firmware repo.
- Keep each application self-contained under `applications/applicationN/`.
