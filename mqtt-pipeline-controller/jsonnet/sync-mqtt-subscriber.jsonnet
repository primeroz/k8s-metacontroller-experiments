local telegraf = import './lib/telegraf.libsonnet';
local telegrafConf = import './lib/telegrafConfToml.libsonnet';
local config = import 'config.libsonnet';
local k = import 'vendor/github.com/jsonnet-libs/k8s-libsonnet/1.26/main.libsonnet';

local cm = k.core.v1.configMap;
local sec = k.core.v1.secret;
local c = k.core.v1.container;
local d = k.apps.v1.deployment;
local envFrom = k.core.v1.envFromSource;

local process = function(request) {
  local parent = request.parent,

  local secret = sec.new(
                   'mqtt-subscriber-' + parent.spec.instanceName,
                   {
                     HOST: std.base64(parent.spec.mqttHost),
                     PORT: std.base64(parent.spec.mqttPort),
                   }
                 ) +
                 sec.metadata.withLabelsMixin({
                   app: 'mqtt-subscriber',
                   instance: parent.spec.instanceName,
                 }),

  local conf = telegrafConf {
                 name:: parent.spec.instanceName,
               } +
               telegrafConf.withMqttConsumer('tcp://$HOST:$PORT', parent.spec.topics) +
               telegrafConf.withOutputsStdout('json'),

  local t = telegraf {
    _config+:: {
      name: 'mqtt-subscriber-' + parent.spec.instanceName,
      telegrafConfig: conf.rendered,
      secretEnvFrom: secret.metadata.name,
    },
  },

  // Create and return a random secret
  //resyncAfterSeconds: if (std.objectHas(childrenSecret, 'metadata') && std.objectHas(childrenSecret.metadata, 'resourceVersion')) then 30.0 else 1800.0,
  resyncAfterSeconds: 30.0,
  status: {
    observedGeneration: std.get(parent.metadata, 'generation', 0),
    ready: 'false',
  },
  children: [
    secret,
    t.objects.configMap,
    t.objects.deployment,
  ],
};

//Top Level Function
function(request)
  local response = process(request);
  // pass with --ext-str TRACE=true|false
  local trace = std.extVar('TRACE');

  if (trace == 'true' || trace == 'TRUE') then
    std.trace('request: ' + std.manifestJsonEx(request, '  ') + '\n\nresponse: ' + std.manifestJsonEx(response, '  '), response)
  else
    response
