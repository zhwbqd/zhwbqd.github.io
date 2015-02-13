---
layout: post
title: "浅谈Java中的锁"
comments: true
tags: JAVA
---

锁在并发编程中的重要性不言而喻, 但是如何更好地选择, 下面借几个问答来开始吧! 后续我会再写一篇有关于无锁队列的Blog

### 1. synchonrize如何更好地使用?

谈到这个问题, 主要先从这几个方面来入手:

> 1. 线程的几种状态
> 2. synchonrize的几种使用方法比较
> 3. synchonrize和volatile比较
> 4. synchonrize和juc中的锁比较
> 5. 用了锁就真的没有并发问题了么?

#### 1.1 线程的几种状态

不熟悉线程的生命周期和相互的转换控制, 是无法写好并发代码的. ![线程生命周期](/post_imgs/thread-lifecycle.jpg)

图简单易懂, 主要是搞清楚, sleep, yield, wait, notify, notifyAll对于锁的处理, 这里就不多展开了. 简单比较如下:

|方法|是否释放锁|备注|
|:---:|:---:|:-----:|
|wait|是|wait和notify/notifyAll是成对出现的, 必须在synchronize块中被调用|
|sleep|否|可使低优先级的线程获得执行机会|
|yield|否|yield方法使当前线程让出CPU占有权, 但让出的时间是不可设定的|

> wait有出让Object锁的语义, 要想出让锁，前提是要先获得锁，所以要先用synchronized获得锁之后才能调用wait. notify原因类似, Object.wait()和notify()不具有原子性语义, 所以必须用synchronized保证线程安全.

> yield()方法对应了如下操作: 先检测当前是否有相同优先级的线程处于同可运行状态, 如有, 则把 CPU 的占有权交给此线程, 否则继续运行原来的线程. 所以yield()方法称为“退让”, 它把运行机会让给了同等优先级的其他线程. 


#### 1.2 synchonrize的最佳实践

synchronize关键字主要有下面5种用法

1. 在方法上进行同步, 分为(1)instance method/(2)static method, 这两个的区别后面说
2. 在内部块上进行同步, 分为(3)synchronize(this), (4)synchonrize(XXX.class), (5)synchonrize(mutex)

```java
public class SyncMethod {
    private int value = 0;
	private final Object mutex = new Object();

    public synchronized int incAndGet0() {
       return ++value;
    }
	
	public int incAndGet1() {
		synchronized(this){
			return ++value;
		}
    }
	
	public int incAndGet2() {
       synchronized(SyncMethod.class){
			return ++value;
		}
    }
	
	public int incAndGet3() {
       synchronized(mutex){
			return ++value;
		}
    }
	
	public static synchonrize int incAndGet4() {
       synchronized(mutex){
			return ++value;
		}
    }
}
```

现在来分析:

1. 作为修饰符加在方法声明上，synchronized修饰非静态方法时表示锁住了调用该方法的堆对象，修饰静态方法时表示锁住了这个类在方法区中的类对象.
2. synchronized(X.class) 使用类对象作为monitor. 同一时间只有一个线程可以能访问块中资源. 
3. synchronized(this)和synchronized(mutex) 都是对象锁，同一时间每个实例都保证只能有一个实例能访问块中资源. 

> sychronized的对象最好选择引用不会变化的对象（例如被标记为final,或初始化后永远不会变），虽然synchronized是在对象上加锁, 但是它首先要通过引用来定位对象, 如果引用会变化, 可能带来意想不到的后果


#### 1.3 synchronized和volatile比较

简单的说就是synchronized的代码块是确保可见性和原子性的, volatile只能确保可见性
当且仅当下面条件全部满足时, 才能使用volatile

> 1. 对变量的写入操作不依赖于变量的当前值, (++i/i++这种肯定不行), 或者能确保只有单个线程在更新
> 2. 该变量不会与其他状态变量一起纳入不变性条件中
> 3. 访问变量时不需要加锁

#### 1.4 synchonrize和juc中的锁比较

ReentrantLock在内存上的语义于synchronize相同, 但是它提供了额外的功能, 可以作为一种高级工具. 当需要一些 **可定时, 可轮询, 可中断的锁获取操作, 或者希望使用公平锁, 或者使用非块结构的编码时** 才应该考虑ReetrantLock. 

总结一点，在业务并发简单清晰的情况下推荐synchronized, 在业务逻辑并发复杂, 或对使用锁的扩展性要求较高时, 推荐使用ReentrantLock这类锁. 另外今后JVM的优化方向一定是基于底层synchronize的, 性能方面应该选择synchronize

#### 1.5 用了锁就真的没有并发问题了么?

先上代码, 看一下是否有并发问题

```java
Map syncMap = Collections.synchronizedMap(new HashMap());
if(!map.containsKey("a")){
	map.put("a",value);
}
```

虽然Map上所有的方法都已被synchronize保护了, 但是在外部使用的时候, 一定要注意**竞态条件**

> 竞态条件: 先检查后执行的这种操作是最常见的竞态条件

下面是并发条件下的一些Donts

> 1. Don’t synchronize on an object you’re changing
> 2. Don’t synchronize on a String literal
> 3. Don’t synchronize on auto-boxed values
> 4. Don’t synchronize on null
> 5. Don’t synchronize on a Lock object
> 6. Don’t synchronize on getClass()
> 7. Be careful locking on a thread-safe object with encapsulated locking 

------------

### 2. Java中的同步原语

待续

-----------

### 3. juc中的锁主要的作用和源码分析

待续