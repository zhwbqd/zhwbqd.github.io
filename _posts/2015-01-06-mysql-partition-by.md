---
layout: post
title: "MYSQL分组聚合实现"
comments: true
tags: SQL
---

MySQL中没有类似oracle和postgreSQL的 OVER(PARTITION BY)功能. 那么如何在MYSQL中搞定分组聚合的查询呢?

**解决方案: 利用 group_concat + substr等函数处理**

------

例如: 订单表一张, 只保留关键字段

|id|	user_id|	money|	create_time|
|:---:|:---:|:-----:|---:|
|1|	1|	50|	1420520000|
|2|	1|	100|	1420520010|
|3|	2|	100|	1420520020|
|4|	2|	200|	1420520030|

需求: 查找每个用户的最近一笔消费金额

单纯使用group by user_id, 只能按user_id 将money进行聚合, 是无法将最近一单的金额筛选出来的, 只能满足这些需求, 例如:　每个用户的总消费金额 sum(money), 最大消费金额 max(money), 消费次数count(1) 等

但是我们有一个group_concat可以用, 思路如下:

**查找出符合条件的记录, 按user_id asc, create_time desc 排序;**

```sql
select ord.user_id, ord.money, ord.create_time from orders ord where ord.user_id > 0 and create_time > 0 order by ord.user_id asc , ord.create_time desc
```

将查出记录按user_id分组, group_concat(money);

```sql
select t.user_id, group_concat( t.money order by t.create_time desc ) moneys from (select ord.user_id, ord.money, ord.create_time from orders ord where ord.user_id > 0 and ord.create_time > 0 order by ord.user_id asc , ord.create_time desc) t group by t.user_id
```
这时, 如果用户有多个消费记录, 就会按照时间顺序排列好, 再利用subString_index 函数进行切分即可

**完整SQL,<font color="red"> 注意group_concat的内排序</font> , 否则顺序不保证, 拿到的就不一定是第一个了**

```sql
select t.user_id, substring_index(group_concat( t.money order by t.create_time desc ),',',1) lastest_money from (select ord.user_id, ord.money, ord.create_time from orders ord where ord.user_id > 0 and create_time > 0 order by user_id asc , create_time desc) t group by user_id ; 
```
利用这个方案, 以下类似业务需求都可以这么做, 如:

> 查找每个用户过去10个的登陆IP

> 查找每个班级中总分最高的两个人

--------

补充: 如果是只找出一行记录, 则可以直接只用聚合函数来进行

```sql
select t.user_id, t.money  from (select ord.user_id, ord.money, ord.create_time from orders ord where ord.user_id > 0 and create_time > 0 order by user_id asc , create_time desc) t group by user_id ;
```
前提一定是(1) 只需要一行数据, (2) 子查询中已排好序, (3) mysql关闭 strict-mode

------

参考资料:

http://dev.mysql.com/doc/refman/5.0/en/sql-mode.html#sql-mode-strict

http://dev.mysql.com/doc/refman/5.0/en/group-by-functions.html#function_group-concat
