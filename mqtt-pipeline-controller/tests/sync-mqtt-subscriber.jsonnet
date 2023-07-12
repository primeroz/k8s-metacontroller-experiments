{
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
}
