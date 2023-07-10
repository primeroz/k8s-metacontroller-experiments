local test = import '../jsonnet/sync-mqtt-subscriber.jsonnet';

local data = {
  parent: {
    apiVersion: 'primeroz.xyz/v1',
    kind: 'MqttSubscriber',
    metadata: {
      name: 'test1',
    },
    spec: {
      topics: ['test1'],
      instanceName: 'test1',
    },
  },
  children: {
    'Configmap.v1': {},
    'Deployment.apps/v1': {},
  },
};

local controllerConfig = {
  version: 'v0.99999',
};


test(data, controllerConfig)
