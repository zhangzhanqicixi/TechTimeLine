---
title: SQL 入门指导片（2） - 条件筛选
date: 2021-10-01 17:33:39
tags:
---

条件筛选这一个 Part，主要介绍三种情况：
1. 行级 WHERE 条件的筛选
2. 列级的 IF-ELSE 条件分组筛选
3. 列级的 CASE-WHEN 条件分组筛选

<!--more-->

##### 数据准备
还是一样的数据集

| user_id | gender | school | birthday | pay_amt | last_login_time |
| :---: | :---: | :---: | :---: | :---: | :---: |
| 1 | 男 | 北京大学 | 1992-01-01 | 34.1 | 2021-08-01 18:23:48|
| 2 | 女 | 北京大学 | 1994-02-06 | 15.54 | 2021-05-23 12:54:00|
| 3 | 男 | 北京大学 | 1992-08-12 | 76.87 | 2021-06-15 13:32:03|
| 4 | 男 | 北京大学 | 1990-12-21 | 97.12 | 2020-11-30 05:23:16|
| 5 | 女 | 清华大学 | 1993-02-17 | 12.16 | 2021-03-30 20:51:57|
| 6 | 女 | 清华大学 | 1996-05-13 | 54.65 | 2021-02-01 23:12:48|
| 7 | 女 | 清华大学 | 1997-08-18 | 76.87 | 2021-08-30 14:17:43|
| 8 | 男 | 清华大学 | 1998-09-04 | 98.93 | 2021-09-30 19:25:34|
| 9 | 女 | 浙江大学 | 1991-11-09 | 12.32 | 2021-08-01 09:29:46|
| 10 | 男 | 浙江大学 | 1993-01-17 | 5.58 | 2021-08-01 11:32:27|

##### 行的筛选条件
如果我们需要对筛选的数据增加条件，比如我们需要筛选出学校是「北京大学」的所有列数据，那么我们就可以用 SQL：
```
SELECT * FROM s_user_info WHERE school = '北京大学'
```
或者也可以用：
```
SELECT * FROM s_user_info WHERE school LIKE '北京大学'
```

> 两者的区别后面再说，先不用纠结

我们就可以得到数据集：

| user_id | gender | school | birthday | pay_amt | last_login_time |
| :---: | :---: | :---: | :---: | :---: | :---: |
| 1 | 男 | 北京大学 | 1992-01-01 | 34.1 | 2021-08-01 18:23:48|
| 2 | 女 | 北京大学 | 1994-02-06 | 15.54 | 2021-05-23 12:54:00|
| 3 | 男 | 北京大学 | 1992-08-12 | 76.87 | 2021-06-15 13:32:03|
| 4 | 男 | 北京大学 | 1990-12-21 | 97.12 | 2020-11-30 05:23:16|

再比如我们需要筛选出支付金额大于等于 50.00 的数据，那么我们也可以用 SQL：
```
SELECT * FROM s_user_info WHERE pay_amt >= 50.00;
```
这样我们就可以得到数据集：

| user_id | gender | school | birthday | pay_amt | last_login_time |
| :---: | :---: | :---: | :---: | :---: | :---: |
| 3 | 男 | 北京大学 | 1992-08-12 | 76.87 | 2021-06-15 13:32:03 |
| 4 | 男 | 北京大学 | 1990-12-21 | 97.12 | 2020-11-30 05:23:16 |
| 6 | 女 | 清华大学 | 1996-05-13 | 54.65 | 2021-02-01 23:12:48 |
| 7 | 女 | 清华大学 | 1997-08-18 | 76.87 | 2021-08-30 14:17:43 |
| 8 | 男 | 清华大学 | 1998-09-04 | 98.93 | 2021-09-30 19:25:34 |

这是最基本的两个用法，另外 WHERE 字句支持很多逻辑上的操作，比如：

| 操作 | 条件说明 | 示例 | 含义 |
| :---: | :---: | :---: | :---: |
| =, !=, <>, <, <=, >, >= | 逻辑操作 | pay_amt >= 50.00, user_id <> 3 | 支付金额大于 50 元，用户编码不等于 3（和 user_id != 3 含义相同）
| BETWEEN...AND | 数字范围 | pay_amt BETWEEN 50.00 AND 70.00 | 支付金额在 50-70 元之间
| IN | 列表范围 | school IN ('清华大学', '北京大学') | 学校在清华大学和北京大学范围内的
| LIKE | 内容搜索匹配 | birthday LIKE '1992%' | 生日是 1992 年开头的 |

几个示例：
```
# 取性别是男生，支付金额大于 50.00 元的数据
SELECT  * 
FROM    s_user_info 
WHERE   gender LIKE '男' 
AND     pay_amt > 50.00;
```

| user_id | gender | school | birthday | pay_amt | last_login_time |
| :---: | :---: | :---: | :---: | :---: | :---: |
| 3 | 男 | 北京大学 | 1992-08-12 | 76.87 | 2021-06-15 13:32:03|
| 4 | 男 | 北京大学 | 1990-12-21 | 97.12 | 2020-11-30 05:23:16|
| 8 | 男 | 清华大学 | 1998-09-04 | 98.93 | 2021-09-30 19:25:34|

```
# 取学校是清华大学和北京大学，生日在 1994-01-01 到 1994-12-31 之间的数据
SELECT  * 
FROM    s_user_info 
WHERE   school IN ('清华大学', '北京大学') 
AND     birthday BETWEEN '1994-01-01' AND '1994-12-31'
```
| user_id | gender | school | birthday | pay_amt | last_login_time |
| :---: | :---: | :---: | :---: | :---: | :---: |
| 2 | 女 | 北京大学 | 1994-02-06 | 15.54 | 2021-05-23 12:54:00 |

