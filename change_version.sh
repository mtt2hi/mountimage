#!/bin/sh

FILE=$1

PKGVERSION=$(dpkg-parsechangelog -SVersion)
PKGVERSION=${PKGVERSION%.p*}

TS=$(dpkg-parsechangelog -S Timestamp)
BASEFILE=$(basename "$FILE")

if test "$BASEFILE" = "mountimage"; then
  YEAR=$(date +"%Y" -d @$TS)
  sed -i 's/VERSION=[0-9\.]*/VERSION='${PKGVERSION}'/' "$FILE"	
  sed -i 's/VERSIONDATE=[0-9]*/VERSIONDATE='${YEAR}'/' "$FILE"	
  sed -i 's/# Copyright (c) [0-9]*/# Copyright (c) '${YEAR}'/' "$FILE"
fi
if test "$BASEFILE" = "mountimage.1.md"; then
  DATES=$(date +"%B %d,%Y" -d @$TS)
  sed -i 's/footer: mountimage  [0-9\.]*/footer: mountimage  '${PKGVERSION}'/' "$FILE"	
  sed -i 's/date: .*/date: '"${DATES}"'/' "$FILE"
fi
