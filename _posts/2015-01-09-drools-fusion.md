---
layout: post
title: "Drools Fusion初探"
comments: true
tags: JAVA
---

Drools Fusion (Complex Event Processing) 是Drools对于复杂事件处理的模块, 与它功能相似的是Esper, 两者都可以提供基于时间跨度和滑动窗口的事件处理, 两者最大的区别可能就在于1. Drools开源, 不支持Distribution, 语法drl, Esper有企业版, 支持Distribution, 语法类SQL

官方文档:

http://docs.jboss.org/drools/release/5.6.0.Final/drools-fusion-docs/html_single/

例子:

This is [an example](https://github.com/zhwbqd/droolsCEP) in my GitHub. 

### Drools Fusion中一些关键的概念

#### 1. event和fact的区别

> * event 一般是不变对象
> * event 与时间强相关
> * event 拥有可管理的生命周期(一般只会在有限的时间内匹配规则, 方便engine管理自动管理event, 将未匹配的event销毁, 并释放相关资源)
>* 每个event都有自己的ts, 可以使用滑动时间窗口, 例如: 统计过去60min的平均值

#### 2. drools support 两种语义的event, 时间点和区间(区别是 @duration 注解是否为0)
 
#### 3. 注解:
   > 1. @role 默认fact, CEP时候 @role(event) 标识fact 是一个event
   > 2. @timestamp, 每个event都有一个相关的timestamp, 默认是从系统获得(即为插入session的时间), 也可以由外部赋值
   > 3. @duration, 每个event的持续时间, 在point-in-time event中为0, 默认值也为0, 外部可赋值
   > 4. @expire, 只在STREAM MODE有效, event的过期时间, @expire(300) 300s过期 @expire(1d3h45m20s29ms) 1天3小时45分钟20秒29毫秒过期
 
#### 4. SessionClock 共有4中, 主要使用的有两种, realtime和pseudo
 
#### 5. After, Before, During, Meet 等关键字 都是用于比较两个事件的发生时间顺序
比如before关键字的意义
3m30s <= $eventB.startTimestamp - $eventA.endTimeStamp <= 4m 
$eventA : EventA( this before[ 3m30s, 4m ] $eventB ) 
 

#### 6. Sliding Window 只能跑在STREAM模式下, SlidingWindow 会立即执行运算,而不会等到事件满足要求才进行计算, event未在sliding window被匹配上的也不会被销毁, 可能有其他event依赖于它, 它会在自己的expire时间内过期



