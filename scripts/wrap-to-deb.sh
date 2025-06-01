#!/bin/bash
set -e

# Ensure APT_GITHUB_TOKEN is set
if [ -z "$APT_GITHUB_TOKEN" ]; then
  echo "Error: No APT_GITHUB_TOKEN nor GH_PAT is set. Please set one in your Codespaces environment."
  exit 1
fi

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
  SELECTOR=$(yq ".architectures.\"$ARCH\".selector" "$SPEC")

  if [[ -z "$SELECTOR" || "$SELECTOR" = "null" ]]; then
    SELECTOR=$ARCH
  fi

  URL=$(echo "$RAW_URL" | sed "s/\${VERSION}/$VERSION/g")

  WORKDIR=$(mktemp -d)
  mkdir -p "$WORKDIR/$NAME-$VERSION/usr/bin"
  mkdir -p "$WORKDIR/$NAME-$VERSION/DEBIAN"

  POSTINST=$(yq '.postinst // ""' "$SPEC")
  if [ -n "$POSTINST" ]; then
    echo "$POSTINST" > "$WORKDIR/$NAME-$VERSION/DEBIAN/postinst"
    chmod +x "$WORKDIR/$NAME-$VERSION/DEBIAN/postinst"
  fi

  # Fetch latest release information
  response_file=releases-latest.json
  curl -sH "Authorization: Bearer ${APT_GITHUB_TOKEN}" https://api.github.com/repos/$REPO/releases > ${response_file}

  asset_url=$(jq -r --arg os "Linux" --arg arch "$SELECTOR" '
      .[]
      | select (.tag_name == "v'$VERSION'")
      | .assets[]
      | select(.name | test($os; "i") and test($arch; "i"))
      | .url
  ' < ${response_file})
  asset_name=$(jq -r --arg os "Linux" --arg arch "$SELECTOR" '
      .[]
      | select (.tag_name == "v'$VERSION'")
      | .assets[]
      | select(.name | test($os; "i") and test($arch; "i"))
      | .name
  ' < ${response_file})

  if [ -z "$asset_name" ] || [ -z "$asset_url" ]; then
      echo "Error: Could not find a compatible release asset for Linux $SELECTOR."
      exit 1
  fi

  rm $response_file

  curl -sL \
       -H "Accept: application/octet-stream" \
       -H "Authorization: Bearer ${APT_GITHUB_TOKEN}" \
       -o "$WORKDIR/archive" \
       "${asset_url}"

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
