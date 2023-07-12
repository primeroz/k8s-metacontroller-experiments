{
  // Generate TOML configuration for telegraf

  // common Settings
  name:: error 'name for this tag instance must be specified',

  // Agent Settings
  interval:: '30s',
  flush_interval:: '10s',
  flush_jitter:: '5s',
  collection_jitter:: '2s',
  metric_batch_size:: 1000,
  metric_buffer_limit:: 25000,

  assert std.isNumber($.metric_batch_size) : 'metric_batch_size must be an int',
  assert std.isNumber($.metric_buffer_limit) : 'metric_batch_size must be an int',

  // global tags
  globalTags+:: {
    hostname: '$HOSTNAME',
    nodename: '$NODENAME',
  },
  assert std.isObject($.globalTags) : 'globalTags must be a map',

  conf:: {
    agent+: {
      interval: $.interval,
      flush_interval: $.flush_interval,
      flush_jitter: $.flush_jitter,
      [if $.collection_jitter != null then 'collection_jitter']: $.collection_jitter,
      metric_batch_size: $.metric_batch_size,
      metric_buffer_limit: $.metric_buffer_limit,
    },
    [if std.length(std.objectFields($.globalTags)) > 0 then 'global_tags']+: {
      [key]: $.globalTags[key]
      for key in std.objectFields($.globalTags)
    },

    inputs+: {
      internal+: {
        tags+: [
          {
            job: std.format('telegraf/%s', $.name),
          },
        ],
      },
    },
  },

  withMockInput():: {
    conf+:: {
      inputs+: {
        mock+: [
          {
            alias: 'indoor_thermostat',
            tags: {
              location: 'mock_house',
              device_id: 'dht_001',
            },
            field: [
              {
                name: 'temperature',
                type: 'float',
                min: 0,
                max: 50,
                distribution: 'sine',
              },
              {
                name: 'humidity',
                type: 'float',
                min: 0.1,
                max: 0.99,
                distribution: 'random',
              },
            ],
          },
        ],
      },
    },
  },

  withMqttConsumer(host, topics):: {

    assert std.isArray(topics) : 'topics must be an array',
    assert std.length(topics) > 0 : 'topics must be an array > 0',

    local this = self,

    // local all_tags = { job: 'telegraf/%s' % $.name },

    conf+:: {
      inputs+: {
        mqtt_consumer+: [
          std.prune({
            servers: [host],
            topics: topics,
            qos: 0,
          }),
        ],
      },
    },
  },

  withOutputsStdout(format):: {

    conf+:: {
      outputs+: {
        file+: [
          {
            files: ['stdout'],
            data_format: format,
          },
        ],
      },
    },
  },

  rendered:: std.manifestTomlEx(std.prune($.conf), ' '),

}