##### 列的分组条件
假设现在有个需求，我们要在现有的数据集列的基础上，新增一列名为「消费等级」的字段，字段的英文名定义为 `pay_level`，口径为：如果一个用户的支付金额 >= 50 元，则认为这个用户是「高消费」用户，反之则为「低消费」用户。
那么，我们的数据集应该就变成了：

| user_id | gender | school | birthday | pay_amt | last_login_time | pay_level |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| 1 | 男 | 北京大学 | 1992-01-01 | 34.1 | 2021-08-01 18:23:48| 低消费 |
| 2 | 女 | 北京大学 | 1994-02-06 | 15.54 | 2021-05-23 12:54:00| 低消费 |
| 3 | 男 | 北京大学 | 1992-08-12 | 76.87 | 2021-06-15 13:32:03| 高消费 |
| 4 | 男 | 北京大学 | 1990-12-21 | 97.12 | 2020-11-30 05:23:16| 高消费 |
| 5 | 女 | 清华大学 | 1993-02-17 | 12.16 | 2021-03-30 20:51:57| 低消费 |
| 6 | 女 | 清华大学 | 1996-05-13 | 54.65 | 2021-02-01 23:12:48| 高消费 |
| 7 | 女 | 清华大学 | 1997-08-18 | 76.87 | 2021-08-30 14:17:43| 高消费 |
| 8 | 男 | 清华大学 | 1998-09-04 | 98.93 | 2021-09-30 19:25:34| 高消费 |
| 9 | 女 | 浙江大学 | 1991-11-09 | 12.32 | 2021-08-01 09:29:46| 低消费 |
| 10 | 男 | 浙江大学 | 1993-01-17 | 5.58 | 2021-08-01 11:32:27| 低消费 |

那么问题来了，我们怎么通过 SQL 来新增这一列，答案是可以通过 IF-ELSE 的形式，SQL 代码如下：

```
SELECT  user_id
    , gender
    , school
    , birthday
    , pay_amt
    , last_login_time
    , pay_level
    , IF ( pay_amt >= 50.00, '高消费', '低消费') AS pay_level
FROM    s_user_info
;
```

> 上面的 `AS` 表示对这个字段取了个名字，令这个字段叫做 `pay_level`

IF 函数的语法：
```
IF( 条件，条件满足时返回的值，条件不满足时返回的值 )
```

接下来，我们学习另一个分组筛选的函数，CASE-WHEN，还是举个例子，假设我们要选出每个用户出生年代，用字段 `birth_year` 表示，定义分为三档，名称及口径分别是：
- 90年代初：1990-1993年出生的
- 90年代中：1994-1996年出生的
- 90年代末：1997-1999年出生的

那么上面的数据集就会变为：

| user_id | gender | school | birthday | pay_amt | last_login_time | pay_level | birth_year |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| 1 | 男 | 北京大学 | 1992-01-01 | 34.1 | 2021-08-01 18:23:48| 低消费 | 90年代初 |
| 2 | 女 | 北京大学 | 1994-02-06 | 15.54 | 2021-05-23 12:54:00| 低消费 | 90年代中 |
| 3 | 男 | 北京大学 | 1992-08-12 | 76.87 | 2021-06-15 13:32:03| 高消费 | 90年代初 |
| 4 | 男 | 北京大学 | 1990-12-21 | 97.12 | 2020-11-30 05:23:16| 高消费 | 90年代初 |
| 5 | 女 | 清华大学 | 1993-02-17 | 12.16 | 2021-03-30 20:51:57| 低消费 | 90年代初 |
| 6 | 女 | 清华大学 | 1996-05-13 | 54.65 | 2021-02-01 23:12:48| 高消费 | 90年代中 |
| 7 | 女 | 清华大学 | 1997-08-18 | 76.87 | 2021-08-30 14:17:43| 高消费 | 90年代末 |
| 8 | 男 | 清华大学 | 1998-09-04 | 98.93 | 2021-09-30 19:25:34| 高消费 | 90年代末 |
| 9 | 女 | 浙江大学 | 1991-11-09 | 12.32 | 2021-08-01 09:29:46| 低消费 | 90年代初 |
| 10 | 男 | 浙江大学 | 1993-01-17 | 5.58 | 2021-08-01 11:32:27| 低消费 | 90年代初 |

针对这一列，我们就可以用下面的 SQL 来实现：
```
SELECT  user_id
    , gender
    , school
    , birthday
    , pay_amt
    , last_login_time
    , pay_level
    , IF ( pay_amt >= 50.00, '高消费', '低消费') AS pay_level
    , CASE WHEN birthday >= '1990-01-01' AND birthday <= '1993-12-31' THEN '90年代初'
        WHEN birthday >= '1994-01-01' AND birthday <= '1996-12-31' THEN '90年代中'
        WHEN birthday >= '1997-01-01' AND birthday <= '1999-12-31' THEN '90年代末' END             AS birth_year
FROM    s_user_info
;
```

CASE-WHEN 语法：

```
CASE WHEN 条件1 THEN 结果1
    WHEN 条件2 THEN 结果2
    WHEN 条件3 THEN 结果3
    ELSE 结果4
END
```
> 注意 CASE WHEN 的语法中，可以没有 `ELSE` 的条件，但是一定要有 `END` 作为结尾。