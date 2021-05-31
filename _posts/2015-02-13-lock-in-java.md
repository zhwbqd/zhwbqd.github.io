---
layout: post
title: "浅谈Java中的锁"
comments: true
tags: 技术与产品
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

> wait有出让Object锁的语义, 要想出让锁, 前提是要先获得锁, 所以要先用synchronized获得锁之后才能调用wait. notify原因类似, Object.wait()和notify()不具有原子性语义, 所以必须用synchronized保证线程安全.

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

1. 作为修饰符加在方法声明上, synchronized修饰非静态方法时表示锁住了调用该方法的堆对象, 修饰静态方法时表示锁住了这个类在方法区中的类对象.
2. synchronized(X.class) 使用类对象作为monitor. 同一时间只有一个线程可以能访问块中资源. 
3. synchronized(this)和synchronized(mutex) 都是对象锁, 同一时间每个实例都保证只能有一个实例能访问块中资源. 

> sychronized的对象最好选择引用不会变化的对象（例如被标记为final,或初始化后永远不会变）, 虽然synchronized是在对象上加锁, 但是它首先要通过引用来定位对象, 如果引用会变化, 可能带来意想不到的后果


#### 1.3 synchronized和volatile比较

简单的说就是synchronized的代码块是确保可见性和原子性的, volatile只能确保可见性
当且仅当下面条件全部满足时, 才能使用volatile

> 1. 对变量的写入操作不依赖于变量的当前值, (++i/i++这种肯定不行), 或者能确保只有单个线程在更新
> 2. 该变量不会与其他状态变量一起纳入不变性条件中
> 3. 访问变量时不需要加锁

#### 1.4 synchonrize和juc中的锁比较

ReentrantLock在内存上的语义于synchronize相同, 但是它提供了额外的功能, 可以作为一种高级工具. 当需要一些 **可定时, 可轮询, 可中断的锁获取操作, 或者希望使用公平锁, 或者使用非块结构的编码时** 才应该考虑ReetrantLock. 

总结一点, 在业务并发简单清晰的情况下推荐synchronized, 在业务逻辑并发复杂, 或对使用锁的扩展性要求较高时, 推荐使用ReentrantLock这类锁. 另外今后JVM的优化方向一定是基于底层synchronize的, 性能方面应该选择synchronize

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

### 2. Juc中的同步辅助类

#### 2.1 Semaphore 信号量是一类经典的同步工具. 信号量通常用来限制线程可以同时访问的（物理或逻辑）资源数量.

#### 2.2 CountDownLatch 一种非常简单, 但很常用的同步辅助类. 其作用是在完成一组正在其他线程中执行的操作之前,允许一个或多个线程一直阻塞.

#### 2.3 CyclicBarrier 一种可重置的多路同步点, 在某些并发编程场景很有用. 它允许一组线程互相等待, 直到到达某个公共的屏障点 (common barrier point). 在涉及一组固定大小的线程的程序中, 这些线程必须不时地互相等待, 此时 CyclicBarrier 很有用.因为该 barrier在释放等待线程后可以重用, 所以称它为循环的barrier. 

#### 2.4 Phaser 一种可重用的同步屏障, 功能上类似于CyclicBarrier和CountDownLatch, 但使用上更为灵活. 非常适用于在多线程环境下同步协调分阶段计算任务（Fork/Join框架中的子任务之间需同步时, 优先使用Phaser）

#### 2.5 Exchanger 允许两个线程在某个汇合点交换对象, 在某些管道设计时比较有用. Exchanger提供了一个同步点, 在这个同步点, 一对线程可以交换数据. 每个线程通过exchange()方法的入口提供数据给他的伙伴线程, 并接收他的伙伴线程提供的数据并返回. 当两个线程通过Exchanger交换了对象, 这个交换对于两个线程来说都是安全的. Exchanger可以认为是 SynchronousQueue 的双向形式, 在运用到遗传算法和管道设计的应用中比较有用. 

-----------

### 3. juc中的锁源码分析

juc中的锁分两种, 1. 可重入锁; 2. 读写锁. 两者都用到了一个通用组件 AbstractQueuedSynchronizer. 先从它说起

