#!/usr/bin/env sh

set -e

# change elm const to prod mode
find ./frontend/src -name Constants.elm -exec sed -i 's/isProduction = False/isProduction = True/' {} \;

npm run make-elm-main -- --optimize
npm run make-elm-worker -- --optimize
npm run make-elm-minify

# change elm src back
find ./frontend/src -name Constants.elm -exec sed -i 's/isProduction = True/isProduction = False/' {} \;
