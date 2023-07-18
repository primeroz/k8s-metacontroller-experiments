FROM golang:1.20 AS build
RUN go install -a github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@v0.5.1
RUN go install -a github.com/kubecfg/kubecfg@v0.31.2

COPY jsonnet/ /hooks
WORKDIR /hooks
RUN jb install

FROM debian:bookworm-slim
COPY --from=build /go/bin/kubecfg /kubecfg
COPY --from=build /hooks /hooks/

WORKDIR /hooks

ENTRYPOINT ["/kubecfg"]
CMD ["--alpha", "httpd", "sync-mqtt-subscriber.jsonnet", "sync-mqtt-publisher.jsonnet"]
EXPOSE 8080