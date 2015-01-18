---
layout: post
title: "Kafka OffsetOutofRangeException"
comments: true
tags: NOSQL
---

最近公司的zk的down掉了,  storm job 重启的时候报出 kafka.common.OffsetOutOfRangeException 异常

网上查询了一些朋友的做法, 自己也看了一下代码, 最终还是解决了  

#### 原因:
  zk挂掉的这几天, kafka中之前的数据已经被清掉了, 但是zk中保存的offset还是几天之前的, 导致KafkaSpout要获取的offset超过了当前kafka的offset, 就像ArrayIndexOutOfRangeException一样

#### 解决方案:
 KafkaSpout 配置项中可以选择读取的方式, 共有三种, 如果Topology启动的时候未进行配置, 则默认是从Zk中读取, 所以导致了异常

> * -2: 从最老的开始读

> * -1: 从最近的开始读

> * 0: 从Zk中读

那么问题来了, 如何设置呢,  SpoutConfig很贴心的给我们提供了一个方法

```java
public void forceStartOffsetTime(long millis) {
        startOffsetTime = millis;
        forceFromStart = true;
    } 
```

所以我们只需要在我们的Topology中添加如下代码即可

```java
        /* -2=最老 -1=最新, 0=zk offset*/
        if (args != null && args[1] != null && Integer.valueOf(args[1]) != 0) {
            if (Integer.valueOf(args[1]) == -2) {
                spoutConfig.forceStartOffsetTime(-2); //从kafka最老的记录读取
            } else if (Integer.valueOf(args[1]) == -1) {
                spoutConfig.forceStartOffsetTime(-1); //从kafka最新的记录读取
            }//其他情况则默认从zk的offset读取

        } 
```
 

发布Topology的时候, 如果需要从最新记录读取, 则像这样  storm jar com.abc.StormTopology stormTopology -1
