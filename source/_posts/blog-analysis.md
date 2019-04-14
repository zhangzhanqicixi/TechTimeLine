---
title: 利用 oss 进行博客流量统计
date: 2019-04-14 15:10:15
tags:
---

我的博客是在阿里云上的，一般云厂商的控制台，只能看到服务器的 QPS 等流量情况，如果我想看博客的访问流量情况，并没什么参考意义。我也用卜算子的统计插件在博客里集成总的 Unique Visitor 和 Page View（拉到最下面就能看到），但还是太片面的，有没有什么比较能定制化的博客流量统计方案？

所以之后想到了一个方案，利用阿里云的 OSS 对象存储 + Loghub 日志服务基本可以做到实时的流量统计。

![oss-loghub](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/blog-analysis/oss-loghub.png)

我把 OSS 当作了我博客的资料库，博客里所有提供的图片，视频，下载资源，都放在 OSS 上，不仅省去了我自己维护的麻烦，也帮我省了一大笔存储的费用，而现在利用 OSS + Loghub，还可以帮我统计实时的访问情况了，简直就是一举三得了。

<!--more-->

过程很简单，开通 OSS 之后，在 OSS Console 中开通日志查询，之后就可以去 Loghub 查看你的 OSS 访问日志情况。

OSS 控制台: [https://oss.console.aliyun.com](https://oss.console.aliyun.com)
Loghub Console: [https://sls.console.aliyun.com](https://sls.console.aliyun.com)

使用阿里云的 Loghub 需要会一些简单的 SQL 技巧，我这里举几个例子，如果需要全面学习下，可以看阿里云给出的文档。

[阿里云 Loghub 用户指南 - 查询与分析](https://help.aliyun.com/document_detail/43772.html?spm=a2c4g.11186623.3.3.6dd865d57CzexQ)

##### 最近访问网站的 IP 地址情况分布

![example1](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/blog-analysis/example1.png)

```
* and not client_ip: 100* and client_ip | SELECT * FROM ( SELECT client_ip, referer, ip_to_country(client_ip) AS county, ip_to_province(client_ip) AS province, ip_to_city(client_ip) AS city,date_format(max(__time__), '%Y-%m-%d %H:%i:%S') AS recent_time, COUNT(*) AS visit_count FROM log GROUP BY client_ip, referer ) ORDER BY recent_time DESC
```

阿里云日志服务的 SQL 可以看成分为了两部分，**|** 前面的为查询语法，用来过滤日志，相当于普通 SQL 的 where 之后的条件； **|** 后面的则是分析语法，用来分析日志情况。这点和普通的 SQL 还是略微有点不同。
    
就像
    
```
* and client_ip and not client_ip: 100*  
```
    
表示筛选「存在 client_ip 字段 且 不是为 100 开头的」日志
    
而
    
```
SELECT * FROM ( SELECT client_ip, referer, ip_to_country(client_ip) AS county, ip_to_province(client_ip) AS province, ip_to_city(client_ip) AS city,date_format(max(__time__), '%Y-%m-%d %H:%i:%S') AS recent_time, COUNT(*) AS visit_count FROM log GROUP BY client_ip, referer ) ORDER BY recent_time DESC
```
    

则对筛选出来的日志做了处理，从内层到外层分别表示为：以访问的 IP 地址和博客地址做 group by 分组，将 IP 转成对应的国家、省份、城市，并取最近的访问时间作为 recent_time 字段。最后对 recent_time 做倒排序，将数据输出。
    
最后呈现出来的数据为：
    
![result1](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/blog-analysis/result1.png)
    
    
##### 最近访问博客的用户城市分布

![example2](
https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/blog-analysis/example2.png)

```
    * and not client_ip: 100* and client_ip | SELECT * FROM (SELECT m.province, m.city, SUM(m.logcount) AS logcount FROM (SELECT client_ip, ip_to_country(client_ip) AS country, ip_to_province(client_ip) AS province, ip_to_city(client_ip) AS city, COUNT(DISTINCT client_ip) AS logcount FROM log GROUP BY client_ip) m GROUP BY province, city ) n WHERE n.city NOT LIKE '-1' ORDER  BY logcount DESC LIMIT 10
```
    
和上面的 SQL 大同小异，不同的是这次 group by 的时候并不关注博客地址，只关注了 client_ip，最后出来的数据也只是 client_ip 对应的城市信息。
    
得到数据之后，可以利用 Loghub 自带的「统计图表」，将数据转换成更直观的饼状图，如下图。
    
![result2](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/blog-analysis/result2.png)
    

##### 最近一周的访问博客 UV 趋势

![example3](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/blog-analysis/example3.png)

```
* | SELECT bizday, COUNT(DISTINCT client_ip) AS uv FROM ( SELECT client_ip, bizday FROM ( SELECT client_ip, date_format(__time__, '%Y-%m-%d ') AS bizday FROM log WHERE client_ip IS NOT NULL ) WHERE bizday < current_date ) GROUP BY bizday ORDER BY bizday
```
    
这次以日期作为 group by 的对象，统计一周内的网站访问量的情况，并对 client_ip 进行 distinct 去重，得到访问博客的人数（这里的访问人数也只是大概的情况），然后使用 Loghub 「统计图表」的线图功能，将这一周的访问趋势画出来。就能非常直观的看到博客每天的访问人数情况了。
    
![result3](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/blog-analysis/result3.png)
    

##### Dashboard 仪表盘

做好数据表和图标之后，把这些图标都放到 Loghub Dashboard 内，目的是可以把这些数据和图标整合一下，我的做法是每天让 Dashborad 自动推一封邮件给我，这样我就不用每天登录阿里云，在邮件客户端每天就能看一眼博客的访问流量情况。

![dashboard](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/blog-analysis/dashborad-mail.png)