---
layout: post
title: "KafkaSpout重复消费问题"
comments: true
tags: 技术与产品
---

使用https://github.com/nathanmarz/storm-contrib来对接Kafka0.7.2时, 发现kafkaSpout总会进行数据重读, 配置都无问题, 也没报错

进行debug之后, 发现是由于自己写的blot继承于IBolt, 但自己没有在代码中显示的调用collector.ack(); 导致kafkaSpout一直认为emitted的数据有问题, 超时之后进行数据重发

KafkaSpout中关键代码如下:

PartitionManager.java

```
public void commit() {
LOG.info("Committing offset for " + _partition);
long committedTo;
if(_pending.isEmpty()) {
committedTo = _emittedToOffset;
} else {
committedTo = _pending.first();
}
if(committedTo!=_committedTo) {
LOG.info("Writing committed offset to ZK: " + committedTo);

Map<Object, Object> data = (Map<Object,Object>)ImmutableMap.builder()
.put("topology", ImmutableMap.of("id", _topologyInstanceId,
"name", _stormConf.get(Config.TOPOLOGY_NAME)))
.put("offset", committedTo)
.put("partition", _partition.partition)
.put("broker", ImmutableMap.of("host", _partition.host.host,
"port", _partition.host.port))
.put("topic", _spoutConfig.topic).build();
_state.writeJSON(committedPath(), data);

LOG.info("Wrote committed offset to ZK: " + committedTo);
_committedTo = committedTo;
}
LOG.info("Committed offset " + committedTo + " for " + _partition);
}
```

如果Bolt不进行ack, 则加粗代码处的offsetNumber永远相等, 导致一直不进行offset的回写操作

## 解决方案:

1. IBolt中显式调用collector.ack();

2. 使用帮你封装好的BaseBasicBlot, 它会帮你自动调用ack的
