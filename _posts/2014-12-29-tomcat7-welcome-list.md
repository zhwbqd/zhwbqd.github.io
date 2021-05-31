---
layout: post
title: "Tomcat7静态资源Mapping"
comments: true
tags: 技术与产品
---

问题描述:

web.xml中， 使用default servlet设置了针对静态资源后缀名的过滤. 并且设置了welcome-list, 使用jetty和tomcat6启动一切正常, 但是使用tomcat7则出现访问不到根节点(/)的情况. 

-------
解决方案:
将web.xml中的defaultServlet相关的mapping交由spring管理, 删掉web.xml中相关代码

```
    <servlet-mapping>
        <servlet-name>default</servlet-name>
        <url-pattern>*.html</url-pattern>
    </servlet-mapping>
```
------

原理和资料:

web.xml中， 使用default servlet设置了针对静态资源后缀名的过滤. 并且设置了welcome-list, 使用jetty和tomcat6启动一切正常, 但是使用tomcat7则出现访问不到根节点(/)的情况. 

1. Tomcat 6.0.30之前的security问题: https://issues.apache.org/bugzilla/show_bug.cgi?id=50026

2. 使用spring的resource标签: http://docs.spring.io/spring/docs/3.0.5.RELEASE/spring-framework-reference/html/mvc.html#mvc-static-resources

3. 不推荐使用容器自身的default servlet进行mapping: http://webmasters.stackexchange.com/questions/29550/why-the-difference-between-tomcat-and-tomcat7-regarding-servlet-mapping-and-defa 

4. 关于静态资源mapping的问题: http://stackoverflow.com/questions/870150/how-to-access-static-resources-when-using-default-servlet/3593513#3593513Tomcat 6.0.30之前的security问题: https://issues.apache.org/bugzilla/show_bug.cgi?id=50026

