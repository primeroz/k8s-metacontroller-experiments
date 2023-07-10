local k = import '../vendor/github.com/jsonnet-libs/k8s-libsonnet/1.26/main.libsonnet';

{
  local c = k.core.v1.container,
  local d = k.apps.v1.deployment,
  local sa = k.core.v1.serviceAccount,
  local cm = k.core.v1.configMap,

  _config::
    {
      name:: error 'name is required',
      image:: 'docker.io/library/telegraf:1.25.3',
      hotReload:: true,
      secretEnvFrom:: null,
      configMapEnvFrom:: null,
      containerEnvMap:: null,  // Pass an object to map as environment variables inline.
      telegrafConfigMapName:: null,
      telegrafConfig:: null,
      resources+:: {
        requests+: { cpu: '10m', memory: '10Mi' },
        limits+: { cpu: '100m', memory: '100Mi' },
      },
      labels: {
        'app.kubernetes.io/name': $._config.name,
        'app.kubernetes.io/component': 'telegraf',
      },
      annotations: {},
      imagePullSecrets: [],
    },

  //serviceAccount::
  //  sa.new($._config.name) +
  //  sa.metadata.withNamespace($._config.namespace) +
  //  sa.metadata.withLabelsMixin($._config.labels) +
  //  sa.metadata.withAnnotationsMixin($._config.annotations),

  configMap:: (if $._config.telegrafConfig != null then
                 cm.new(std.format('%s-config', $._config.name), { 'telegraf.conf': $._config.telegrafConfig }) +
                 cm.metadata.withLabelsMixin($._config.labels) +
                 cm.metadata.withAnnotationsMixin($._config.annotations)
               else null),

  container::
    c.new('telegraf', std.format('%s', [$._config.image])) +
    c.resources.withRequests($._config.resources.requests) +
    c.resources.withLimits($._config.resources.limits) +
    c.withCommand(['telegraf']) +
    c.withArgs(['--config', '/etc/telegraf/telegraf.conf']) +
    (if $._config.hotReload then c.withArgsMixin(['--watch-config', 'inotify']) else {}) +
    //(if $._config.inputPlugins != [] && std.isArray($._config.inputPlugins) then c.withArgsMixin(['--input-list', std.join(':', $._config.inputPlugins)]) else {}) +
    //(if $._config.outputPlugins != [] && std.isArray($._config.outputPlugins) then c.withArgsMixin(['--output-list', std.join(':', $._config.outputPlugins)]) else {}) +
    //c.withEnvMixin([k.core.v1.envVar.withName('ENV') + k.core.v1.envVar.withValue($._config.env)]) +
    c.withEnvMixin([k.core.v1.envVar.withName('HOME') + k.core.v1.envVar.withValue('/tmp/')]) +
    c.withEnvMixin([k.core.v1.envVar.withName('NODENAME') + k.core.v1.envVar.valueFrom.fieldRef.withFieldPath('spec.nodeName')]) +
    c.withEnvMixin([k.core.v1.envVar.withName('HOST_IP') + k.core.v1.envVar.valueFrom.fieldRef.withFieldPath('status.hostIP')]) +
    c.withEnvMixin([k.core.v1.envVar.withName('HOSTNAME') + k.core.v1.envVar.valueFrom.fieldRef.withFieldPath('spec.nodeName')]) +
    (if $._config.configMapEnvFrom != null then c.withEnvFromMixin(k.core.v1.envFromSource.configMapRef.withName($._config.configMapKeyRef)) else {}) +
    (if $._config.containerEnvMap != null then c.withEnvMap($._config.containerEnvMap) else {}) +
    (if $._config.secretEnvFrom != null then c.withEnvFromMixin(k.core.v1.envFromSource.secretRef.withName($._config.secretEnvFrom)) else {}) +
    (if $._config.telegrafConfigMapName != null then c.withVolumeMountsMixin({ name: $._config.telegrafConfigMapName, mountPath: '/etc/telegraf' }) else {}) +
    (if $._config.telegrafConfig != null then c.withVolumeMountsMixin({ name: std.format('%s-config', $._config.name), mountPath: '/etc/telegraf' }) else {}) +
    c.securityContext.withRunAsUser(999),

  deployment::
    d.new($._config.name, 1, [$.container], $._config.labels) +
    d.metadata.withLabelsMixin($._config.labels) +
    //d.metadata.withLabelsMixin(configLib.utils.RenderRequiredLabels($._config.labels['app.kubernetes.io/name'])) +
    //d.spec.template.metadata.withLabelsMixin(configLib.utils.RenderRequiredLabels($._config.labels['app.kubernetes.io/name'])) +
    //d.metadata.withAnnotationsMixin($._config.annotations + configLib.metadata.Annotations($._config, 'allow_missing_liveness_probe')) +
    (
      if $._config.hotReload then {} else (
        if $.configMap != null then d.metadata.withAnnotationsMixin({ 'configmap.hash': std.md5($._config.telegrafConfig) })
        else {}
      )
    ) +
    d.spec.strategy.withType('Recreate') +
    //(if $.serviceAccount != null then d.spec.template.spec.withServiceAccountName($.serviceAccount.metadata.name) else {}) +
    //d.spec.template.spec.withPriorityClassName($._config.priorityClassName) +
    //(if $._config.imagePullSecrets != [] then d.spec.template.spec.withImagePullSecrets($._config.imagePullSecrets) else {}) +
    (if $._config.telegrafConfigMapName != null then d.spec.template.spec.withVolumesMixin(k.core.v1.volume.configMap.withName($._config.telegrafConfigMapName) + k.core.v1.volume.withName(std.format('%s-config', $._config.name))) else {}) +
    (if $._config.telegrafConfig != null then d.spec.template.spec.withVolumesMixin(k.core.v1.volume.configMap.withName($.configMap.metadata.name) + k.core.v1.volume.withName(std.format('%s-config', $._config.name))) else {}),

  // map of items of the telegraf resource
  objects:: {
    deployment: $.deployment,
    [if $.configMap != null then 'configMap']: $.configMap,
    //[if $.serviceAccount != null then 'serviceAccount']: $.serviceAccount,
  },
}
