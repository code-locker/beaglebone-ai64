# Skills

Know-how and skills learned while working on the BeagleBone AI-64. One folder
per topic, each with a `README.md` that captures the concepts, commands, and
gotchas so they're reusable later.

## Index

These are Claude skills (`<topic>/SKILL.md`, loaded via `.claude/skills` → `skills/`).

- [workspace-setup/](workspace-setup/) — personal code-locker identity on any PC, clone, verify.
- [build-image/](build-image/) — build boot chain + kernel, prerequisites, failure table.
- [kernel-dev/](kernel-dev/) — edit/rebuild kernel, DTS, modules; bump the fork.
- [new-application/](new-application/) — new app from `_template`, cross-compile, run.
- [deploy-and-test/](deploy-and-test/) — SD card / board deploy, serial console, boot debug.
- [git-workflow/](git-workflow/) — develop branch model, submodule bumps, switching PCs.
- [add-skill/](add-skill/) — how to add or update a skill here.
- [beaglebone-embedded-linux/](beaglebone-embedded-linux/) — TDA4VM / J721E boot
  flow background: TF-A + OP-TEE + U-Boot and the arm64 kernel.

## Adding a skill

Follow [add-skill/SKILL.md](add-skill/SKILL.md): `skills/<topic-name>/SKILL.md` with
`name` + `description` frontmatter, then add it to the index above.
