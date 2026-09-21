#!/usr/bin/env bash
# make-site.sh — assemble the static site that is published to GitHub Pages.
#
# Usage: bin/make-site.sh <repo-dir> <out-dir> <gpg-fingerprint>
#
#   <repo-dir>          OSTree repo produced by flatpak-builder, after
#                       `flatpak build-update-repo --gpg-sign` has signed it
#   <out-dir>           created from scratch; receives
#                         repo/               the repo itself
#                         index.flatpakrepo   what `flatpak remote-add` consumes
#                         index.html          rendered from site/index.html
#   <gpg-fingerprint>   key whose public half is embedded in index.flatpakrepo;
#                       it must be in the current GPG keyring
#
# Environment (optional; the defaults are derived from GITHUB_REPOSITORY):
#   SITE_URL     public base URL, no trailing slash  (https://<owner>.github.io/<name>)
#   SITE_TITLE   name shown when the remote is added (<owner> Flatpaks)
#   HOMEPAGE     link shown in the remote's metadata (https://github.com/<owner>/<name>)

set -euo pipefail

if [[ $# -ne 3 ]]; then
    sed -n '2,/^$/{s/^# \{0,1\}//;p}' "$0" >&2
    exit 2
fi

REPO_DIR="$1"
OUT_DIR="$2"
FINGERPRINT="$3"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ -n "${GITHUB_REPOSITORY:-}" ]]; then
    OWNER="${GITHUB_REPOSITORY%%/*}"
    NAME="${GITHUB_REPOSITORY#*/}"
    SITE_URL="${SITE_URL:-https://${OWNER}.github.io/${NAME}}"
    SITE_TITLE="${SITE_TITLE:-${OWNER} Flatpaks}"
    HOMEPAGE="${HOMEPAGE:-https://github.com/${GITHUB_REPOSITORY}}"
fi
: "${SITE_URL:?set SITE_URL or GITHUB_REPOSITORY}"
: "${SITE_TITLE:?set SITE_TITLE or GITHUB_REPOSITORY}"
: "${HOMEPAGE:?set HOMEPAGE or GITHUB_REPOSITORY}"
SITE_URL="${SITE_URL%/}"

[[ -f "$REPO_DIR/summary" ]] || {
    echo "make-site: $REPO_DIR has no summary; run 'flatpak build-update-repo' first" >&2
    exit 1
}
[[ -f "$REPO_DIR/summary.sig" ]] || {
    echo "make-site: $REPO_DIR/summary.sig is missing; sign it with 'flatpak build-update-repo --gpg-sign'" >&2
    exit 1
}

# Clients verify commits and the summary against this key, so an empty one would
# publish a remote that installs nothing.
GPG_KEY="$(gpg --export "$FINGERPRINT" | base64 -w0)"
[[ -n "$GPG_KEY" ]] || {
    echo "make-site: no public key for '$FINGERPRINT' in the GPG keyring" >&2
    exit 1
}

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"
cp -a "$REPO_DIR" "$OUT_DIR/repo"

cat > "$OUT_DIR/index.flatpakrepo" <<EOF
[Flatpak Repo]
Title=${SITE_TITLE}
Url=${SITE_URL}/repo
Homepage=${HOMEPAGE}
Comment=Unofficial Flatpak builds of proprietary apps and SDK extensions that Flathub does not carry
GPGKey=${GPG_KEY}
EOF

# The page is a template so the URL never has to be edited by hand.
esc() { printf '%s' "$1" | sed -e 's/[\\&|]/\\&/g'; }
sed -e "s|@SITE_URL@|$(esc "$SITE_URL")|g" \
    -e "s|@SITE_TITLE@|$(esc "$SITE_TITLE")|g" \
    -e "s|@HOMEPAGE@|$(esc "$HOMEPAGE")|g" \
    "$ROOT/site/index.html" > "$OUT_DIR/index.html"

echo "Site written to $OUT_DIR ($(du -sh "$OUT_DIR" | cut -f1))"
