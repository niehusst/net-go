#!/usr/bin/env sh

set -e

mainjs="frontend/static/js/elm.js"
workerjs="frontend/static/js/scoring-worker.js"

if ! [ -e "$mainjs" ] || ! [ -e "$workerjs" ]; then
    echo "Transpiled Elm JS scripts don't exist. Please make elm first!"
    exit 1
fi

npx uglifyjs "$mainjs" --compress "pure_funcs=[F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9],pure_getters,keep_fargs=false,unsafe_comps,unsafe" | npx uglifyjs --mangle --output "$mainjs"
npx uglifyjs "$workerjs" --compress "pure_funcs=[F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9],pure_getters,keep_fargs=false,unsafe_comps,unsafe" | npx uglifyjs --mangle --output "$workerjs"