#### 3.1 AbstractQueuedSynchronizer

利用了一个int来表示状态, 内部基于FIFO队列及UnSafe的CAS原语作为操纵状态的数据结构, AQS以单个 int 类型的原子变量来表示其状态，定义了4个抽象方法（ tryAcquire(int)、tryRelease(int)、tryAcquireShared(int)、tryReleaseShared(int)，前两个方法用于独占/排他模式，后两个用于共享模式 ）留给子类实现，用于自定义同步器的行为以实现特定的功能。这方面的介绍大家看一下资料2, 描述非常清楚

引用资料2中的一段话: 

> 同步器是实现锁的关键，利用同步器将锁的语义实现，然后在锁的实现中聚合同步器。可以这样理解：锁的API是面向使用者的，它定义了与锁交互的公共行为，而每个锁需要完成特定的操作也是透过这些行为来完成的（比如：可以允许两个线程进行加锁，排除两个以上的线程），但是实现是依托给同步器来完成；同步器面向的是线程访问和资源控制，它定义了线程对资源是否能够获取以及线程的排队等操作。锁和同步器很好的隔离了二者所需要关注的领域，严格意义上讲，同步器可以适用于除了锁以外的其他同步设施上（包括锁）。

#### 3.2 ReentrantLock

可重入锁, 支持公平和非公平策略(FairSync/NonFairSync), 默认非公平锁, 内部Sync继承于AbstractQueuedSynchronizer.

两者代码区别是:

FairSync 代码中对于尝试加锁时(tryAcquire)多了一个判断方法, 判断等待队列中是否还有比当前线程更早的, 如果为空，或者当前线程线程是等待队列的第一个时才占有锁

```java
if (c == 0) {
    if (!hasQueuedPredecessors() && //就是这里
        compareAndSetState(0, acquires)) {
        setExclusiveOwnerThread(current);
        return true;
    }
}

public final boolean hasQueuedPredecessors() {
	// The correctness of this depends on head being initialized
	// before tail and on head.next being accurate if the current
	// thread is first in queue.
	Node t = tail; // Read fields in reverse initialization order
	Node h = head;
	Node s;
	return h != t &&
		((s = h.next) == null || s.thread != Thread.currentThread());
}
```
#### 3.3 ReentrantReadWriteLock

##### 3.3.1 引子

可重入的读写锁, 首先我想到的是它的适用场景, 它与volatile有何区别, 又有何优势呢?

> volatile只能保证可见性, 在1写N读的情况下, 使用它就足够了. 但是如何N写N读, 如何保证数据一致性而又减少并行度的损失呢? 就要看ReentrantReadWriteLock了.

##### 3.3.2 源码分析:

读锁

```java
public static class ReadLock implements Lock, java.io.Serializable  {
    private final Sync sync;

    protected ReadLock(ReentrantReadWriteLock lock) {
        sync = lock.sync;
    }

    public void lock() {
        sync.acquireShared(1);//共享锁
    }

    public void lockInterruptibly() throws InterruptedException {
        sync.acquireSharedInterruptibly(1);
    }

    public  boolean tryLock() {
        return sync.tryReadLock();
    }

    public boolean tryLock(long timeout, TimeUnit unit) throws InterruptedException {
        return sync.tryAcquireSharedNanos(1, unit.toNanos(timeout));
    }

    public  void unlock() {
        sync.releaseShared(1);
    }

    public Condition newCondition() {
        throw new UnsupportedOperationException();
    }

}
```

写锁

```java
public static class WriteLock implements Lock, java.io.Serializable  {
    private final Sync sync;
    protected WriteLock(ReentrantReadWriteLock lock) {
        sync = lock.sync;
    }
    public void lock() {
        sync.acquire(1);//独占锁
    }

    public void lockInterruptibly() throws InterruptedException {
        sync.acquireInterruptibly(1);
    }

    public boolean tryLock( ) {
        return sync.tryWriteLock();
    }

    public boolean tryLock(long timeout, TimeUnit unit) throws InterruptedException {
        return sync.tryAcquireNanos(1, unit.toNanos(timeout));
    }

    public void unlock() {
        sync.release(1);
    }

    public Condition newCondition() {
        return sync.newCondition();
    }

    public boolean isHeldByCurrentThread() {
        return sync.isHeldExclusively();
    }

    public int getHoldCount() {
        return sync.getWriteHoldCount();
    }
}
```

