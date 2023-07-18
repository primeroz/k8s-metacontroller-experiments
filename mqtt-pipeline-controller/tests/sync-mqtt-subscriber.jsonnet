{
  parent: {
    apiVersion: 'primeroz.xyz/v1',
    kind: 'MqttSubscriber',
    metadata: {
      name: 'test1',
    },
    spec: {
      topics: ['test1/#'],
      instanceName: 'test1',
      mqttHost: 'test.mosquitto.org',
      mqttPort: '1883',
    },
  },
  children: {
    'Secret.v1': {},
    'Configmap.v1': {},
    'Deployment.apps/v1': {},
  },
}
