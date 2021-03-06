---
title: 出租房内「网络架构」设计与「智能家居」场景应用
date: 2020-10-10 11:01:20
tags:
---

年初的时候升级了家里的网络，捣鼓了软路由 + 硬路由的各种组合方式，又在全屋范围内升级了一系列的智能家居，故来记录一下

> 由于目前还是租房狗，所以活动范围也只有一个主卧的大小，单路由已经可以完全覆盖，所以目前没有设计无线 AP 或 Mesh 网络。

##### 网络拓扑
目前房间内的整体网络拓扑图如下图：

![home-topology](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/meshworkarch-aihome-in-rentalhome/home-topology.png)

<!--more-->

**网路入口**为公寓的公共路由器，为软路由作为入户的**主路由**，负责整体流量的进出，千兆路由器通过有线 AP Bridge 作为主路由的**旁路由**，用于发射 WiFi 信号和 LAN 口扩展（小型交换机）。

而各个终端设备我分为三类管理：

- 屋内支持网线的设备，如 Nas，电视，PC 等，通过网线连接至「主路由」或「旁路由」的 LAN 口
- 屋内的无线设置则通过无线路由器
- 屋内的智能家居通过智能家居网关统一管理，由智能家居网关负责对各类插座、灯泡、电器的控制，目前支持 HomeKit 和 MiHome 两种协议。

##### 软路由
软路由我选择的型号为 J1900，是淘宝上比较入门的型号，默认安装了 KoolShare LEDE 系统，配置可看下图，虽然配置比较低，但是相比普通路由器，这个配置可以说是相当高了。

我对软路由的需求有两个：
1. 作为出入关网的主路由
2. 作为分流设备翻墙

> 软路由应作为「主路由」还是「旁路由」的选择，我也纠结了一会儿，最终还是把它作为了「主路由」。一方面我自己不太会折腾软路由，另一方面我的硬路由只是入门级的千兆路由器，配置也不是很好。

![j1900](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/meshworkarch-aihome-in-rentalhome/j1900.png)

关于软路由的初始化，网上有很多教程，我就不班门弄斧了。但是有一点可以注意一下，当第一次设置 WAN 口和 LAN 口之后，需要注意一下在「防火墙 」-「常规设置」页面中的「覆盖的网络」这一栏，如果默认为空的话，很可能目前你上不了网，需要将覆盖的网络设置成你的 WAN 口。

![firewall](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/meshworkarch-aihome-in-rentalhome/firewall-openwrt.png)

##### 硬路由
硬路由其实就是普通的家用千兆路由器，在当前场景下，硬路由的作用有：
1. 作为小型交换机，扩展 LAN 口
2. 提供 WiFi 信号

软路由设置好可上网后，我们可以用软路由的 LAN 口连接硬路由器的 LAN 口，然后进入硬路由的设置页面，将上网模式设置成 AP 桥接模式（AP Bridge）。

这样对于硬路由而言，它不再提供上网的服务，而只是作为流量的中间站，将它接收到的流量，转发到前段的软路由，由软路由统一做上网处理。

##### 智能家居
由于是出租房，智能家居还是比较简单的阶段，从设备上看，我只买了三大类：插座，灯泡，传感器。有了这三类设备，可以基本自动化的控制家里的设备，比如：
智能插座 + 热水器 ===> 智能热水器；
智能插座 + 除湿器 ===> 智能除湿器；
吊灯换成 Yeelight 灯泡 ===> 智能吊灯；
… >_<

![homekit](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/meshworkarch-aihome-in-rentalhome/homekit-aihome-1.png)

设备多了之后，就可以个性化很多自己的场景，比如：

- 湿度传感器 + 除湿器 + 智能插座：当室内湿度大于 65%，则打开除湿器。
- 如果再加入「门窗传感器」，就可以进一步加入判断条件：当室内湿度大于 65% 且门窗都是关闭状态，则打开除湿器。
- 如果只想出门的时候进行除湿，还可以加入：当室内湿度大于 65% 且门窗都是关闭状态且我的定位不在家的范围内，则打开除湿器。

类似地还可以设置很多场景，这里就不一一概述了。

