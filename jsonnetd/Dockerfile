FROM golang:1.20 AS build
ARG version=dev

COPY . /go/src/jsonnetd/
WORKDIR /go/src/jsonnetd/
RUN go mod vendor && go install -ldflags="-X 'main.Version=$version'"

FROM debian:bookworm-slim
COPY --from=build /go/bin/jsonnetd /jsonnetd/
WORKDIR /jsonnetd
ENTRYPOINT ["/jsonnetd/jsonnetd"]
EXPOSE 8080