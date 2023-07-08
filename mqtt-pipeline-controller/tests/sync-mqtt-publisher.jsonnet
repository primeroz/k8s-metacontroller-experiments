local test = import '../jsonnet/sync-mqtt-publisher.jsonnet';

local data = {
  parent: {
    apiVersion: 'primeroz.xyz/v1',
    kind: 'MqttPublisher',
    metadata: {
      name: 'test1',
    },
    spec: {
      topicName: 'test1',
    },
  },
  children: {
    'Secret.v1': {},
  },
};


test(data)
