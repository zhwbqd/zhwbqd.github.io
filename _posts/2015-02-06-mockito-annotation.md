---
layout: post
title: "Mockito 注解使用"
comments: true
tags: JAVA
---

#### Mockito简介
Mockito 是 Google 实现的测试框架, 语法跟EasyMock很像, 但从语法来看, Mockito更加简洁.
这是[官网EasyMock和Mockito的对比](https://code.google.com/p/mockito/wiki/MockitoVSEasyMock)

Mockito的所有功能都在Mockito这个类中，里面的函数按功能可分为几类:

1. 参数匹配 — 就是Matchers里的那些any开头的函数

2. Mock

3. 打桩（stub）功能 — 就是那些do什么开头的函数

4. 验证模型 verify, 包括atLeast，atLeastOnce，atMost，only，times

#### Mockito注解使用

##### 支持注解:

* @Mock
> 代替mock(xxx.class), 代码精简

* @Spy
> 可以监视真实对象, 只mock想要打桩的方法

* @Captor
> 参数捕获器, 用于获取mock方法内部的对象, 进行验证使用

* @InjectMocks
> 主动将已存在的mock对象注入到bean中, 按名称注入, 但注入失败不会抛出异常

##### 示例代码:

```java
public class JackBoltTest {

	@InjectMocks
    private JackBolt jackBolt = new JackBolt();
    @Captor
    private ArgumentCaptor<Values> valuesCaptor;
    @Mock
    private Tuple tuple;
    @Mock
    private BasicOutputCollector basicOutputCollector;

    @BeforeMethod
    public void setUp() throws Exception {
        MockitoAnnotations.initMocks(this); //需要将注解进行初始化
        when(tuple.getFields()).thenReturn(new Fields());
    }
	
	@Test(description = "这里是描述")
    public void testExecute() {
        when(tuple.getValue(0)).thenReturn("你想要的值");
        analyzeBolt.execute(tuple, basicOutputCollector);
        verify(basicOutputCollector, times(1)).emit(valuesCaptor.capture());//可以捕获用于发送的values对象

        Values value = valuesCaptor.getValue(); //进行校验
        assertEquals(value.get(0), "2");
        assertEquals(value.get(4), 1);
    }
}
	
```

关于@spy的示例代码
```java
@Test
public void spyTest2() {
    
    List list = new LinkedList();
    List spy = spy(list);
  
    //optionally, you can stub out some methods:
    when(spy.size()).thenReturn(100);
  
    //using the spy calls real methods
    spy.add("one");
    spy.add("two");
  
    //prints "one" - the first element of a list
    System.out.println(spy.get(0));
  
    //size() method was stubbed - 100 is printed
    System.out.println(spy.size());
  
    //optionally, you can verify
    verify(spy).add("one");
    verify(spy).add("two"); 
}

```

