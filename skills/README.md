# Skills

Know-how and skills learned while working on the BeagleBone AI-64. One folder
per topic, each with a `README.md` that captures the concepts, commands, and
gotchas so they're reusable later.

## Index

- [beaglebone-embedded-linux/](beaglebone-embedded-linux/) — cross-compiling the
  TI K3 boot chain (TF-A + OP-TEE + U-Boot) and the arm64 kernel; boot flow of
  the TDA4VM / J721E.

## Adding a skill

```bash
mkdir -p skills/<topic-name>
$EDITOR skills/<topic-name>/README.md
```

Keep each skill self-contained: what it is, why it matters, the exact commands,
and the mistakes to avoid.
