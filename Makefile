PHONY: start, elm, format

start:
	go run main.go

elm:
	cd frontend; elm make frontend/src/Home.elm --output ./static/js/elm.js; cd ..

format:
	go fmt . ; elm-format frontend/src/ --yes
