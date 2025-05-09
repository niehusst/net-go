#!/usr/bin/env sh

set -e

js="$1"

if [ -z "$js" ] || ! [ -e "$js" ]; then
    echo "Transpiled Elm JS script doesn't exist. Please make elm first!"
    exit 1
fi

npx uglifyjs "$js" --compress "pure_funcs=[F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9],pure_getters,keep_fargs=false,unsafe_comps,unsafe" | npx uglifyjs --mangle --output "$js"
echo "Minified $js in-place"

