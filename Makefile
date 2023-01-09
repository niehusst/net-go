PHONY: run, elm, format, test, debug-elm

run:
	go run main.go

debug-elm:
	elm-live frontend/src/Main.elm --pushstate -- --debug

elm:
	elm make frontend/src/Main.elm --output frontend/static/js/elm.js

format:
	go fmt . ; elm-format frontend/src/ --yes

test:
	go test ; elm-test
