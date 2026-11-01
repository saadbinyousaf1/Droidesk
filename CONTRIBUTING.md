<!-- // © https://saadbinyousaf.dev/ © // -->
# Contributing to Droidesk

Thanks for helping. Droidesk aims to stay small: an easy, portable way to create and root Android emulators on Windows. Changes that keep it simple and reliable are the easiest to accept.

## Reporting bugs

Use the [bug report form](https://github.com/saadbinyousaf1/Droidesk/issues/new?template=bug_report.yml) and include:

- your Windows version and build (`winver`)
- the Droidesk version from the status bar
- the Android version and system image of the device
- the full console log of the failed task

## Suggesting features

Open a [feature request](https://github.com/saadbinyousaf1/Droidesk/issues/new?template=feature_request.yml) and describe the problem you're solving, not only the solution. Features that bring Android Studio back as a dependency, or that need an installer, are out of scope.

## Pull requests

1. Fork the repository and create a branch from `main`.
2. Read [Development](docs/development.md) for how the engine, tasks and UI fit together.
3. Keep each pull request to one change, and describe how you tested it on Windows 10 or 11.
4. Follow the conventions:
   - PowerShell must run on Windows PowerShell 5.1.
   - Save `.ps1` files as UTF-8 with BOM.
   - Start child processes with `CreateNoWindow`.
   - Keep the signature line above each script section.
   - Keep UI text plain and specific.
5. Update `docs/` when behaviour changes, and add a line to `docs/changes.md` under an *Unreleased* heading.

By contributing, you agree that your contribution is released under the [MIT License](LICENSE).
