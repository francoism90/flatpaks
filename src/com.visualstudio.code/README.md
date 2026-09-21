# Visual Studio Code Flatpak<!-- omit in toc -->

🚨 Warning: This is an unofficial Flatpak build of Visual Studio Code, generated from the official Microsoft-built [.deb packages](https://code.visualstudio.com/download). Use it at your own risk, it is recommended to build it yourself.

## Table of Contents<!-- omit in toc -->

- [Install](#install)
- [Usage](#usage)
  - [Execute commands in the host system](#execute-commands-in-the-host-system)
  - [Use host shell in the integrated terminal](#use-host-shell-in-the-integrated-terminal)
  - [Support for language extension](#support-for-language-extension)

## Install

Add the shared remote once (see the [root README](../../README.md#install) for the scope caveat and the
migration from the old per-app remote), then:

```bash
flatpak install flatpaks com.visualstudio.code
flatpak update
```

To build it yourself instead of using the prebuilt, signed remote, run `bin/build com.visualstudio.code` from the
repository root (see [Build locally](../../README.md#build-locally)).

## Usage

Most functionality works out of the box, though please note that flatpak runs in an isolated environment and some work is necessary to enable those features.

### Execute commands in the host system

To execute commands on the host system, run inside the sandbox:

`flatpak-spawn --host <COMMAND>`

or

`host-spawn <COMMAND>`

- Most users seem to report a better experience with `host-spawn`

### Use host shell in the integrated terminal

Another option to execute commands is to use your host shell in the integrated terminal instead of the sandbox one.

For that go to `File -> Preferences -> Settings` and find `Features > Terminal > Integrated > Profiles`, then click on `Edit in settings.json` (The important thing here is to open settings.json)

And make sure that you have the following lines there:

**Using `flatpak-spawn`:**

```json
{
  "terminal.integrated.defaultProfile.linux": "bash",
  "terminal.integrated.profiles.linux": {
    "bash": {
      "path": "/usr/bin/flatpak-spawn",
      "args": ["--host", "--env=TERM=xterm-256color", "bash"],
      "icon": "terminal-bash",
      "overrideName": true
    }
  }
}
```

**Using `host-spawn`:**

```json
{
  "terminal.integrated.defaultProfile.linux": "bash",
  "terminal.integrated.profiles.linux": {
    "bash": {
      "path": "/app/bin/host-spawn",
      "args": ["bash"],
      "icon": "terminal-bash",
      "overrideName": true
    }
  }
}
```

- You can change **bash** to any terminal you are using: zsh, fish, sh.
- `overrideName` allows for the 'name' (or whatever you set it to) of the shell you're using to appear (e.g. normally zsh, fish, sh).

### Support for language extension

Some Visual Studio extensions depend on packages that might exist on your host, but they are not accessible through Flatpak. Like support for programming languages: gcc, python, etc.

**See available SDK:**

```bash
flatpak run --command=sh com.visualstudio.code
ls /usr/bin # shared runtime
ls /app/bin # bundled with this flatpak
```

**Getting support for additional languages, you have to install SDK extensions, e.g.:**

```bash
flatpak install flathub org.freedesktop.Sdk.Extension.dotnet
flatpak install flathub org.freedesktop.Sdk.Extension.golang
FLATPAK_ENABLE_SDK_EXT=dotnet,golang flatpak run com.visualstudio.code
```

**Container support (Podman):**

To use Podman as a container runtime inside the sandbox (e.g. for Dev Containers), install the
`org.freedesktop.Sdk.Extension.podman` SDK extension from the same `flatpaks` remote (it is not on
Flathub, see its [README](../org.freedesktop.Sdk.Extension.podman/README.md) for why) and enable it the
same way:

```bash
flatpak install flatpaks org.freedesktop.Sdk.Extension.podman
FLATPAK_ENABLE_SDK_EXT=podman flatpak run com.visualstudio.code
```

**Finding other SDK:**

`flatpak search <TEXT>`
