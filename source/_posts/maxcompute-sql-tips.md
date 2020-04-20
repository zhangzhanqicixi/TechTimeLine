---
title: MaxCompute SQL 几个优化 Tips
date: 2020-04-20 15:36:40
tags: 
---

![sql](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/maxcompute_sql_tips/max-compute-sql-tips.png)

由于平常的工作学习中基本都是在阿里云上开发，Hive 接触的比较少，所以这次总结也主要是针对在 MaxCompute SQL 上的优化，本质上一些语法都是大同小异

<!--more-->

##### 列名快速选择 - SELECT 正则表达式

- 选出 dual 表中所有列名以 *abc* 开头的列
```
SELECT `abc.*` 
FROM dual
;
```

- 选出 dual 表中列名不为 *ds* 的列
```
SELECT `(ds)?+.+` 
FROM dual
;
```

- 选出 dual 表中排除 *ds* 和 *pt* 两列的其他列
```
SELECT `(ds|pt)?+.+` 
FROM dual
;
```

- 选出 dual 表中排除列名为 d 开头的其他列
```
SELECT `(d.*)?+.+` 
FROM dual
;
```

##### Json 解析 - 使用 JSON_TUPLE
比如有如下 json 
```
{"name": "zhangsan", "age": 26, "top3_location": [330110, 310120, 120345]}
```

使用传统的 *get_json_object* 函数解析所有字段

```
SELECT GET_JSON_OBJECT('{"name": "zhangsan", "age": 26, "top3_location": [330110, 310120, 120345]}', '$.name') AS name
, GET_JSON_OBJECT('{"name": "zhangsan", "age": 26, "top3_location": [330110, 310120, 120345]}', '$.age') AS age
, GET_JSON_OBJECT('{"name": "zhangsan", "age": 26, "top3_location": [330110, 310120, 120345]}', '$.top3_location[0]') AS location1
, GET_JSON_OBJECT('{"name": "zhangsan", "age": 26, "top3_location": [330110, 310120, 120345]}', '$.top3_location[1]') AS location2
, GET_JSON_OBJECT('{"name": "zhangsan", "age": 26, "top3_location": [330110, 310120, 120345]}', '$.top3_location[2]') AS location3
;
```

解析了 5 个字段，调用了 5 次函数，可以看到效率非常低，而用 *json_tuple* 就只要调用一次，就能解析所有字段

```
SELECT JSON_TUPLE('{"name": "zhangsan", "age": 26, "top3_location": [330110, 310120, 120345]}'
, 'name', 'age', 'top3_location[0]', 'top3_location[1]', 'top3_location[2]') 
AS (name, age, location1, location2, location3)
;
```

##### Map Worker 并发配置

修改每个 Map Worker 的输入数据量，即输入文件的分片大小，从而间接控制每个 Map 阶段下 Worker 的数量

```
SET odps.stage.mapper.split.size=32;
```

##### 数据倾斜
- Join

**MapJoin** - 使用 MAPJOIN 缓存小表
    
```
SELECT /*+ MAPJOIN(B) */ *
FROM A JOIN B
ON A.key = B.key
;
```

**Join 空值** - 给空值随机数
```
SELECT *
FROM A JOIN B
ON COALESCE(A.key, RAND() * 9999) = B.key
;
```

**Join 热点值**
这部分主要要结合业务，大致的思路是：
1. 将热门（热点）值过滤过，放入临时表
2. 在全量数据中排除热门值，定义为非热门值
3. 分别对热门值做维表 JOIN，对非热门值做维表 JOIN
4. 两份数据 UNION ALL 合并

**系统设置**

```
# odps 开启 join 倾斜功能
set odps.sql.skewjoin=true
# 设置倾斜的 key 及对应的值
set odps.sql.skewinfo=skewed_src:(skewed_key) [("skewed_value")]
```

- Group By

**添加随机数，再做一次 group by**
    
```
# 已知长尾 key 为 'long_tails'
SELECT m.key, SUM(m.cnt) AS cnt
FROM (
    SELECT key, COUNT(0) AS cnt
    FROM dual
    GROUP BY key,
    CASE WHEN key = 'long_tails' THEN HASH(RANDOM()) % 50 ELSE 0 END
) m GROUP BY m.key
;
```
    
**系统设置**
    
```
# odps
set odps.sql.groupby.skewindata=true;
    
# hive
hive.groupby.skewindata=true;
```
    
- Distinct

**改成 Group By**
    
```
# 优化前
SELECT COUNT(DISTINCT uid) AS uv
FROM dual
;
    
# 优化后
SELECT COUNT(0) AS uv
FROM (
    SELECT uid
    FROM dual
    GROUP BY uid
) m
;
```
    
优化后的代码转换成了 group by 形式，可以利用 group by 解决长尾的方式优化

##### SEMI & ANTI

JOIN 下的特殊语法，右表只过滤左表的数据，而不出现在最终数据中

**LEFT SEMI JOIN**：如果左表与右表有匹配，则输出数据
**LEFT ANTI JOIN**：如果左表与右表不匹配，则输出数据

##### UNION & INTERSECT & EXCEPT

| 表达式 | 含义 |
| ---- | ---- |
| **UNION ALL** | 多个数据集，合并成一个数据集 |
| **UNION** | 多个数据集，合并成一个数据集并去重 |
| **UNION DISTINCT** | 同上 |
| **INTERSECT ALL** | 多个数据集，取交集 |
| **INTERSECT DISTINCT** | 多个数据集，取交集并去重 |
| **EXCEPT ALL** | 多个数据集，取补集 |
| **MINUS ALL** | 同上 |
| **EXCEPT DISTINCT** | 多个数据集，取补集并去重 |
| **MINUS DISTINCT** | 同上 |

##### 创建视图 View 作为中间表
```
CREATE VIEW IF NOT EXISTS dual_view
(a, b, c)
AS SELECT * FROM dual
;
```

##### 使用 WITH 查询，将结果查询放到内存中
```
WITH result AS (SELECT a FROM dual WHERE a = 'with')
SELECT * FROM (SELECT a FROM result)
```

##### 大数据集的数据抽样

对于数据量特别大的数据集，给定随机数，并且在 MAP 阶段过滤一批随机数，通过 DISTRIBUTE BY 将数据随机 Shuffle 到 Reducer，然后对每个 Reducer 做 Sort By 进行随机排序，最终输出最终需要条数的 10000 条数据（可以通过调整过滤 rand() 的条件来确定数据基数）

```
SELECT *
FROM dual
WHERE rand() < 0.001 
DISTRIBUTE BY rand() SORT BY rand()
LIMIT 10000
```

##### 排序优化 Order By + Sort By

- Order By - 全局排序
- Sort By - Reduce 阶段的局部排序（配合 Distribute By）

```
SELECT m.tn
FROM (
    SELECT RAND() AS tn
    FROM dual
    DISTRIBUTE BY RAND() SORT BY RAND()
) m ORDER BY m.tn
;
```