{
  // Generate TOML configuration for telegraf

  // common Settings
  name:: error 'name for this tag instance must be specified',

  // Agent Settings
  interval:: '10s',
  flush_interval:: '5s',
  flush_jitter:: '5s',
  collection_jitter:: '2s',
  metric_batch_size:: 1000,
  metric_buffer_limit:: 10000,

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

  withMockIotInput(metricName):: {
    conf+:: {
      inputs+: {
        mock+: [
          {
            alias: 'mock_' + metricName,
            metric_name: metricName,
            tags: {
              location: 'mock_house',
              device_id: 'dht_001',
              iotName: metricName,
            },
            stock: [
              {
                name: 'temperature',
                price: 26.01,
                volatility: 0.1,
              },
              {
                name: 'humidity',
                price: 65.01,
                volatility: 0.1,
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
            data_format: 'json',
          }),
        ],
      },
    },
  },

  withMqttPublisher(host, topic):: {

    local this = self,

    conf+:: {
      outputs+: {
        mqtt+: [
          std.prune({
            servers: [host],
            topic: topic,
            qos: 0,
            keep_alive: 60,
            data_format: 'json',
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
