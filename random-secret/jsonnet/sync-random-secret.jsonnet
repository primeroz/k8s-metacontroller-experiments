local k = import 'vendor/github.com/jsonnet-libs/k8s-libsonnet/1.26/main.libsonnet';

local secret = k.core.v1.secret;

function(request) {
  local parent = request.parent,
  local _children = std.get(request.children, 'Secret.v1'),
  local children = if _children == {} then { metadata: {} } else _children[parent.spec.secretName],

  // Create and return a random secret
  resyncAfterSeconds: if std.objectHas(children.metadata, 'resourceVersion') then 30.0 else 1800.0,
  status: {
    observedGeneration: std.get(children.metadata, 'resourceVersion', '0'),
    ready: if std.objectHas(children.metadata, 'resourceVersion') then 'true' else 'false',
  },
  children: [
    secret.new(
      parent.spec.secretName,
      {
        value: std.base64('test'),
      }
    ),
    //{
    //  apiVersion: 'v1',
    //  kind: 'Secret',
    //  metadata: {
    //    name: parent.spec.secretName,
    //    labels: { app: 'test' },
    //  },
    //  data: {
    //    value: std.base64('test'),
    //  },
    //},
  ],
}
