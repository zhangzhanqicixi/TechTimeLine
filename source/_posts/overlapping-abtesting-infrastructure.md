---
title: A/B Testing 多实验分层重叠方案
date: 2020-06-24 14:57:39
tags:
---

在算法开发中必然会有 A/B 测试，通常可以简单的根据用户 ID 或 Cookie 去切割流量，实现让不同的用户走不同的算法，最后回溯数据评估效果。随着业务越来越多，通过该方案单纯的切割流量进行测试，会造成流量饥饿与流量偏置等问题。本文章记录一下 A/B Testing 中比较流行的多层重叠方案。

<!--more-->

##### 单层 A/B Testing
![single-layer](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/overlapping-abtesting-infrastructure/FA742619-6B7F-4646-B2FE-12DA9EBCB0B9.png)
单层的 A/B 测试方案比较简单，有几个实验，就切分几份流量，比如现在线上需要同时测试排序模块的算法 A和B，推荐模块的算法 A和B，我们就可以把流量分切成 4 份，每份都有 25% 的流量，但这样做会造成两个重要的问题：
-  **流量饥饿**
如果流量本身基数不大，25% 的流量不足以有足够的置信度来评估算法，通常就需要加大流量来提高测试的置信度，但一组实验流量加大，必然会造成其他组实验无法得到充足的流量，造成流量饥饿。
比如，测试实验A，实验B算法，每组共需要 80% 的流量的情况；实验C，实验D每组只能使用剩下的 20% 流量，使结果同样不具有统计意义。
-  **流量偏置**
产品的逻辑线往往既有并线也有串线，就像上面的例子，排序算法和召回算法，都能影响最终的推荐效果。用户请求过来，我需要同时去请求排序算法中的一组实验和召回算法中的一组实验，如何保证测排序实验的结果没有被召回实验影响，反之亦然，这就是流量偏置问题。

#### 设计目标
针对上面的几个问题，我们提出几个 A/B Testing 多实验组测试时需要解决的几个目标：
- 支持多个实验组同时测试
- 多个实验组流量互相独立
- 每组实验确保能得到 100% 的流量

##### 多层重叠 A/B Testing
![muti-layer](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/overlapping-abtesting-infrastructure/B523EA6B-5B94-413F-86ED-99D22402FD5D.png)
 **流量域、流量层、流量桶**
该方案最早由 Google 在 2010 年 KDD 上公布，如上图所示，将整个实验空间进行横向和纵向划分。纵向上，我们定义「域 Domain」 的概念，流量线进行 Domain 域的判断，进入不同的 Domain 域中；横向上，我们定义「层 Layer」的概念，在同一层中进行一类的实验，每类实验根据实验数量不同，又可以切分成 N 个「桶 Bucket」，*流量在每个层都会被重新打散*。

比如在上图中，「实验1A」、「实验1B」、「实验3B」… 就是一个个流量「桶 Bucket」；「实验 2A」 + 「实验 2B」 组成一个 「流量层 Layer」，我一般也称为「实验组」；最外层的「实验组1-4」或 「独立流量域」 组成一个大的 「域 Domain」。

 **流量分配函数**
流量在每层都会被重新打散，保证每层的流量都是来自上层每个桶且随机而均匀。这种打散的方法叫做「分配函数」，我们简单定义了两种分配函数的情况，一种是基于用户 Id + Layer 的函数，一种是基于用户 Id + Bizdate + Later 的函数，这里的 N 表示你要区分的桶数，根据业务需要决定是否需要加入时间因子。
```
user_id_layer_mods = F(user_id, layer) % N
user_id_bizdate_layer_mods = F(user_id, bizdate, layer) % N
```

但是，论文并没有说出公式的 F 具体怎么实现，如果单纯加减，会存在流量切分不均匀的问题。后续经过实验，下面这个逻辑，可以均匀切分，已经过证明。

> 证明过程就不放上来了，其实就是单纯看了 N 个样本集统计，如果你可以很好的证明下面的公式可以均分流量，欢迎留言告诉我

```
def get_bucket_no(account, bucket_pi, layer_bucket_cnt):
    """
    :param account: 用户 id 或其他 id
    :param bucket_pi: 上层layer桶数的累乘
    :param layer_bucket_cnt: 当前实验组桶数
    :return: 当前实验组的桶号
    """
    return hash(account / bucket_pi) % layer_bucket_cnt
```

下图展示了 Google 的论文中判断用户进入域，层，桶的判断罗技
![google-infrastructure](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/overlapping-abtesting-infrastructure/76F5BDB9-5148-488C-A132-B897FA42DBD1.png)

##### 总结
这一套 A/B Testing 方案在工业界也算是比较通用的方案，理解起来也不是很困难，应用场景也比较广泛，不止算法测试，UI、功能、运营策略上都可以应用到这套方案，并且在大厂中，已经对该方案进行了产品化，做到了可配置和热更新。最后按我个人的理解再总结一下几点特性：

- 横向分层，流量重叠
每层都有 100% 的流量
分割流量策略可以不同
分层策略可以不同（可以是算法对照组，可以是运营策略对照组）
- 纵向分流，流量分配
流量可以进入不同域
流量切割分配函数

##### reference

1. [Overlapping Experiment Infrastructure](https://storage.googleapis.com/pub-tools-public-publication-data/pdf/36500.pdf)
2. [你的AB测试平台和方案，真的可靠么？](https://uxren.cn/?p=58841)