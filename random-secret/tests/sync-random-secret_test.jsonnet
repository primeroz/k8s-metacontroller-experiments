local test = import '../manifests/sync-random-secret.jsonnet';

local data = {
  parent: {
    apiVersion: 'primeroz.xyz/v1',
    kind: 'RandomSecret',
    metadata: {
      name: 'test1',
    },
    spec: {
      length: 10,
      secretName: 'secret1',
    },
  },
};


test(data)
