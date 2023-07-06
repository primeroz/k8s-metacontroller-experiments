local k = import 'vendor/github.com/jsonnet-libs/k8s-libsonnet/1.26/main.libsonnet';

local secret = k.core.v1.secret;

function(request) {
  local parent = request.parent,
  local childrenSecret = std.get(request.children, 'Secret.v1'),

  // Create and return a random secret
  resyncAfterSeconds: if std.objectHas(children.metadata, 'resourceVersion') then 30.0 else 1800.0,
  status: {
    observedGeneration: parent.metadata.resourceVersion,
    ready: if std.objectHas(children.metadata, 'resourceVersion') then 'true' else 'false',
  },
  children: [
    secret.new(
      parent.spec.secretName,
      {
        value: std.base64('test'),
      }
    ),
  ],
}
