PHONY: run, elm, format, test

run:
	go run main.go

elm:
	elm make frontend/src/Main.elm --output frontend/static/js/elm.js

format:
	go fmt . ; elm-format frontend/src/ --yes

test:
	go test ; elm-test
