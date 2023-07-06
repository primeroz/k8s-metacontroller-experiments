ARG jsonnetdTag

FROM golang:1.20 AS build
RUN go install -a github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@v0.5.1

COPY jsonnet/ /hooks
WORKDIR /hooks
RUN jb install

FROM primeroz/jsonnetd:$jsonnetdTag AS jsonnetd

FROM debian:bookworm-slim
COPY --from=jsonnetd /jsonnetd/jsonnetd /hooks/
WORKDIR /hooks
ENTRYPOINT ["/hooks/jsonnetd"]
EXPOSE 8080