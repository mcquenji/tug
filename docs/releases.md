# Distributing Tug

Tug uses GitHub Actions and GitHub Releases; no Coolify service or download server is needed. `mcquenji/homebrew-tap` contains the Homebrew formula. Release archives contain a standalone CLI, so users do not need a Dart SDK to run it. Git and FVM are needed to inspect projects and generate their deployment build files.

## Install

On macOS or Linux:

```sh
brew install mcquenji/tap/tug
```

Homebrew installs the binary matching the machine's OS and CPU, plus Git and FVM. The native Mac builds require macOS 15 or later. Linux builds target ARM64 and x86-64 and are built on Ubuntu 22.04; use a compatible glibc-based distribution.

To update:

```sh
brew update
brew upgrade mcquenji/tap/tug
tug --version
```

If an older manually installed `tug` is earlier on PATH, `command -v tug` will identify it. Remove or move that old executable so the Homebrew installation is used.

On Windows, download `tug-v<VERSION>-windows-x64.zip` from [Releases](https://github.com/mcquenji/tug/releases), compare its SHA-256 with `SHA256SUMS`, extract `tug.exe`, and add its directory to your user PATH. Install Git and FVM separately. The Windows download is an unsigned x64 executable; native Windows ARM64, Scoop, WinGet and code signing are not included in this setup.

```powershell
Get-FileHash .\tug-v0.1.0-windows-x64.zip -Algorithm SHA256
.\tug.exe --version
```

## Publish a version

Every branch push and pull request runs analysis, tests, and a compiled-binary smoke check on all five targets. Only a stable `vMAJOR.MINOR.PATCH` tag publishes a release. The tag must match `version:` in its `pubspec.yaml`, and the release builds the exact tagged commit.

Use `commit-and-tag-version` from a clean checkout:

```sh
commit-and-tag-version
# Or choose the next version explicitly:
# commit-and-tag-version --release-as patch
git push --follow-tags origin main
```

`.versionrc` reads the current version from `pubspec.yaml` and bumps both that file and `lib/gen/version.g.dart`. The Dart file uses `tool/version_updater.cjs`, a custom updater, so the generated constant is included in the same release commit and tag as the changelog. No Dart generation command is needed for a version-only release.

If you edit the pubspec version manually, run `fvm dart run tool/generate.dart` and commit the generated version before tagging. The version test and generated-file check deliberately fail when these two files disagree.

The original `v0.2.0` tag predates this updater and contains a stale Dart version. Rerunning that tag will still fail; after pulling the fix, use `commit-and-tag-version --release-as patch` to publish a corrected `v0.2.1` tag without rewriting the old tag.

The workflow tests and compiles on native macOS ARM64/x64, Linux ARM64/x64, and Windows x64 runners, verifies the executable's embedded version outside the checkout, and uploads all five archives plus `SHA256SUMS`. It publishes the GitHub release only after every platform succeeds. Finally, it commits the new download URLs and checksums to `mcquenji/homebrew-tap`. Users receive it through `brew upgrade`.

`tool/build.dart` embeds the pubspec version directly; the build output is `build/tug` on Unix and `build/tug.exe` on Windows. FVM and Actions are pinned, and `.fvmrc` pins the SDK used for releases. Update the pins deliberately along with the lockfile and generated artifacts.

## Credentials and recovery

The release job uses GitHub's repository-scoped `GITHUB_TOKEN` to publish release assets. Only the final tap-update job receives `HOMEBREW_TAP_DEPLOY_KEY`, an SSH key with write access to the tap repository alone. The tap repository has its own deploy key; no personal access token or Coolify credentials are needed.

If a build fails, fix it and publish a new tag after updating the version. Do not move a tag that users may already have installed. A failed draft upload can be rerun before publication. Published assets are never replaced. If publishing succeeds but the tap update fails, use **Re-run failed jobs** in Actions; this updates the formula without rebuilding or replacing released assets. An older release cannot downgrade the formula.

The Release workflow also accepts an existing tag through **Run workflow** for recovery before publication. It is not a way to overwrite a published version.

For a new fork, change the repository and tap names in `tool/release.py` and `.github/workflows/release.yml`, create the tap repository, and configure its deploy key before publishing a tag.
