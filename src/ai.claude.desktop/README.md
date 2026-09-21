# ai.claude.desktop

An **unofficial** Flatpak repackage of [Claude Desktop for Linux](https://code.claude.com/docs/en/desktop-linux)
(currently in beta). Anthropic ships the app only as a `.deb`; this manifest
downloads that official, signed package onto your own machine at *install*
time (an `extra-data` source) and runs it inside a Flatpak sandbox via
[zypak](https://github.com/refi64/zypak). No Anthropic code or binaries are
redistributed in this repository — only packaging metadata.

Claude Code (the integrated terminal/editor/diff-review tab) runs commands on
the **host**, not inside the sandbox, via a small Go relay
([host-spawn](https://github.com/1player/host-spawn)) that talks to the
`org.freedesktop.Flatpak` portal. That's what lets it see your real `git`,
`node`, `python`, and project tools instead of the empty runtime.

Supports `x86_64` and `aarch64`.

## Install

Add the shared remote once (see the [root README](../../README.md#install) for the scope caveat and the
migration from the old per-app remote), then:

```bash
flatpak install flatpaks ai.claude.desktop
flatpak update
```

To build it yourself instead of using the prebuilt, signed remote, run `bin/build ai.claude.desktop` from the
repository root (see [Build locally](../../README.md#build-locally)).

## Credits

Built on top of two existing Claude Desktop Flatpak projects:

- [dewzor/ClaudeDesktop](https://github.com/dewzor/ClaudeDesktop)
  (`io.github.dewzor.ClaudeDesktop`) — the manifest shape used here: the
  `extra-data` fetch (Flathub-compatible, no proprietary redistribution),
  `finish-args`, `.desktop`/metainfo/icon handling, and the `host-spawn` /
  `host-shell` / `host-exec` / `host-git` relay that lets Claude Code reach the
  host's real toolchain. It in turn credits
  [gordonmessmer/com.anthropic.Claude](https://github.com/gordonmessmer/com.anthropic.Claude)
  for the original finish-args/launcher shape.
- [jennifgcrl/claude-desktop-flatpak](https://github.com/jennifgcrl/claude-desktop-flatpak)
  (`me.jezh.ClaudeDesktop`) — pinning the `.deb` straight from Anthropic's own
  apt repo (`downloads.claude.ai/claude-desktop/apt/stable`, the basis for this
  manifest's `x-checker-data: debian-repo` updater) and the Cowork/QEMU/OVMF
  module referenced under "What works / what doesn't" below.

## Updating

The pinned version and per-arch `sha256`/`size` live in `ai.claude.desktop.yml`. Each `extra-data`
source carries `x-checker-data` of type `debian-repo`, pointed at Anthropic's own apt repo
(`downloads.claude.ai/claude-desktop/apt/stable`), so `flatpak-external-data-checker` can detect new
releases without scraping a redirect endpoint. The repo's update-checker workflow runs it daily and opens
a PR; merging that PR rebuilds and republishes the remote, with no manual step.

To check for updates locally instead, from the repository root:

```sh
docker run --rm -v "$PWD:/checker" -w /checker \
  ghcr.io/flathub/flatpak-external-data-checker:latest \
  --update src/ai.claude.desktop/ai.claude.desktop.yml
git diff
bin/build ai.claude.desktop
```

## What works / what doesn't

- **Chat, Claude Code** (integrated terminal, editor, diff review): work.
  Claude Code's shell commands and `git` run on the host via `host-spawn`
  (see `claude-desktop.sh`, `host-shell.sh`, `host-exec.sh`, `host-git.sh`).
- **Credentials, notifications, tray icon**: wired up via the Secret Service
  (`org.freedesktop.secrets`, KWallet), notification, and StatusNotifier
  D-Bus names in `finish-args`.
- **Cowork** (the sandboxed-VM feature): **not included by default.** The
  `.deb` bundles the VM image and `virtiofsd`, but not `qemu-system-x86_64`
  itself, and the app looks for UEFI firmware at a hardcoded `/usr/share/OVMF`
  path that doesn't exist in the read-only runtime. Building QEMU + OVMF from
  source and adding `--device=kvm` (or `--device=all`, for the KVM +
  `vhost-vsock` pair Cowork needs) makes it work — see
  [jennifgcrl/claude-desktop-flatpak](https://github.com/jennifgcrl/claude-desktop-flatpak)
  for a complete, working module for that.
- **Sandbox caveat for Claude Code:** the app itself runs inside the Flatpak
  sandbox, but its shell commands and `git` are relayed to the host, so they
  see your real toolchain (`--filesystem=home` covers project file access, and
  shares `~/.claude` with the CLI). Narrow that to specific project
  directories if you want tighter isolation.

## Permissions

See `finish-args` in the manifest — notably `--filesystem=home` (broad; needed
for Claude Code/Cowork to work with arbitrary project directories) and
`--talk-name=org.freedesktop.Flatpak` (lets `host-spawn` run commands on the
host — see "What works" above).

## How it works

1. `flatpak-builder` builds `host-spawn` from vendored Go sources and installs
   the launcher scripts, `.desktop` entry, icons and AppStream metadata — all
   at build time, without touching the proprietary payload.
2. At **install** time, Flatpak downloads the official per-arch `.deb`
   (checksum-pinned in the manifest) as an `extra-data` source, then runs
   `apply_extra`.
3. `apply_extra` unpacks the `.deb` (an `ar` archive containing a `data.tar.xz`)
   with `bsdtar`, drops the SUID `chrome-sandbox` (zypak replaces it), and
   patches the Electron app's desktop-filename via
   `patch-electron-desktop-filename` so the Wayland `app_id` matches this
   app's `.desktop` entry.
4. `claude-desktop.sh` launches the bundled Electron binary through
   `zypak-wrapper`, after probing the `org.freedesktop.Flatpak` portal and
   pointing `$SHELL` / `$CLAUDE_CODE_SHELL_PREFIX` at the `host-*` wrappers so
   Claude Code's terminal and agent commands run on the host.

## Disclaimer

Not affiliated with or endorsed by Anthropic. "Claude" and related marks
belong to Anthropic PBC. This repository only contains packaging metadata —
no Anthropic code or binaries are redistributed here; they are fetched from
Anthropic's own servers at install time.
