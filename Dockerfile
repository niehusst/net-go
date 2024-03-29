FROM golang:alpine as builder

WORKDIR /go/src/app

# Get Reflex for live reload in dev
#ENV GO111MODULE=on
#RUN go get github.com/cespare/reflex

COPY go.mod .
COPY go.sum .

# download go deps
RUN go mod download

COPY . .

# copy over static site files to serve
COPY frontend/templates/ .
COPY frontend/static/ .

# compile go app to file called 'run'
RUN go build -o ./run .

#FROM alpine:latest
RUN apk --no-cache add ca-certificates
#WORKDIR /root/

#Copy executable from builder
#COPY --from=builder /go/src/app/run .

EXPOSE 8080
CMD ["./run"]
