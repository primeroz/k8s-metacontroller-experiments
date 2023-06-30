function(request) {
  local secret = request.object,
  local name = secret.spec.name
  local length = secret.spec.length

  // Create and return a random secret
  attachments: [
    {
      apiVersion: "v1",
      kind: "Secret",
      metadata: {
        name: name
        labels: {app: "test"}
      },
      data: {
        value: std.base64("test")
      }
    }
  ]
}
