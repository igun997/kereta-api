---
name: rflutter
description: Use for ANY Flutter or Dart build, analyze, test, pub, codegen or release (apk, appbundle, web) in a project with pubspec.yaml. Runs flutter on a remote machine (instabox, Daytona or an SSH server) instead of the user's computer, which may be a small laptop that freezes on local builds. Also use when asked to set up remote Flutter builds, install tools on the build machine, add/choose a build instance, run the app on the user's phone with hot reload, or when a command prints "SETUP REQUIRED".
---

# rflutter: build Flutter on a remote machine, not on the user's laptop

The user's computer is often small (think 8 GB RAM). A local `flutter build apk` runs Gradle and can freeze it. **Never run `flutter build/run/test/analyze/drive`, `dart analyze/test/run/compile` or `./gradlew` locally.** Use rflutter: it syncs the working tree (uncommitted and private code, plus `path:` dependencies) to a remote machine over SSH, runs flutter there with persistent Gradle/pub caches, and streams the result back. No GitHub access is involved. Light commands (`flutter pub add`, `flutter doctor`, `dart format`, `flutter clean`) may run locally.

Flutter, a JDK and the Android SDK install themselves on the remote at first use (several minutes, once).

## How to call it

Prefer the MCP server (`rflutter mcp`) when its tools are available:

| Tool | Use |
|---|---|
| `flutter` | `args` = what follows `flutter`: `["build","apk","--release"]`, `["build","appbundle","--release","--flavor","prod"]`, `["build","web"]`, `["test"]`, `["analyze"]`, `["pub","get"]`. Start with `"dart"` for the Dart CLI: `["dart","run","build_runner","build"]`. Output is compact: compile errors, Gradle failures, analyzer findings, failing tests first. After a successful `build` the output files are copied into the local `build/` directory (`pull: false` to skip). |
| `install` | extras on the remote: `android`, `flutter` + version, `linux`, `chrome`, `bundletool`, `firebase`, `fastlane`, `pub` + packages, `npm` + packages, `apt` + packages. `name: "list"` shows all. |
| `shell` | inspect the remote workspace (`ls build/app/outputs`, `du -sh build`). Not for building. |
| `sync` | upload changes without running anything |
| `instances` | list instances with descriptions and live state |
| `setup` | readiness check; returns exact steps for whatever is missing |
| `power` | `up` / `down` an instance |
| `workspaces` | disk usage per project on an instance |

Without MCP, use the CLI: `rflutter build apk --release`, `rflutter test`, `rflutter analyze`, `rflutter install android`, `rflutter -i NAME build appbundle`. Anything that is not an rflutter command is passed to flutter and run remotely; `rflutter dart ...` runs the Dart CLI. Add `--no-pull` (before the subcommand) to keep build outputs on the remote.

## Running the app on the user's phone: only the user can do it

`rflutter run` needs a terminal and the phone plugged into the user's computer: it tunnels the user's adb server to the build machine, builds remotely, installs on the phone and hot-reloads when files are saved (`r` reload, `R` restart, `q` quit). `-d web-server` serves the app on a local port instead. **Do not run it yourself** (the MCP `flutter` tool refuses `run`); tell the user to run `rflutter run` in their own terminal. `rflutter devices` lists the phones. If it reports no device, the steps are for the user (USB debugging, allow the computer).

To put a build on the user's phone without a live session: `rflutter --install build apk --release` (or `--debug`; `--install=SERIAL` when several phones are attached; `--split-per-abi` installs the matching apk). The CLI pulls the apk and installs it with the user's local adb, so it changes the user's phone: do it only when asked. It is a CLI flag (before the subcommand), not an MCP option; with MCP, build with the `flutter` tool and tell the user the apk path under `build/`.

## Release builds and signing

`android/key.properties` and keystores (`*.jks`, `*.keystore`) are never uploaded by default, and neither are `.env` files. A signed release build needs the user to opt in, in `rflutter.toml`:

