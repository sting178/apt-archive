#!/bin/bash
set -e

DIST="stable"
COMP="main"

ARCHS=$(find pool/ -type f -name '*.deb' | xargs -n1 dpkg-deb -f | \
    grep Architecture | awk '{print $2}' | sort -u)

for ARCH in $ARCHS; do
  OUTDIR="dists/$DIST/$COMP/binary-$ARCH"
  mkdir -p "$OUTDIR"
  dpkg-scanpackages --arch "$ARCH" pool /dev/null > "$OUTDIR/Packages"
  gzip -k -f "$OUTDIR/Packages"
done

apt-ftparchive generate conf/apt-ftparchive.conf
apt-ftparchive -c=conf/release.conf release dists/$DIST > dists/$DIST/Release

gpg --default-key "$GPG_KEY_ID" \
    --digest-algo SHA256 \
    -abs \
    -o dists/$DIST/Release.gpg dists/$DIST/Release
gpg --default-key "$GPG_KEY_ID" \
    --digest-algo SHA256 \
    --clearsign \
    -o dists/$DIST/InRelease dists/$DIST/Release

gpg --export "$GPG_KEY_ID" > public.gpg

gpg --verify dists/$DIST/Release.gpg dists/$DIST/Release
