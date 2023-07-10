local k = import 'vendor/github.com/jsonnet-libs/k8s-libsonnet/1.26/main.libsonnet';

local sec = k.core.v1.secret;
local c = k.core.v1.container;
local d = k.apps.v1.deployment;
local envFrom = k.core.v1.envFromSource;

function(request) {
  local parent = request.parent,
  local childrenSecret = std.get(request.children, 'Secret.v1'),

  local secret = sec.new(
    'mqtt-publisher-' + parent.spec.topicName,
    {
      HOST: 'test.mosquitto.net',
      PORT: '1883',
      TOPIC: parent.spec.topicName,
    }
  ),

  local container = c.new('controller', std.format('%s:%s', ['primeroz/mqtt-publisher', '0.1'])) +
                    c.withEnvFrom(envFrom.secretRef.withName(secret.metadata.name)),
  //c.resources.withRequests($._config.EventExporter.resources.requests) +
  //c.resources.withLimits($._config.EventExporter.resources.limits) +
  //c.withCommand(['--conf', '/data/config.yaml']),

  local deployment = d.new('mqtt-publisher-' + parent.spec.topicName, 1, [container], { app: 'mqtt-publisher', topic: parent.spec.topicName }) +
                     d.spec.template.metadata.withLabelsMixin({ app: 'mqtt-publisher', topic: parent.spec.topicName }),
  //d.metadata.withLabelsMixin($._config.EventExporter.labels) +
  //d.metadata.withLabelsMixin(configLib.utils.RenderRequiredLabels($._config.EventExporter.name, $._config.EventExporter.version)) +
  //d.metadata.withAnnotationsMixin($._config.EventExporter.annotations + configLib.metadata.Annotations($._config, 'allow_image_pull_secret') + configLib.metadata.Annotations($._config, 'allow_missing_liveness_\nprobe') + configLib.metadata.Annotations($._config, 'allow_missing_readiness_probe')) +
  //d.spec.template.metadata.withLabelsMixin(configLib.utils.RenderRequiredLabels($._config.EventExporter.name, $._config.EventExporter.version)) +
  //d.spec.strategy.withType('Recreate') +
  //d.spec.template.spec.withServiceAccountName($.serviceAccount.metadata.name) +
  //d.spec.template.spec.withPriorityClassName($._config.EventExporter.priorityClassName) +
  //d.configMapVolumeMount($.configMap, '/data'),


  // Create and return a random secret
  resyncAfterSeconds: if (std.objectHas(childrenSecret, 'metadata') && std.objectHas(childrenSecret.metadata, 'resourceVersion')) then 30.0 else 1800.0,
  status: {
    observedGeneration: std.get(parent.metadata, 'generation', 0),
    ready: if (std.objectHas(childrenSecret, 'metadata') && std.objectHas(childrenSecret.metadata, 'resourceVersion')) then 'true' else 'false',
  },
  children: [
    secret,
    deployment,
  ],
}
