---
layout: post
title: "Maven Filter"
comments: true
tags: 技术与产品
---

Maven提供了一个很不错的功能 Resource Filter, 可以将按不同环境的进行变量赋值, 比如数据库链接, redis, 日志输出位置等等.. 具体的filter如何使用我这里不做介绍, 只是把一些问题记录下来

1. spring中使用的如果是 xxx.properties文件中的值, maven的filter会将这些值直接替换掉, 这是我们不想看到的

2. src/main/resources/ 目录中有一些用于其他目的的二进制文件, 比如就像qq的地址库, 这些文件会被filter扫描到并且改变编码格式, 你就会发现单元测试一些ok, 打成war包部署这个文件对应的解析功能就失败

这时, exclude和include的功能就来了, 通过它, 你可以定义目录下的那些子目录需要(不需要)进行filter替换, 这样就可以做到精确的控制

```xml
<build>
<filters>
            <filter>src/main/resources/filters/filter-${env}.properties</filter>
        </filters>
        <resources>
            <resource>
                <directory>src/main/resources</directory>
                <filtering>true</filtering>
                <excludes>
                    <exclude>spring/*</exclude>
                    <exclude>filters/*</exclude>
                    <exclude>*.dat</exclude>
                </excludes>
            </resource>
            <resource>
                <directory>src/main/resources</directory>
                <filtering>false</filtering>
                <includes>
                    <include>spring/*</include>
                    <include>*.dat</include>
                </includes>
            </resource>
        </resources>
</build>
```
