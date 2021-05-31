---
layout: post
title: "解析与实战JDK Unsafe"
comments: true
tags: 技术与产品
---

说到锁, 无锁队列, 那么就不能不说 **sun.misc.Unsafe** , juc底层的操作很多都是依赖于Unsafe提供的方法. 事实上它能做的事情远远多于这些.

在我的github上我写了几个示例代码, 来说明它的各种用法. [请移步这里](https://github.com/zhwbqd/java/tree/master/java_conclusion/src/main/java/zhwb/study/unsafe)

#### 1. Unsafe的初始化

为了防止程序员误用, Unsafe的构造器声明为私有. 并且静态方法Unsafe.getUnsafe()会检查类加载器是否是BootstrapClassLoader, 否则抛出SecurityException

```java
public static Unsafe getUnsafe() {
    Class cc = sun.reflect.Reflection.getCallerClass(2);
    if (cc.getClassLoader() != null)
        throw new SecurityException("Unsafe");
    return theUnsafe;
}
```

> 1. 我们可以指定使用bootstrap来加载我们的class, 但是这样做不方便.  java -Xbootclasspath:/usr/jdk1.7.0/jre/lib/rt.jar:

> 2. 我们可以通过Reflecttion获得Unsafe中的私有成员变量theUnsafe

```java
Field f = Unsafe.class.getDeclaredField("theUnsafe");
f.setAccessible(true);
Unsafe unsafe = (Unsafe) f.get(null);
```

=============================================

#### 2. Unsafe中的API

Unsafe中有105个方法, 我将其中重要的几类列下来:

* Info. 返回底层内存信息

> * addressSize 
> * pageSize

* Objects. 操作对象和field

> * allocateInstance
> * objectFieldOffset

* Classes. 操作类和静态变量

> * staticFieldOffset
> * defineClass
> * defineAnonymousClass
> * ensureClassInitialized

* Arrays. 操作数组

> * arrayBaseOffset
> * arrayIndexScale

* Synchronization 底层同步操作

> * monitorEnter
> * tryMonitorEnter
> * monitorExit
> * compareAndSwapInt
> * putOrderedInt

* Memory. 直接操作内存

> * allocateMemory
> * copyMemory
> * freeMemory
> * getAddress
> * getInt
> * putInt

#### 3. 有趣的case

##### 1. 防止初始化

> 使用allocateInstance(), 可以防止对象初始化. 包括field的初始化和构造器

* 需要跳过对象初始化阶段
* 绕过含安全检查的构造函数
* 想要的获得类的实例，但它没有任何公开的构造器


```java
class A {
    private long a; // not initialized value

    public A() {
        this.a = 1; // initialization
    }

    public long a() { return this.a; }
}

A o1 = new A(); // constructor
o1.a(); // prints 1

A o2 = A.class.newInstance(); // reflection
o2.a(); // prints 1

A o3 = (A) unsafe.allocateInstance(A.class); // unsafe
o3.a(); // prints 0
```

##### 2. 内存填充/替换

使用putInt可以将指定位置的内存进行填充和替换, 与Reflection的区别是: 反射必须指定对象, 而Unsafe只需要指定内存地址

```java
unsafe.putInt(obj, 16 + unsafe.objectFieldOffset(f), 42); // obj对象的大小在32位系统中占16位, 故可以将相邻的obj中字段进行赋值
```

##### 3. 获得对象大小

使用objectFieldOffset可以获得对象大小. (shallow size 并非真实的占用内存大小)

> 遍历所有非静态变量, 包括父类. 获得每个变量的offset, 找到最大的offset. 并增加padding(内存对齐. 按8位进行对齐)

```java
public static long sizeOf(Object o) {
    Unsafe u = getUnsafe();
    HashSet<Field> fields = new HashSet<Field>();
    Class c = o.getClass();
    while (c != Object.class) {
        for (Field f : c.getDeclaredFields()) {
            if ((f.getModifiers() & Modifier.STATIC) == 0) {
                fields.add(f);
            }
        }
        c = c.getSuperclass();
    }

    // get offset
    long maxSize = 0;
    for (Field f : fields) {
        long offset = u.objectFieldOffset(f);
        if (offset > maxSize) {
            maxSize = offset;
        }
    }

    return ((maxSize/8) + 1) * 8;   // padding, 8位对齐
}
```

##### 4. 并发

juc中的Atomic, ConcurrentLinkedQueue, ReentrantLock的底层实现都有Unsafe的参与, 主要是使用了两个方法, objectFieldOffset和compareAndSwapObject

```
Counter counter = new Counter() {
            private volatile long counter = 0;
            private Unsafe unsafe;
            private long offset;

            {
                unsafe = UnSafeFactory.getInstance();
                offset = unsafe.objectFieldOffset(this.getClass().getDeclaredField("counter"));
            }

            @Override
            public void  increment() {
                long before = counter;
                unsafe.getAndAddLong(this, offset, 1L); //jdk1.8优化, 无需loop
//                while (!unsafe.compareAndSwapLong(this, offset, before, before + 1)) {
//                    before = counter;
//                }
            }

            @Override
            public long getCounter() {
                return counter;
            }
        };
		
//以下是从OpenJDK copy来的, 保留行号.
1047		public final long getAndAddLong(Object o, long offset, long delta) {
1048        long v;
1049        do {
1050            v = getLongVolatile(o, offset);
1051        } while (!compareAndSwapLong(o, offset, v, v + delta));
1052        return v;
1053    }
```

关于cas的参考资料: 

1. [CAS Loop的问题](http://cs.oswego.edu/pipermail/concurrency-interest/2014-May/012705.html)
2. [CAS性能](https://blogs.oracle.com/dave/entry/atomic_fetch_and_add_vs)
3. [OpenJDK中Unsafe的源码](http://grepcode.com/file/repository.grepcode.com/java/root/jdk/openjdk/8-b132/sun/misc/Unsafe.java?av=f)
