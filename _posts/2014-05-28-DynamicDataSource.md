---
layout: post
title: "事务与动态数据源"
comments: true
tags: JAVA
---

#### 问题描述:
写主库开事务的情况下会导致时不时的将更新/插入操作写入到从库上, 导致mysqlException update command denied

#### 问题原因:
jetty的工作队列会重用处理线程, 导致threadLocal中的值被重用, 然而transaction注解在service层, 会在DynamicDataSourceSwitch被设置之前直接去threadlocal拿数据, 本应拿到null, 但是拿到了之前线程的值

#### 问题解决:
DataSourceAdvice AfterReturn需要删除threadLocal中的数据源key

```java
public class DataSourceAdvice implements MethodBeforeAdvice, AfterReturningAdvice, ThrowsAdvice {

    private static final Logger LOG = LoggerFactory.getLogger(DataSourceAdvice.class);

    @Override
    public void afterReturning(Object returnValue, Method method, Object[] args, Object target)
throws Throwable {
        DataSourceSwitcher.clearDataSource();
    }  
}
```

#### 事务代码调用链:

> service注解上@transactional-->TransactionInterceptor.interpter()-->TransactionAspectSupport.createTransactionIfNecessary()-->AbstractPlatformTransactionManager.getTransaction()-->DataSourceTransactionManager.doBegin()-->AbstractRoutingDataSource.determineTargetDataSource()[lookupKey==null去拿默认的Datasource, 不为空则使用获取到的连接]-->DataSourceTransactionManager.setTransactional()[将连接设置到TransactionUtils的threadLocal中]--->Repository@Annotation-->执行一般调用链, 问题在于SpringManagedTransaction.getConnection()-->openConnection()-->DataSourceUtils.getConnection()-->TransactionSynchronizationManager.getResource(dataSource)不为空[从TransactionUtils的threadLocal中获取数据源], 所以不会再去调用DynamicDataSource去获取数据源
