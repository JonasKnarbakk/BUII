#!/usr/bin/env bash

cd ..
zip_filename=~/Downloads/BravosUIImprovements-$(date '+%Y%m%d%H%M').zip
zip -r ${zip_filename} BravosUIImprovements/ -x '*.editorconfig' '*.luarc.json' '*package.sh' '*.git*' \
    && echo "created ${zip_filename}" \
    || echo "failed packaging"
