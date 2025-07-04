### build go server binary ###
FROM golang:1.23 AS go-builder
WORKDIR /app

# Install Node.js to use npm scripts in Go stage + gcc for clibs compilation
RUN apt-get update && apt-get install -y nodejs npm

# download go deps
# cgo required for go compilation to work; but this
# requires glibc dylib to exist while building, requiring
# final image to have glibc available
ENV CGO_ENABLED=1
COPY go.mod go.sum .
RUN go mod download

# compile go app to file called 'run'
COPY package.json main.go .
COPY backend/ ./backend/
ENV GIN_MODE=release
RUN npm run make-go


### build elm SPA ###
FROM node:23-alpine AS elm-builder
WORKDIR /app

# download elm binary + deps
RUN apk add --no-cache curl
RUN curl -fsSL https://github.com/elm/compiler/releases/download/0.19.1/binary-for-linux-64-bit.gz \
    | gunzip > /usr/local/bin/elm && chmod +x /usr/local/bin/elm
# RUN npm install -g elm@0.19.1

COPY package.json package-lock.json .
RUN npm ci

COPY tailwind.config.js minify_elm.sh make_elm_prod.sh elm.json .
COPY frontend/ ./frontend/
RUN npm run make-elm-prod
RUN npm run make-css


### setup server configs and copy build artifacts ###
# required to use glibc dylib compiled binary
FROM frolvlad/alpine-glibc:latest
WORKDIR /root
ARG ENV_FILE=".env.prod"

RUN apk add --no-cache ca-certificates

COPY --from=elm-builder /app/frontend/templates/ ./frontend/templates/
COPY --from=elm-builder /app/frontend/static/ ./frontend/static/
COPY --from=go-builder /app/run .
COPY ${ENV_FILE} .env

EXPOSE 8080
CMD ["./run"]
