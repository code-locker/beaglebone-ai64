# Applications

My own applications that run on the BeagleBone AI-64. Each application lives in
its own folder and is fully self-contained — source, build files, and a README
with build & run steps.

```
applications/
├── _template/        # copy this to start a new app
├── application1/
├── application2/
└── ...
```

## Start a new application

```bash
cp -r applications/_template applications/application1
# edit applications/application1/README.md, CMakeLists.txt, src/
```

## Conventions

- Each app has its own `README.md`, `CMakeLists.txt`, and `src/`.
- Cross-compile for the A72 (aarch64) target; the README documents the toolchain.
- Build directories (`build/`, `cmake-build-*/`) are git-ignored — never commit binaries.
