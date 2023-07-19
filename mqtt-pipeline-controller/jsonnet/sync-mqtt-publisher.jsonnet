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
  local children = request.children,

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
               telegrafConf.withMockIotInput('iot1') +
               telegrafConf.withMockIotInput('iot2') +
               telegrafConf.withMockIotInput('iot3') +
               telegrafConf.withMqttPublisher('tcp://$HOST:$PORT', '$TOPIC/{{ .Tag "iotName" }}/{{ .PluginName }}'),

  local t = telegraf {
    _config+:: {
      name: 'mqtt-publisher-' + parent.spec.instanceName,
      telegrafConfig: conf.rendered,
      secretEnvFrom: secret.metadata.name,
    },
  },

  local deploymentStatus = if std.objectHas(children['Deployment.apps/v1'], 'mqtt-publisher-' + parent.spec.instanceName) then
    children['Deployment.apps/v1']['mqtt-publisher-' + parent.spec.instanceName].status
  else
    {},

  local isGenerationReady = if (std.length(deploymentStatus) > 0 && std.objectHas(deploymentStatus, 'updatedReplicas') && deploymentStatus.updatedReplicas == deploymentStatus.replicas) then
    true
  else
    false,

  resyncAfterSeconds: if (std.objectHas(parent, 'status') && std.objectHas(parent.status, 'ready') && parent.status.ready == 'true') then 300.0 else 30.0,
  status: {
    observedGeneration: if isGenerationReady then std.get(parent.metadata, 'generation', 0) else (if std.objectHas(parent, 'status') then std.get(parent.status, 'observedGeneration', 0) else 0),
    ready: std.toString(isGenerationReady),
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
