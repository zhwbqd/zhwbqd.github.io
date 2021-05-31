---
layout: post
title: "Java序列化 InvalidClassException"
comments: true
tags: 技术与产品
---

类实现序列化接口, 进行序列化反序列化的时候, 抛出 java.io.InvalidClassException 异常

```java
java.io.InvalidClassException: com.xx.Xxx; local class incompatible: stream classdesc serialVersionUID = -783991920331, local class serialVersionUID = -331138183213
```
这个异常是由于反序列化时, 当前类的serialVersionUID 与 bytes中的类反序列化后的类的serialVersionUID 不同所致, 这个serialVersionUID 如果不在类中显式声明, 则是通过类名，方法名等诸多因素经过计算而得，理论上是一一映射的关系，也就是唯一的

**解决方案: 在类中显式指定**

> privatestatic final long serialVersionUID = 42L;

查看JDK中关于Serializable接口的声明, 重要的几点:

1. 所有实现序列化的类，　都推荐显式声明序列化ID

2. 序列化ID的访问类型 推荐为 private, 因为只在自己内部被使用, 不会因为继承而流到子类

3. 数组是无法显示声明序列化ID的(比如String[], 你无法在其中声明serialVersionUID), 但是java的序列化也不会对数组对象进行serialVersionUID 的比较