> WriteLock就是一个独占锁，这和ReentrantLock里面的实现几乎相同，都是使用了AQS的acquire/release操作。当然了在内部处理方式上与ReentrantLock还是有一点不同的。对比清单1和清单2可以看到，ReadLock获取的是共享锁，WriteLock获取的是独占锁。

> AQS中有一个state字段（int类型，32位）用来描述有多少线程获持有锁。在独占锁的时代这个值通常是0或者1（如果是重入的就是重入的次数），在共享锁的时代就是持有锁的数量。在上一节中谈到，ReadWriteLock的读、写锁是相关但是又不一致的，所以需要两个数来描述读锁（共享锁）和写锁（独占锁）的数量。显然现在一个state就不够用了。于是在ReentrantReadWrilteLock里面将这个字段一分为二，高位16位表示共享锁的数量，低位16位表示独占锁的数量（或者重入数量）。2^16-1=65536，所以共享锁和独占锁的数量最大只能是65535。

##### 3.3.3 写入锁分析:

1. 持有锁线程数非0（c=getState()不为0），如果写线程数（w）为0（那么读线程数就不为0）或者独占锁线程（持有锁的线程）不是当前线程就返回失败，或者写入锁的数量（其实是重入数）大于65535就抛出一个Error异常

2. 如果当且写线程数位0（那么读线程也应该为0，因为步骤1已经处理c!=0的情况），并且当前线程需要阻塞那么就返回失败；如果增加写线程数失败也返回失败

3. 设置独占线程（写线程）为当前线程，返回true。

```java
protected final boolean tryAcquire(int acquires) {
    Thread current = Thread.currentThread();
    int c = getState();
    int w = exclusiveCount(c);
    if (c != 0) {
        if (w == 0 || current != getExclusiveOwnerThread())
            return false;
        if (w + exclusiveCount(acquires) > MAX_COUNT)
            throw new Error("Maximum lock count exceeded");
    }
    if ((w == 0 && writerShouldBlock(current)) ||
        !compareAndSetState(c, c + acquires))
        return false;
    setExclusiveOwnerThread(current);
    return true;
}
```

##### 3.3.4 列出读写锁几个特性:

* 重入性
> 读写锁允许读线程和写线程按照请求锁的顺序重新获取读取锁或者写入锁。当然了只有写线程释放了锁，读线程才能获取重入锁。
> 写线程获取写入锁后可以再次获取读取锁，但是读线程获取读取锁后却不能获取写入锁。
> 另外读写锁最多支持65535个递归写入锁和65535个递归读取锁。

* 锁降级
> 写线程获取写入锁后可以获取读取锁，然后释放写入锁，这样就从写入锁变成了读取锁，从而实现锁降级的特性。

* 锁升级
> 读取锁是不能直接升级为写入锁的。因为获取一个写入锁需要释放所有读取锁，所以如果有两个读取锁视图获取写入锁而都不释放读取锁时就会发生死锁。

* 锁获取中断
> 读取锁和写入锁都支持获取锁期间被中断。这个和独占锁一致。

* 条件变量

> 写入锁提供了条件变量(Condition)的支持，这个和独占锁一致，但是读取锁却不允许获取条件变量，将得到一个UnsupportedOperationException异常。


参考资料:
> 1. [并发编程网关于同步原语的介绍](http://java-latte.blogspot.com/2014/04/Semaphore-CountDownLatch-CyclicBarrier-Phaser-Exchanger-in-Java.html)

> 2. [并发编程网关于同步器的介绍](http://ifeve.com/introduce-abstractqueuedsynchronizer/)

> 3. [并发编程网关于读写锁的介绍](http://ifeve.com/read-write-locks/)