# flatpaks

Unofficial Flatpak builds that Flathub does not carry, published as one GPG-signed Flatpak remote:

```text
https://francoism90.github.io/flatpaks/index.flatpakrepo
```

| App                                                                                          | What it is                                       |
| -------------------------------------------------------------------------------------------- | ------------------------------------------------ |
| [`org.freedesktop.Sdk.Extension.podman`](src/org.freedesktop.Sdk.Extension.podman/README.md) | Podman SDK extension (upstream Flathub declined it) |

This repo replaces the separate `ai.claude.desktop`, `org.freedesktop.Sdk.Extension.podman` and
`com.visualstudio.code` repos, which were built with [Flatter](https://github.com/andyholmes/flatter).

### Moved

- `com.visualstudio.code` is now on FlatPark: [flatpark.org/apps/com.visualstudio.code](https://flatpark.org/apps/com.visualstudio.code/).
- `ai.claude.desktop` is gone. Use `com.anthropic.ClaudeDesktop` on FlatPark instead: [flatpark.org/apps/com.anthropic.ClaudeDesktop](https://flatpark.org/apps/com.anthropic.ClaudeDesktop/).

## Install

Runtimes come from Flathub, and flatpak only resolves them from remotes in the **same installation
scope**. Add both remotes with `--user`, or both system-wide (drop `--user` and use `sudo`), but do not
mix them, or you will get `requires the runtime ... which was not found`.

```bash
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak remote-add --user --if-not-exists flatpaks https://francoism90.github.io/flatpaks/index.flatpakrepo

flatpak install flatpaks org.freedesktop.Sdk.Extension.podman
```

`flatpak update` keeps them current.

### Coming from the old per-app repos

The old remotes were `francoism90-vscode`, `francoism90-claude-desktop` and `francoism90-podman`.
`--force` uninstalls what came from them but keeps your data in `~/.var/app`:

```bash
for remote in francoism90-vscode francoism90-claude-desktop francoism90-podman; do
    flatpak remote-delete --user --force "$remote"
done
```

Then install VS Code and Claude Desktop from FlatPark, and the Podman extension from `flatpaks` as
above. Use the same scope you used originally (drop `--user` for a
system-wide install).

## Build locally

```bash
bin/build org.freedesktop.Sdk.Extension.podman               # build and install for the current user
bin/build org.freedesktop.Sdk.Extension.podman --no-install
```

`bin/build` builds into `build/repo` and then installs with the host's own `flatpak`, instead of
`flatpak-builder --install`. When `flatpak-builder` is the sandboxed `org.flatpak.Builder`, hardened
and atomic distros can fail its nested install with `bwrap: No permissions to create a new namespace`;
installing from a local repo with the host's `flatpak` avoids that.

## Repository layout

```text
src/<app-id>/<app-id>.yml|yaml   manifest, plus everything it references
bin/build                        local build + install
bin/make-site.sh                 assembles the Pages site (used by CI)
bin/create-keys                  one-time GPG key generation
site/index.html                  landing page template
.github/workflows/flatpaks.yml   build, sign, publish
.github/workflows/update-checker.yml   opens PRs when a pinned source has a new release
```

## How CI works

[`flatpaks.yml`](.github/workflows/flatpaks.yml) builds every app with the official
[`flatpak-builder` action](https://github.com/flatpak/flatpak-github-actions), all exporting into the
same OSTree repo. On `main` it then signs the repo summary, assembles the site with `bin/make-site.sh`
and deploys it to GitHub Pages. Pull requests build unsigned and deploy nothing.

[`update-checker.yml`](.github/workflows/update-checker.yml) runs
[flatpak-external-data-checker](https://github.com/flathub/flatpak-external-data-checker) daily
against every manifest and opens a PR when a source has a new release. Merging it
triggers a rebuild.

## Setup (for a fork or a new copy)

1. Generate a signing key with `bin/create-keys "Your Name" "you@example.com"`. Store the printed
   values as the repo secrets `GPG_PRIVATE_KEY` and (only if the key has a passphrase)
   `GPG_PASSPHRASE`, then delete `private.key` and `flatpak-keyring/`.
2. Settings → Pages → Source: **GitHub Actions**.
3. Settings → Actions → General → allow **GitHub Actions to create and approve pull requests**
   (needed by the update checker).

## Adding an app

1. Add `src/<app-id>/<app-id>.yml` (or `.yaml`) with everything the manifest references next to it.
2. Add a build step for it in `flatpaks.yml`, copying an existing one and keeping `repo-dir: repo`.
3. Give its sources `x-checker-data` so the update checker can track them.
4. Optionally list it in `site/index.html`.

## License

MIT for the packaging metadata in this repository; see [LICENSE](LICENSE).
