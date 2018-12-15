---
title: 如何在国内看 Netflix 及搭建优质线路
date: 2018-12-15 16:53:28
tags: 
---

![netflix](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/tutorial-of-visit-netflix-in-china/netflix.png)

最近想看美剧，但不想做去搜索引擎搜美剧下载，再拷贝到设备上看这么复杂的操作。发现大部分想看的美剧都在 [Netflix](https://www.netflix.com/browse) 上有提供，所以尝试注册订阅了 Netflix，但操作两天下来发现想要在国内看并非是一件容易的事情，所以记录下整个的过程。

<!--more-->

##### Netflix 套餐
Netflix 提供三种套餐，如下图，只要标准及以上的套餐提供 HD 模式（1080P），所以我就选择了标准套餐。
注册好账号，绑定 Paypal 或信用卡（首月免费），就可以进入 Netflix 了。

本教程主要介绍如果使用代理访问 Netflix，其他基础的教程可以参考 [在中国看 Netflix，看这一篇就够了](https://digitalimmigrant.org/16) 这篇博客，介绍的很清楚。

![订阅服务](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/tutorial-of-visit-netflix-in-china/subscribe.png)

##### 代理服务

中国大陆的网络是无法直接访问 Netflix 的，需要代理访问，但 Aliyun, GCP 等知名大厂的服务器作为代理，可以访问但看不了剧，原因是 Netflix 自身维护了一个巨大的 IP 库黑名单，里面维护了几乎所有 VPS 大厂的 IP 段。所以我们就需要找一个没有被 Netflix 屏蔽 IP 段的 VPS 厂商。

![proxy](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/tutorial-of-visit-netflix-in-china/proxyban.png)

> 刚开始我还想过通过抓包分析请求头重写或者直接 reject 某些验证请求了，暂时都不行。（可能也是我还没分析到位）


##### 问题和优化

之后我选择了一家新加坡本地 VPS 服务商，不说名字了，因为他们没给我钱让我广告，需要看看的可以点 [这里](https://usonyx.net) ，我选了 Lite 配置是 2U / 20G SSD / 2G Memory / 每个月 2TB 流量 / 100Mbps 的带宽 ，5 新币 / 月，配置价格还算公道，至少比阿里云划算，实测下来带宽在 100Mbps - 200Mbps 左右。

![usonyx](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/tutorial-of-visit-netflix-in-china/usonyx.png)

![speedtest-cli](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/tutorial-of-visit-netflix-in-china/vps-speedtest-cli.png)

比较坑的是如果运营商是中国电信，从中国大陆直连，速度就非常慢，ping 基本在 200ms 以上，而且使用 Netflix 官方测速工具 [fast.com](https://fast.com ) ，速度仅在 200Kbps 上下，这种速度是没法看 Netflix 的。

- 本地网络直连 VPS 后访问 Netflix 速度
![fast](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/tutorial-of-visit-netflix-in-china/fast-local.png)

- 本地网络 ping 新加坡本地 VPS
![pingvps](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/tutorial-of-visit-netflix-in-china/pingvps.png)

相比之下，我在阿里云国际版中新加坡区的 ECS，延迟就小了很多，ping 几乎能到 100ms 以下，速度也基本能跑满（默认是 30Mbps），我对 4K 也没有需求，所以对我来说肯定够用了。

- 本地网络 ping 新加坡 Aliyun ECS
![pingecs](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/tutorial-of-visit-netflix-in-china/pingecs.png)

但为什么会这样呢？查了下原因，发现中国电信运营商下的国际线路中，阿里云新加坡区走的是电信提供的比较优质的 CN2 线路，而一般的 VPS 厂商，走的是电信普通线路，所以速度和延迟可想而知了。。

那么怎么解决呢？我想到的是，由于 Aliyun 新加坡的服务器和新加坡本地 VPS 服务器之间，基本没有延迟的特性（1ms - 2ms），所以可以直接访问 Aliyun , 通过 HAProxy 转发整个请求包，将请求转发到坡县本地的 VPS 服务器上，这样的话延迟下降到 100ms，访问   速度也将上升到 Aliyun ECS 的速度；

- 新加坡服务器之间互 ping
![ecspingvps](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/tutorial-of-visit-netflix-in-china/ecspingvps.png)

- 普通线路访问
![flowchart](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/tutorial-of-visit-netflix-in-china/flowchat.png)

- 用阿里云 CN2 线路作为中继
![flowchart-cn2](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/tutorial-of-visit-netflix-in-china/flowchat-cn2.png)


#####  HAProxy
阿里云 ECS 转发请求的 HAProxy，过程很简单，首先安装 HAProxy
```
    # Debian / Ubuntu系统：
    apt-get -y install haproxy
    
    # Centos系统：
    yum -y install haproxy
```

设置配置文件

```
[root@izt4nezkmfgg9s05ik5l67z ~]# vim /etc/haproxy/haproxy.cfg
```

```
global

defaults
    log global
    mode    tcp
    option  dontlognull
        timeout connect 5000
        timeout client  50000
        timeout server  50000

frontend ss-in
    bind *:5259
    default_backend ss-out

backend ss-out
    server server1 127.0.0.1 maxconn 20480
        
```
上面内容复制到 haproxy.cfg 之后，将 127.0.0.1 设置成你的 ss 的 IP 地址，将 5259 端口设置成你的 ss 的端口；

启动服务
```
systemctl start haproxy
systemctl enable haproxy
```

##### 测试
增加了 Aliyun 作为中继转发之后，基本可以做到无等待看 Netflix 了。再次测速，可以跑满 Aliyun ECS 的带宽。

![fast](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/tutorial-of-visit-netflix-in-china/fast-aliyun.png)

##### 总结

简单来说，如果你在中国看 Netflix，大概需要以下的工具（产品）
- 海外信用卡 - 海外 VPS 厂商，Netflix
- PayPal - Netflix， 阿里云国际
- 支持 CN2 路线的服务器 - 确保国内访问海外服务器速度
- 没有被 Netflix 拉黑的服务器 - 直连 Netflix 服务器
- HAProxy 和 Shadowsocks 配置