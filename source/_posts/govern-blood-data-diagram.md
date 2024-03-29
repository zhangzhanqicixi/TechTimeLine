---
title: 全链路数据血缘构建及方案
date: 2022-05-05 16:20:39
tags:
---


在数据治理，模型升级改造等场景中，我们常常需要通过查找上下游的血缘关系为下线、升级做参考，以往我们只能依托计算平台自身的血缘能力，看到计算节点和数据表之间的血缘关系。但只有这些血缘来分析是不够的，基于数据生产链路，需要清楚的知道数据全链路的流转情况。

![overview](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/govern-blood-data-diagram/overview-2.png)


<!--more-->

##### 问题与痛点
基于背景介绍，从数据角度看，需要解决以下两类问题：
- 【缺少各数据生产链路节点的元数据信息】从数据视角看，一方面，我们缺少各个数据库，接口，数据产品之间的元数据信息，导致我们不清楚某张表、接口的访问信息，最近使用情况等统计数据。
- 【缺少全链路的数据血缘信息】有些计算平台，内部虽然有血缘关系，但这些也只是离线数据部分的血缘，上游到计算节点，计算节点到下游的血缘是缺失的。比如我们不知道一张 MySQL表是来自 业务库 还是 binlog 流，也无法知道 OLAP 表流向了 报表 还是 接口。出现问题只能通过 case by case 的一个一个节点排查，效率很低。

而从产品视角看，相当于业务库-计算平台-业务库-接口-数据产品之间的链路，也是缺失的。PD，开发，数据研发之间关注的数据段不同，各自不清楚各自的数据上下游的情况，出现问题排查效率也十分底下，很难建立全链路看问题的视角，识别和解决问题。

##### 全链路血缘价值
全链路血缘要解决最基础的问题就是可以以产品化可视化的形式展现数据从源到端的流转，来满足不同的数据应用场景。

##### 应用场景
###### 助力数据治理和模型改造
- 【推动无访问 / 低访问数据应用下线】有些数据表，已经没有访问量，或者访问量很低，在计算平台中找不到对应下游。但实际可能在跨数据域的其他数据产品中用到了，也可能在 报表 里用到了。如果想要下线，就只能一层层去问问对应的数据开发，产品技术的同学，中间很容易忽略某个链路，导致出现故障。反向来看，有些接口和报表，如果也没有了访问量，通过自动化治理平台告警之后，可以找到对应的上游表，并且在通知对应的数据研发以及 PD，关注是否可以下线
- 【数据应用成本分摊】一些报表，上游依赖的 Hive 表，计算量大，存储高。但是业务价值不明显，看数人员较少。通过全链路的血缘关系以及成本分摊算法（这块后面单独会写文章介绍），可以把上游 Hive 的成本分摊至下游报表，让相关同学可以预估该报表的 ROI，如果 ROI 较低，则可以推动下线无效报表
- 【模型改造】在模型改造过程中，往下游看，如果我对这张表做了修改，会影响下游哪些应用，哪些节点。往上游看，可以观察到是否依赖了过多层级，是否有依赖不合理的表等。

###### 提高用数效率，减少答疑成本
- 【提升取数效率】在报表使用过程中，如果需要找到某个指标的数据底表，当下需要先问页面负责 PD，PD 再转交给对应的数据研发，数据研发再去查找对应的表给到用数人，整条链路效率底下，答疑成本高
- 【降低数据排查成本】在数据接口调用过程中，如果发现接口数据异常，需要排查问题，当下也只能通过一层层往上问对应的前端接口负责人-数据接口负责人-数据表负责人，最后再由对应的同学来查看问题

##### 解决方案
整体方案分为三层建设，数据层，能力层，应用层；
数据层作为整个项目的基础能力，负责建立和管理数据基础及各类数据源元数据及上下游血缘。
能力层包含建立标签体系，图检索，成本分析及模型治理等
应用层主要基于业务场景，在能力层的基础上，为不同业务场景提供血缘方案。

聚焦数据层，我们主要需要收集数据流转过程中，各个数据源的元数据信息及上下游血缘，并设计通用模型方案。

各数据源元数据及血缘关系，需要根据不同的业务场景自行收集，相当于从 DB-大数据计算平台-DB-数据产品 这条链路上的所有数据源元数据及血缘，都要进行沉淀，处理，开发成通用的血缘数据，那么如何承接这批数据，使这些不同来源的数据的都用统一的数据格式存储，而且也方便易于后续的扩展。所以这里主要介绍全链路血缘数据层的基础模型方案。

整个全链路血缘中的数据源可抽象成 实体（entity），设计了记录元数据及血缘的模型表：实体表、关系表

表名：
表描述：实体表

| 字段中文名称 | 字段英文名称 | 类型 | 备注 |
| :---: | :---: | :---: | :---: |
| 实体 id | entity_id | STRING | 唯一 id，odps.project.table.column |
| 实体类型 | entity_type | STRING | 枚举的实体类型，1-库，2-表，3-字段，4-节点，5-数据集
| 属性 | arrtibutes | STRING | 当前实体的相关属性，json

表名：
表描述：关系表

| 字段中文名称 | 字段英文名称 | 类型 | 备注 |
| :---: | :---: | :---: | :---: |
| 输入实体 id | input_entity_id | STRING | 唯一 id，odps.project.table.column |
| 输出实体 id | output_entity_id | STRING | 唯一 id，odps.project.table.column
| 关系类型 | relation_type | STRING | 关系类型，0-root作为输入，1-表表关系

##### 产品效果图

核心能力是可查询全链路血缘关系，从 DB - 大数据计算平台 - 业务工作台，相当于把技术 - 数据 - 业务三方串联了起来，提供从源到端全链路血缘的查询，提高找数、取数效率，降低排查成本，产品非敏感数据部分展示（仅做演示记录用）：

![产品效果图](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/govern-blood-data-diagram/overview.jpg)


扩展能力是成本分析，量化业务产品每一款产品的数据成本，并结合访问情况计算 ROI，这块的数据比较敏感，不作展示。