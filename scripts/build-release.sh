#!/usr/bin/env bash
#
# Build a universal binary (arm64 + x86_64) for GitHub Releases.
#
# Usage:
#   scripts/build-release.sh v0.2.0
#
# To cut a release:
#   scripts/build-release.sh v0.2.0
#   gh release create v0.2.0 release/inverso-v0.2.0-universal.tar.gz release/checksums.txt \
#     --title "Inverso v0.2.0" --notes "..."
#
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:-dev}"
NAME="inverso"
DEPLOY="13.0"
OUT="release"

build_arch() {
  local arch="$1"
  local scratch=".build-$arch"
  local triple="$arch-apple-macosx$DEPLOY"
  rm -rf "$scratch"
  swift build -c release --scratch-path "$scratch" --triple "$triple" >/dev/null
  swift build -c release --scratch-path "$scratch" --triple "$triple" --show-bin-path
}

echo "Building arm64 ..."
ARM64_DIR="$(build_arch arm64)" || exit 1
echo "Building x86_64 ..."
X86_DIR="$(build_arch x86_64)" || exit 1

rm -rf "$OUT"
mkdir -p "$OUT"
echo "Merging universal binary ..."
lipo -create -output "$OUT/$NAME" "$ARM64_DIR/$NAME" "$X86_DIR/$NAME"
codesign --force --sign - "$OUT/$NAME"

echo "Architectures: $(lipo -archs "$OUT/$NAME")"
TARBALL="$NAME-$VERSION-universal.tar.gz"
tar -czf "$OUT/$TARBALL" -C "$OUT" "$NAME"
( cd "$OUT" && shasum -a 256 "$NAME" "$TARBALL" > checksums.txt )

echo "Done. Artifacts in $OUT/:"
ls -1 "$OUT"
echo ""
echo "Checksums:"
cat "$OUT/checksums.txt"
