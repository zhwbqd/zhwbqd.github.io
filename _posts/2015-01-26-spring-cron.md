---
layout: post
title: "Spring Scheduler实现解析"
comments: true
tags: Spring
---

Spring3.0之后, 增加了调度器功能, 提供的@Schedule注解, 想必大家都用过, 有了它, 基本上Quartz就可以下岗了. 那么它内部是如何实现的呢? 

首先给出几个结论:

1. 调度器本质上还是通过juc的ScheduledExecutorService进行的
2. 调度器启动后你无法通过修改系统时间达到让它马上执行的效果
3. 被@Schedule注解的方法如果有任何Throwable出现, 不会中断后续Task, 只会打印Error日志

主要与这几个类相关: *ScheduledAnnotationBeanPostProcessor*, *ScheduledTaskRegistrar*, *TaskScheduler*, *ReschedulingRunnable*

### 1. ScheduledAnnotationBeanPostProcessor

**写在前面:** 

> BeanPostProcessor 是Spring中的基础组件, 可以帮助我们进行Bean的预处理和后处理, 请注意, 它是对容器中所有的bean都生效的, 所以如果自己实现的话必须包含过滤条件. Spring组件中, 一共有不到20个BeanPostProcessor, 需要顺序的时候则实现Ordered接口自定义优先级即可 

**功能介绍:**

> 负责@Schedule注解的扫描, 构建ScheduleTask向ScheduledTaskRegistrar中注册, 调用ScheduledTaskRegistrar.afterPropertiesSet()

**核心代码:**

```java
	public Object postProcessAfterInitialization(final Object bean, String beanName) {
		final Class<?> targetClass = AopUtils.getTargetClass(bean);
		ReflectionUtils.doWithMethods(targetClass, new MethodCallback() {
			public void doWith(Method method) throws IllegalArgumentException, IllegalAccessException {
				Scheduled annotation = AnnotationUtils.getAnnotation(method, Scheduled.class);//查找注解
				if (annotation != null) {
				  //省略
				  
				  //构建CronTask并注册到ScheduledTaskRegistrar
				  String cron = annotation.cron();
						if (!"".equals(cron)) {
							Assert.isTrue(initialDelay == -1, "'initialDelay' not supported for cron triggers");
							processedSchedule = true;
							if (embeddedValueResolver != null) {
								cron = embeddedValueResolver.resolveStringValue(cron);
							}
							registrar.addCronTask(new CronTask(runnable, cron));
						}
						
					//省略
				}
			}
		}
	}
	
	public void onApplicationEvent(ContextRefreshedEvent event) {
		//省略
		this.registrar.afterPropertiesSet();
	}
	
}
```

### 2. ScheduledTaskRegistrar

**功能介绍:**

> 它是Schedule中所支持的三种Task的一个容器, 内部维护了这些Task List和executor的引用, 并负责将Task置入executor中执行

**核心代码:**

```java

	protected void scheduleTasks() {
		
		if (this.cronTasks != null) {
			for (CronTask task : cronTasks) {
				this.scheduledFutures.add(this.taskScheduler.schedule(
						task.getRunnable(), task.getTrigger()));
			}
		}
	}
```

### 3. TaskScheduler

**功能介绍:**

> TaskScheduler是Spring中专门用于进行定时操作的接口, 主要的实现类有三个 ThreadPoolTaskScheduler, ConcurrentTaskScheduler, TimerManagerTaskScheduler, 前两个delegate juc里面的ScheduledExecutor, 最后一个delegate commonj.timers.TimerManager. 这个类的作用主要是将task和executor用ReschedulingRunnable包装起来进行生命周期管理

**核心代码:**

```java
	public ScheduledFuture schedule(Runnable task, Trigger trigger) {
		ScheduledExecutorService executor = getScheduledExecutor();
		try {
			ErrorHandler errorHandler =
					(this.errorHandler != null ? this.errorHandler : TaskUtils.getDefaultErrorHandler(true));//无默认handler, 则只打印LOG 不进行rethrow
			return new ReschedulingRunnable(task, trigger, executor, errorHandler).schedule();
		}
		catch (RejectedExecutionException ex) {
			throw new TaskRejectedException("Executor [" + executor + "] did not accept task: " + task, ex);
		}
	}
```

### 4.  ReschedulingRunnable

**写在前面:**

> DelegatingErrorHandlingRunnable将Runnable代理, 进行异常捕获并可以使用自己的handler进行处理

> handler有两种, 通过TaskUtils.getDefaultErrorHandler(true)可以看到, 如果是true, 则说明是可重复任务, 则有异常捕获后只进行Log, false则Log之后rethrow Exception

**功能介绍:**

> 主要进行task的提交, 执行, 重提交, 取消, 这一套生命周期管理 

```java
	public ScheduledFuture schedule() {
		synchronized (this.triggerContextMonitor) {
			this.scheduledExecutionTime = this.trigger.nextExecutionTime(this.triggerContext);//根据当前时间和Crontab的格式, 找出下一次执行的时间点, 比如 2015-01-02 23:00:00 CST, 注意这里的时区使用的是Default的
			if (this.scheduledExecutionTime == null) {
				return null;
			}
			long initialDelay = this.scheduledExecutionTime.getTime() - System.currentTimeMillis();//将下一次执行时间点与当前时间相减, 得到等待时间, 所以在task启动的时候就已经定了下一次执行还有多少ms了
			this.currentFuture = this.executor.schedule(this, initialDelay, TimeUnit.MILLISECONDS); //调用ScheduledExecutor执行Task, 进行Schedule
			return this;
		}
	}

	@Override
	public void run() {
		Date actualExecutionTime = new Date();
		super.run();//执行被@Schedule注解的方法
		Date completionTime = new Date();
		synchronized (this.triggerContextMonitor) {
			this.triggerContext.update(this.scheduledExecutionTime, actualExecutionTime, completionTime);
			if (!this.currentFuture.isCancelled()) {
				schedule();//如果未被取消则重新调度
			}
		}
	}
```

整个调度器的结构就是这样, 主要要熟悉 DelegatingErrorHandlingRunnable, BeanPostProcessor, Ordered, EmbeddedValueResolverAware, ApplicationContextAware 这些Spring的基本组件, 万变不离其宗