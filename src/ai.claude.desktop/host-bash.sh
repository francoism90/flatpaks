#!/bin/sh
#
# Stand-in for bash that runs on the host through the Flatpak portal.
#
# This is the shell $CLAUDE_CODE_SHELL points at.
#
# The Claude Code agent picks the shell for its Bash tool from
# $CLAUDE_CODE_SHELL, then $SHELL. It takes either only when the path contains
# "bash" or "zsh" and is executable, and otherwise searches /bin, /usr/bin and
# /usr/local/bin. Inside the sandbox every one of those answers is the
# runtime's own bash, which has no node, no python and none of the user's
# project tools. The name of this script is what gets it accepted.
#
# The agent runs it as "<shell> -c -l <script>" to snapshot the user's shell
# setup, then as "<shell> -c [-l] <command>" for every Bash tool call. All
# arguments go through unchanged to bash or zsh on the host.
#
# $CLAUDE_CODE_SHELL also leaks into environments where /app does not exist,
# such as an SSH session the app opens on a remote host. There the path is not
# executable, so the agent ignores it and picks a local shell itself. That is
# why this is not done with $CLAUDE_CODE_SHELL_PREFIX: a prefix that does not
# exist makes every command fail instead.
#
# host-spawn starts the process on the host, so PATH is the real one. It passes
# on only the variables named by --env. It inherits the working directory,
# which is what keeps "cd" correct from one tool call to the next: the agent
# reads the directory back out of a file under TMPDIR, and TMPDIR is a path
# both sides see.
exec /app/bin/host-spawn --no-pty \
    --env=TERM,COLORTERM,COLUMNS,LINES,LANG,LC_ALL,TMPDIR,TMPPREFIX,CLAUDECODE,CLAUDE_CODE_TMPDIR,CLAUDE_CODE_SESSION_ID,CLAUDE_CODE_ENTRYPOINT,CLAUDE_PROJECT_DIR,CLAUDE_CONFIG_DIR,SSH_AUTH_SOCK,GIT_ASKPASS,SSH_ASKPASS,GIT_TERMINAL_PROMPT,GIT_EDITOR \
    /bin/sh -c 'shell=${SHELL:-}
case "$shell" in
    *bash|*zsh) ;;
    *) shell=/bin/bash ;;
esac
[ -x "$shell" ] || shell=/bin/sh
exec "$shell" "$@"' host-bash "$@"
