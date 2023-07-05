function(request) {
  local secret = request.parent,
  local secretName = secret.spec.secretName,
  local secretLength = secret.spec.length,

  // Create and return a random secret
  attachments: [
    {
      apiVersion: 'v1',
      kind: 'Secret',
      metadata: {
        name: secretName,
        labels: { app: 'test' },
      },
      data: {
        value: std.base64('test'),
      },
    },
  ],
}
