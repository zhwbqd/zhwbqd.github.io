---
layout: post
title: "MYSQL索引优化"
comments: true
tags: 技术与产品
---

#### Btree:

1. 尽量使用覆盖索引, 即三星索引
2. 多列索引如果带范围的话, 后续列不会作为筛选条件
3. 多列索引应选择过滤性更好的充当前缀索引
4. 尽量按主键顺序插入, 减少页分裂, 采用自增ID在高并发情况下, 可能造成明显征用, 或者更改innodb_autoinc_lock_mode配置.

#### Hash:

1. 只有精确匹配所有列的查询才有效, 对于每行数据, 引擎都会对所有索引列计算hash码
2. 只有memory才可以支持hash索引, innodb支持自适应hash索引, 但是不受人为控制, 是innodb的内部优化, 他会在内存中基于Btree在建立一个hash索引
3. hash索引结构十分紧凑, 查询速度快, 但是也有限制:
> *  只包含hash值和指针
> *  hash索引不是排序的
> *  hash索引不支持部分索引列匹配
> *  不支持范围查询
> *  访问速度快, 除非有hash冲突
> *  不适合对选择性很低的列上建立索引, 冲突越多, 代价越大

4. 在innoDB上创建自定义hash索引, 思路: 在Btree上创建伪hash索引, 例如要保持大量url, 根据url进行查询, 如果使用btree, 存储内容会很大, 增加一个url_crc列, 使用CRC32进行hash, 查询的时候使用select id from url where url=CRC32("http://sdad.com"); 这样做性能非常高, 维护hash索引值可以手动维护, 也可用触发器, 不能采用SHA1或者MD5作为hash函数, 因为这两个函数的计算hash值非常大, 浪费空间, 消除冲突在这里不是最高要求,  出现hash冲突, 可采用select id from url where url_crc=CRC32("http://sadsa") AND url = "hhtp://asdad.com", 也可使用FNV64()作为hash函数, 冲突小很多

#### Explain:
1. Using union 说明索引应该合并
2. using index 说明是覆盖索引, 赞
3. using where 说明索引未完全覆盖, 或者是使用like查询
4. using where, using index
