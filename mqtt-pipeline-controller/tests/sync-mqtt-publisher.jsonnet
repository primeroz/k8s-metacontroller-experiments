{
  parent: {
    apiVersion: 'primeroz.xyz/v1',
    kind: 'MqttPublisher',
    metadata: {
      name: 'test1',
    },
    spec: {
      instanceName: 'test1',
      topicName: 'test1',
      mqttHost: 'test.mosquitto.org',
      mqttPort: '1883',
    },
  },
  children: {
    'Secret.v1': {},
  },
}
