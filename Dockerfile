FROM golang:alpine as builder
WORKDIR /root

### download deps ###
# (done separately first to optimize docker layer caching)

# download elm transpiler deps
COPY package.json package-lock.json .
RUN npm ci

# download go deps
COPY go.mod go.sum .
RUN go mod download

### build client and server ###

COPY . .

RUN npm run make-elm-prod

# compile go app to file called 'run'
ENV GIN_MODE=release
RUN npm run make-go

### setup server configs ###

RUN apk --no-cache add ca-certificates

EXPOSE 8080
CMD ["./run"]
