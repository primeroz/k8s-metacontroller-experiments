// Imports
local telegraf = import './lib/telegraf.libsonnet';
local telegrafConf = import './lib/telegrafConfToml.libsonnet';
local kubecfg = import 'lib/kubecfg.libsonnet';
local k = import 'vendor/github.com/jsonnet-libs/k8s-libsonnet/1.26/main.libsonnet';

// k8s objects
local sec = k.core.v1.secret;
local c = k.core.v1.container;
local d = k.apps.v1.deployment;
local envFrom = k.core.v1.envFromSource;

//Code
local process = function(request) {
  local parent = request.parent,

  local secret = sec.new(
                   'mqtt-publisher-' + parent.spec.instanceName,
                   {
                     HOST: std.base64(parent.spec.mqttHost),
                     PORT: std.base64(parent.spec.mqttPort),
                     TOPIC: std.base64(parent.spec.topicName),
                   }
                 ) +
                 sec.metadata.withLabelsMixin({
                   app: 'mqtt-publisher',
                   instance: parent.spec.instanceName,
                 }),

  local conf = telegrafConf {
                 name:: parent.spec.instanceName,
               } +
               telegrafConf.withMockInput() +
               telegrafConf.withMqttPublisher('tcp://$HOST:$PORT', '$TOPIC'),

  local t = telegraf {
    _config+:: {
      name: 'mqtt-publisher-' + parent.spec.instanceName,
      telegrafConfig: conf.rendered,
      secretEnvFrom: secret.metadata.name,
    },
  },


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
  //TODO Can i make the tracing conditional ?
  //std.trace('request: ' + std.manifestJsonEx(request, '  ') + '\n\nresponse: ' + std.manifestJsonEx(response, '  '), response)
  response
