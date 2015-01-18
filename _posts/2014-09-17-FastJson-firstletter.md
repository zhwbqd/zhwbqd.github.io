---
layout: post
title: "Fastjson首字母小写"
comments: true
tags: JAVA
---

项目组使用FastJson, 在输出下面一段Json的时候出现此问题, 期望是大写但是fastJson将值自动首字母变成小写了

```
{"code":0,"message":"","result":{"facts":{"ip":{"aCUN_ONE_MIN":0,"aCUN_TEN_MIN":0}},"level":0}}
```
查询后发现fastjson内部做Bean转换时会使用到 com.alibaba.fastjson.util.TypeUtils, 核心代码如下, >在类加载的时候会去读取环境变量 fastjson.compatibleWithJavaBean, 找不到则使用默认值false,将会导>致首字母小写

解决方案:

1. 如果你的项目由多个模块且为分布式部署, 则可考虑使用设置System.property

2. 一般只是极少数的代码出现此情况, 那么建议直接在你的单例Service初始化时, 在静态块中直接改变TypeUtils的变量值, 如果用Spring的话可以使用InitializingBean进行处理
> TypeUtils.compatibleWithJavaBean = true;
3. 此变量是public的注意要在一个地方进行改动, 避免线程安全问题
 
附上TypeUtils.java部分代码如下:

```java
public static boolean compatibleWithJavaBean = false;

    static {
        try {
            String prop = System.getProperty("fastjson.compatibleWithJavaBean");
            if ("true".equals(prop)) {
                compatibleWithJavaBean = true;
            } else if ("false".equals(prop)) {
                compatibleWithJavaBean = false;
            }
        } catch (Throwable ex) {
            // skip
        }
    }

public static List<FieldInfo> computeGetters(Class<?> clazz, Map<String, String> aliasMap, boolean sorted) {
String propertyName;
if (Character.isUpperCase(c3)) {
if (compatibleWithJavaBean) {
propertyName = Introspector.decapitalize(methodName.substring(3));
} else {
propertyName = Character.toLowerCase(methodName.charAt(3)) + methodName.substring(4);
}
} else if (c3 == '_') {
propertyName = methodName.substring(4);
} else if (c3 == 'f') {
propertyName = methodName.substring(3);
} else {
continue;
}}
```
