---
layout: post
title: "Kafka UnresolveAddressException"
comments: true
tags: NOSQL
---

最近写的 binlog2kafka storm job 上线在一个新的集群环境中(storm 0.9.0.1, kafka 0.8), storm job 运行时报出如下异常:

```java
java.lang.RuntimeException: java.nio.channels.UnresolvedAddressException
    at storm.kafka.ZkCoordinator.refresh(ZkCoordinator.java:83)
    at storm.kafka.ZkCoordinator.getMyManagedPartitions(ZkCoordinator.java:45)
    at storm.kafka.KafkaSpout.nextTuple(KafkaSpout.java:118)
    at backtype.storm.daemon.executor$eval3848$fn__3849$fn__3864$fn__3893.invoke(executor.clj:562)
    at backtype.storm.util$async_loop$fn__384.invoke(util.clj:433)
    at clojure.lang.AFn.run(AFn.java:24)
    at java.lang.Thread.run(Thread.java:701)
Caused by: java.nio.channels.UnresolvedAddressException
    at sun.nio.ch.Net.checkAddress(Net.java:89)
    at sun.nio.ch.SocketChannelImpl.connect(SocketChannelImpl.java:514)
    at kafka.network.BlockingChannel.connect(BlockingChannel.scala:57)
    at kafka.consumer.SimpleConsumer.connect(SimpleConsumer.scala:44)
    at kafka.consumer.SimpleConsumer.getOrMakeConnection(SimpleConsumer.scala:129)
    at kafka.consumer.SimpleConsumer.kafka$consumer$SimpleConsumer$$sendRequest(SimpleConsumer.scala:69)
    at kafka.consumer.SimpleConsumer.getOffsetsBefore(SimpleConsumer.scala:125)
    at kafka.javaapi.consumer.SimpleConsumer.getOffsetsBefore(SimpleConsumer.scala:80)
    at storm.kafka.KafkaUtils.getOffset(KafkaUtils.java:55)
    at storm.kafka.KafkaUtils.getOffset(KafkaUtils.java:45)
    at storm.kafka.PartitionManager.(PartitionManager.java:77)
    at storm.kafka.ZkCoordinator.refresh(ZkCoordinator.java:78)
    ... 6 more
```

网上查了一下, 很多答案答非所问, 最后在github的kafkaSpout的作者的Issue List中找到了答案, 顺利解决 https://github.com/wurstmeister/storm-kafka-0.8-plus/issues/36


**问题在于: storm kafkaSpout 通过ZK去获取kafka的地址, 但是zk中保存的kafka是以域名的方式保存的, 而新集群上没有配置相关的hosts, 所以只需要在新集群的supervior机器上的/etc/hosts加上对应的kafka hosts即可**


