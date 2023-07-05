function(request) {
  local parent = request.parent,
  local child = std.get(request, 'children', { metadata: {} }),

  // Create and return a random secret
  status: {
    observedGeneration: std.get(child.metadata, 'resourceVersion', '0'),
    ready: if std.objectHas(child.metadata, 'resourceVersion') then 'true' else 'false',
  },
  children: [
    {
      apiVersion: 'v1',
      kind: 'Secret',
      metadata: {
        name: parent.spec.secretName,
        labels: { app: 'test' },
      },
      data: {
        value: std.base64('test'),
      },
    },
  ],
}
