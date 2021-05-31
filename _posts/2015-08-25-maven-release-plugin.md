---
layout: post
title: "Maven release plugin 心得"
comments: true
tags: 技术与产品
---

说到Maven 和 Maven 相关的Plugin, 有很多大家耳熟能详的. 但是跟项目发布相关的插件, 首推[maven release plugin](http://maven.apache.org/maven-release/maven-release-plugin/), 省心太多!

### 为什么要用它?

如果项目中需要发布一些外部系统所依赖的包, 那么应该有如下几步:

> 1. 把版本号后面的SNAPSHOT去掉(SNAPSHOT是可以被重复覆盖的),  向maven私服发布一个稳定版本;
> 2. 需要在git上面建立tag, 作为release的milestone;
> 3. 为下一个迭代进行SNAPSHOT版本的准备.

如果人肉去做这几件事情, 会很烦还容易出错. maven release plugin 就是帮我们做这几件事情的. 他还会额外帮助我们做:

> 1. 检查项目中所有的外部依赖包, 是否包含SNAPSHOT;
> 2. 检查是否有未提交的代码;
> 3. 运行单元测试, 确保全部通过.

### 使用说明

一般来说引入maven release plugin需要如下几步:

> 1. 在项目的pom文件中(如果是multi-module的只需要在主Pom中添加), 增加 <distributionManagement> 和 <scm>, 无需添加mvn-release-plugin的依赖, 因为它默认被包含于maven的effective pom中;
> 2. 检查自己的maven settings.xml是否包含了私服的用户名密码;
> 3. 确保自己本地代码是在主分支, 并且是最新的副本, 否则后果自负;
> 3. 执行 mvn release:prepare, 这时插件会扫描项目依赖查看是否有SNAPSHOT, 是否存在未提交的文件, 确定当前release的版本号和下一个迭代的版本号, 插件会运行单元测试, 并向git中提交两次commit, 一次是release版本, 一次是下一个迭代的版本. 并将当前release版本打一个tag并提交到git上面去;
> 4. 执行 mvn release:perform, 插件会执行mvn deploy 操作, 并clean掉生成的缓存文件.

so easy, 顺利的进行完成后, 你就会发现, 项目已经顺利的从 1.0-SNAPSHOT 变成了 1.0.1-SNAPSHOT. 并且 1.0 版本已经在git的tag和maven的私服上面了. 大功告成!

---------------------

执行mvn release:prepare之后, git log

```xml
commit ff
Author: jack.zhang <jack.zhang@xxx.com>
Date:   Tue Aug 25 17:45:56 2015 +0800

    [maven-release-plugin] prepare for next development iteration

commit be
Author: jack.zhang <jack.zhang@xxx.com>
Date:   Tue Aug 25 17:45:50 2015 +0800

    [maven-release-plugin] prepare release project-1.0.1

```

-------------------------

pom文件中的设置

```xml
	<distributionManagement>
        <repository>
            <id>releases</id>
            <name>xxxx internal releases repository</name>
            <url>http://xxx.com/nexus/content/repositories/releases</url>
        </repository>
        <snapshotRepository>
            <id>snapshots</id>
            <name>xxxx internal snapshots repository</name>
            <url>http://xxx.com/nexus/content/repositories/snapshots</url>
        </snapshotRepository>
    </distributionManagement>

    <scm>
        <url>http://xxx.com/project</url>
        <connection>scm:git:git@xxx.com/project.git</connection>
        <developerConnection>scm:git:git@xxx.com/project.git</developerConnection>
        <tag>HEAD</tag>
    </scm>
```
-------------------------

### 可能出现的问题与解决方案

一般情况下, 如果出现任何的build失败的情况, 请仔细查阅maven日志, 无非是以下几种情况

1. 依赖项中版本带SNAPSHOT;
2. 单元测试未通过;
3. scm或者distributionManagement  没有在pom中进行配置;
4. mvn release: perform 返回400;
5. 代码改动没有merge;
6. 不想升级了.

> 出现这些情况不要慌, 如果没有执行mvn release:perform, 那么改动是不会真正发布到maven私服上面的, 可以通过 mvn release:rollback, 进行回退处理.

> 如果还不行那么最简单的方案就是 mvn release:clean ,  git clean -fd, 会清除一切的maven插件产生的中间文件

> 如果是mvn release:perform时出现400问题, 那么检查一下你的私服的用户名密码是否在maven settings.xml中配置正确, 再检查一下当前release的版本是否在私服上已经有了. 

