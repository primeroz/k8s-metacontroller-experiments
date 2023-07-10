local telegraf = import './lib/telegraf.libsonnet';
local telegrafConf = import './lib/telegrafConfToml.libsonnet';
local config = import 'config.libsonnet';
local k = import 'vendor/github.com/jsonnet-libs/k8s-libsonnet/1.26/main.libsonnet';

local cm = k.core.v1.configMap;
local c = k.core.v1.container;
local d = k.apps.v1.deployment;
local envFrom = k.core.v1.envFromSource;

function(request, controllerConfig) {
  local parent = request.parent,

  local conf = telegrafConf {
                 name:: parent.spec.topicName,
               } +
               telegrafConf.withMqttConsumer('tcp://test.mosquitto.org:1883', parent.spec.topicName) +
               telegrafConf.withOutputsStdout('cloudevents'),

  local t = telegraf {
    _config+:: {
      name: 'mqtt-subscriber-' + parent.spec.topicName,
      telegrafConfig: conf.rendered,
    },
  },

  // Create and return a random secret
  //resyncAfterSeconds: if (std.objectHas(childrenSecret, 'metadata') && std.objectHas(childrenSecret.metadata, 'resourceVersion')) then 30.0 else 1800.0,
  resyncAfterSeconds: 30.0,
  status: {
    observedGeneration: std.get(parent.metadata, 'generation', 0),
    ready: false,
  },
  children: [
    t.objects.configMap,
    t.objects.deployment,
  ],
}
