---
layout: post
title: "Zookeeper 日志输出指定文件夹"
comments: true
tags: 技术与产品
---

最近在研究Zookeeper Storm Kafka, 顺便在本地搭了一套集群, 遇到了Zookeeper日志问题输出路径的问题, 发现zookeeper设置log4j.properties不能解决日志路径问题, 发现解决方案如下:

1. 修改log4j.properties, 这个大家都应该会改, 红色加粗处是我修改的, 但是改了这边还是不生效

```
# Define some default values that can be overridden by system properties
<font color="red"> zookeeper.root.logger=INFO,ROLLINGFILE </font> 
zookeeper.console.threshold=INFO
zookeeper.log.dir=.
<font color="red">zookeeper.log.file=zookeeper-1.log</font>
zookeeper.log.threshold=DEBUG
zookeeper.tracelog.dir=.
zookeeper.tracelog.file=zookeeper_trace.log

#
# ZooKeeper Logging Configuration
#

# Format is "<default threshold> (, <appender>)+

# DEFAULT: console appender only
log4j.rootLogger=${zookeeper.root.logger}

# Example with rolling log file
#log4j.rootLogger=DEBUG, CONSOLE, ROLLINGFILE

# Example with rolling log file and tracing
#log4j.rootLogger=TRACE, CONSOLE, ROLLINGFILE, TRACEFILE

#
# Log INFO level and above messages to the console
#
log4j.appender.CONSOLE=org.apache.log4j.ConsoleAppender
log4j.appender.CONSOLE.Threshold=${zookeeper.console.threshold}
log4j.appender.CONSOLE.layout=org.apache.log4j.PatternLayout
log4j.appender.CONSOLE.layout.ConversionPattern=%d{ISO8601} [myid:%X{myid}] - %-5p [%t:%C{1}@%L] - %m%n

#
# Add ROLLINGFILE to rootLogger to get log file output
#    Log DEBUG level and above messages to a log file
<font color="red"> log4j.appender.ROLLINGFILE=org.apache.log4j.DailyRollingFileAppender </font>
log4j.appender.ROLLINGFILE.Threshold=${zookeeper.log.threshold}
log4j.appender.ROLLINGFILE.File=${zookeeper.log.dir}/${zookeeper.log.file}

# Max log file size of 10MB
<font color="red"> #log4j.appender.ROLLINGFILE.MaxFileSize=10MB </font>
# uncomment the next line to limit number of backup files
#log4j.appender.ROLLINGFILE.MaxBackupIndex=10

log4j.appender.ROLLINGFILE.layout=org.apache.log4j.PatternLayout
log4j.appender.ROLLINGFILE.layout.ConversionPattern=%d{ISO8601} [myid:%X{myid}] - %-5p [%t:%C{1}@%L] - %m%n


#
# Add TRACEFILE to rootLogger to get log file output
#    Log DEBUG level and above messages to a log file
log4j.appender.TRACEFILE=org.apache.log4j.FileAppender
log4j.appender.TRACEFILE.Threshold=TRACE
log4j.appender.TRACEFILE.File=${zookeeper.tracelog.dir}/${zookeeper.tracelog.file}

log4j.appender.TRACEFILE.layout=org.apache.log4j.PatternLayout
### Notice we are including log4j's NDC here (%x)
log4j.appender.TRACEFILE.layout.ConversionPattern=%d{ISO8601} [myid:%X{myid}] - %-5p [%t:%C{1}@%L][%x] - %m%n
```

2. 还需要改${zkhome}/bin/zkEnv.sh, 请留意红色加粗处, 这时日志已经可以成功按照你设置的目录进行输出了

```
if [ "x${ZOO_LOG_DIR}" = "x" ]
then
   <font color="red"> ZOO_LOG_DIR="/apps/logs/zookeeper" </font>
fi

if [ "x${ZOO_LOG4J_PROP}" = "x" ]
then
   <font color="red"> ZOO_LOG4J_PROP="INFO,ROLLINGFILE" </font>
fi
```

3. 美中不足的是在你设定的目录中, 仍会有zookeeper.out文件存在, 虽然它的size=0, 但是仍让我感到不爽.

究其原因是因为zkServer.sh会使用nohup进行zookeeper的启动, 然而nohup必然会输出一个日志文件到你设置的目录中,

相关代码如下, 需要将此处的逻辑修改掉, 就可以将zookeeper.out移除啦, 如果你不是处女座当然可以省略这一步

```
<font color="red"> _ZOO_DAEMON_OUT="$ZOO_LOG_DIR/zookeeper.out" </font>

case $1 in
start)
    echo  -n "Starting zookeeper ... "
    if [ -f "$ZOOPIDFILE" ]; then
      if kill -0 `cat "$ZOOPIDFILE"` > /dev/null 2>&1; then
         echo $command already running as process `cat "$ZOOPIDFILE"`.
         exit 0
      fi
    fi
    nohup "$JAVA" "-Dzookeeper.log.dir=${ZOO_LOG_DIR}" "-Dzookeeper.root.logger=${ZOO_LOG4J_PROP}" \
    -cp "$CLASSPATH" $JVMFLAGS $ZOOMAIN "$ZOOCFG" > <font color="red"> "$_ZOO_DAEMON_OUT" </font> 2>&1 < /dev/null &
```