```toml
[sync]
include = ["android/key.properties", "android/app/upload-keystore.jks"]
[remote]
forward_env = ["KEYSTORE_PASSWORD"]   # copied from the user's shell at run time, never written to disk
```

Explain that this copies those files to the build machine and let the user decide. Never read, print or paste signing secrets yourself. `rflutter remote doctor` warns when `key.properties` exists but is not listed. iOS and macOS builds (`build ios|ipa|macos`) need a Mac instance (ssh backend); on a Linux instance rflutter says so and stops.

## Several instances

A user may have more than one machine (for example a small default and a big one for release builds). Always check the list before choosing: the `instances` tool, or `rflutter instances`.

- Omit `instance` to use the default.
- If there is **no default** the call fails with SETUP REQUIRED and the list; pick by description or ask the user.
- Choose a bigger instance only for heavy work (release builds, large projects) and only when its description says it is bigger.
- **Never** create, delete or reconfigure instances yourself. Suggest it to the user.
- When the session is over and the user is done building, `power` `down` saves money (builds start it automatically).

## Flutter version

By default the remote uses the latest stable Flutter, or the version in the project's `.fvmrc`. `remote.flutter_version` in `rflutter.toml` overrides it (`"3.35.1"`). Versions install side by side. Match what the user develops with: an app built with a different Flutter than the user's can differ.

## When something is missing: SETUP REQUIRED

If rflutter (CLI exit code 3, or an MCP result with `isError` and `structuredContent.setup_required`) prints **SETUP REQUIRED**, it lists numbered steps. Follow them literally:

1. Run steps **not** marked `[USER]` yourself.
2. For `[USER]` steps (browser login, API keys, installing software, dashboard) show the user the exact command or URL in plain words, then **wait** for their confirmation. Do not retry in a loop.
3. Never invent, guess, print or ask the user to paste credentials into the chat. Keys go into the environment or the provider's own login.
4. When the user says it is done, call `setup` (or `rflutter onboard --live`) to verify, then retry the original command.

Typical first-time path for a new user (explain it simply, they may not know Flutter or servers):

- No instance yet, simplest: `npx instabox@latest` (signs in and installs the instabox CLI; a free tier exists), then `rflutter instances add main --backend instabox --default --description "general purpose builder"`. Headless agents: `instabox login --agent --name rflutter` prints a claim page and code; relay both to the user and wait.
- Daytona: the user runs `daytona login` once, or sets `DAYTONA_API_KEY`. Register with `--set cpu=4 --set memory=8 --set disk=20`: Daytona's default sandbox is too small for Android builds.
- Own server: `rflutter instances add vps --backend ssh --set host=user@server`; key-based SSH must already work. Debian/Ubuntu with sudo or root.
- Flutter plus the Android SDK need about 8 GB of disk on the remote. If a build fails with "No space left", tell the user; `rflutter remote ls` shows usage, `rflutter remote gc --days 7 --yes` frees old workspaces (ask first).
- One-command project setup: `rflutter init` (writes `rflutter.toml`, this skill, the MCP registration and a guard that blocks local `flutter build` in Claude Code).

## Reading results

- The header line shows the instance, SUCCESS/FAILED with the exit code and sync stats.
- Fix compile errors top to bottom; analyzer infos and warnings only if asked. Rerun the same `flutter` call to verify.
- Only the first diagnostics are shown if there are many; fix those and rerun.
- Exit 75 / "gave up waiting for the remote workspace lock": another build runs in this workspace; retry shortly.
- Gradle failures show the `What went wrong` block. A missing Android package or NDK: `rflutter install android-pkg "ndk;VERSION"` or add it to `remote.android_packages`.
- Private pub packages or git dependencies need a token on the remote: add the variable name to `forward_env` in `rflutter.toml`.
- Disk full on the remote: `rflutter remote ls`, then `rflutter remote gc --days 7 --yes` (ask first) or `flutter clean` through the `flutter` tool.
- **Never** run `rflutter remote destroy`, `rflutter remote rm` or `rflutter remote gc --all` on your own initiative: they delete the user's remote machine or work. Offer them and wait for an explicit yes.
