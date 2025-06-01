#!/bin/bash
set -e

SPEC="$1"

NAME=$(yq '.name' "$SPEC")
REPO=$(yq '.repo' "$SPEC")
MAJOR=$(yq '.major // ""' "$SPEC")
DESCRIPTION=$(yq '.description' "$SPEC")
VERSION=$(bash scripts/fetch-latest-version.sh "$REPO" "$MAJOR")

ARCHS=$(yq '.architectures | keys | .[]' "$SPEC")

for ARCH in $ARCHS; do
  RAW_URL=$(yq ".architectures.\"$ARCH\".url" "$SPEC")
  BIN_PATH=$(yq ".architectures.\"$ARCH\".bin_path" "$SPEC")

  URL=$(echo "$RAW_URL" | sed "s/\${VERSION}/$VERSION/g")

  WORKDIR=$(mktemp -d)
  mkdir -p "$WORKDIR/$NAME-$VERSION/usr/bin"
  mkdir -p "$WORKDIR/$NAME-$VERSION/DEBIAN"

  curl -sL "$URL" -o "$WORKDIR/archive"
  mkdir "$WORKDIR/extracted"
  tar -xf "$WORKDIR/archive" -C "$WORKDIR/extracted"

  cp "$WORKDIR/extracted/$BIN_PATH" "$WORKDIR/$NAME-$VERSION/usr/bin/$NAME"
  chmod +x "$WORKDIR/$NAME-$VERSION/usr/bin/$NAME"

  cat > "$WORKDIR/$NAME-$VERSION/DEBIAN/control" <<EOF
Package: $NAME
Version: $VERSION
Section: utils
Priority: optional
Architecture: $ARCH
Maintainer: Fabio Mora <code@fabiomora.dev>
Description: $DESCRIPTION
EOF

  mkdir -p "pool/$NAME"
  dpkg-deb \
    --build "$WORKDIR/$NAME-$VERSION" \
    "pool/$NAME/${NAME}_${VERSION}_${ARCH}.deb"
done
