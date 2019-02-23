---
title: 针对中国大陆的 Apple TV 最佳配置教程 
date: 2019-02-23 16:27:17
tags:
---

![cover](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/introduction-of-apple-tv/device.jpg)

入手 Apple TV 也有一段时间了，基本搞清楚了这东西在中国使用的门道，写这篇文章的原因也是因为想在中国完整的和全面的体验 Apple TV，是需要有不少技术和金钱成本的。

<!--more-->

##### Apple TV

![hdr](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/introduction-of-apple-tv/hdr.jpeg)

Apple TV 其实和普通的电视盒子一样，都是用来浏览互联网上的资源的，只不过里面预装了 Apple 的 tvOS，所以从体验上来讲很有苹果的味道。

使用 Apple TV，完全不推荐使用中国大陆的 Apple ID，如果使用中国的 Apple ID，进入 Apple TV 之后会发现什么都没有，我长期使用美区的 Apple ID，资源相对来说是最全面。



第一次使用 Apple TV 或恢复出厂设置时，Apple TV 会提醒你是否需要登录 Apple ID，登录之后，你就不需要设置 Wifi，iCloud 等这些配置，Apple TV 会直接拉取你在 iCloud 上的配置。

![setup](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/introduction-of-apple-tv/setup.png)

当使用 Apple TV 需要输入文字时，你的手机上马上会显示 Apple TV 输入框，只要你的手机上输入，电视上就会同步显示。上面两点相对 Android 的电视盒子，对用户的体验方便的不是一点半点。



##### 硬件支持

因为 Apple TV 本质只是一个电视盒子，所以还需要一些硬件支持，我准备了以下的硬件。

- 4K HDR 电视机
- High-Speed 2.0 HDMI
- Nas
- 千兆路由器

![setup](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/introduction-of-apple-tv/cover.jpg)

为了观影体验，我入手了一台 Sony KD-43X8500F HDR，虽然我暂时没有看出 HDR 和 UHD 的在这台电视上的显示区别，但是听网上那么多人吹 HDR，我想买了总没错的。

Apple TV 只支持 HDMI 视音频输出，如果你的电视机是 4K 的，还必须使用 HDMI 2.0 的高速线缆，苹果官网有贝尔金的 HDMI 线缆，但是价格很感人，我记得是 236 元。我自己淘宝买了一根 68 元的 0.5 米线缆，至今没出什么问题。

在 Apple TV 上，有时候常见的流媒体正版资源无法满足你，这是就需要去下载一些资源。比如想看一部电影，在电脑上，我的习惯是直接下载一部盗版电影，在电脑上看完之后就删除（因为我的硬盘只有 256G）。但是在 Apple TV 上，由于有很多软件能自动支持电影海报和字幕的加载（下面会介绍），所以我更愿意看完之后就放在硬盘里，逐渐搭建自己的影音库。这样一来需要一台 Nas 就不可避免了，由于我买 Nas 的目的并不是为了备份资料（我的资料都是云上），只是用于存电影和电视剧。所以我买了群晖的最基础的 DS118 + SEAGATE 4TB，体验了 2 周之后，感觉还是很不错的。

![nas](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/introduction-of-apple-tv/ds118.jpg)

##### 网络环境

Apple TV 上最常用的基本上都是美国的流媒体软件，比如 YouTube，Netflix，虽然也有 CNN，HBO 这类本土的可选，但是这些基本都实行了锁区的限制，由于我对新闻类的应用也没有多少兴趣，也没有去折腾下去。另外，用美区的 Apple ID，是找不到爱奇艺，优酷这些国内的流媒体软件的，但是听说香港区的 Apple ID 可以。

所以能正常使用这些流媒体软件还要有个境外的服务器做支撑，来处理 Apple TV 的流量，但是 Apple tvOS 上的 App Store 并没有代理软件的客户端，网上比较通用的方法是让你的路由器作为客户端去加密你的请求流量，转发到你的服务器来进行翻墙。
这样的做法简单粗暴，但是能够刷梅林系统的路由器基本都要大几百，而且我个人并不喜欢在路由器层面去加密这些流量。一方面很容易将不需要翻墙的流量也去走代理服务器，浪费带宽和增加延迟；另一方面如果有一天你的代理服务器被 ban，你就需要登录路由器改配置，太麻烦。

所以我使用了另一种方法，将一台闲置电脑作为网关，使 Apple TV 的流量都走到该电脑上，在电脑端加密 Apple TV 的请求，然后转发境外服务器。

在 macOS 上将 Mac 设置成网关最简单的方法是使用 Surge ，点击「增强模式」即可；之后你只需要进入 Apple TV 网络设置界面，点击手动配置，更改路由器地址为你的 Mac 的 IP 地址，将 DNS 地址更改为 198.18.0.2，之后 Surge 上就能看到来自 Apple TV 的流量了。

![surge](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/introduction-of-apple-tv/surge.png)

解决了自由浏览互联网内容的问题，接下来是内网环境下流畅看 Nas 上资源的问题。由于买了 Nas，而且毕竟是支持 4K 的 Apple TV 和电视机，想体验一下 4K 影片的欲望必不可少。互联网流媒体上的 4K 资源，由于是服务商压缩过的资源，所以只要你的带宽到了 30 Mbps 以上，就可以流畅观看了。但是很多下载到 Nas 上的资源，基本都是没有压缩过的，即使你的内网带宽达到 100 Mbps，也无法流畅的看，我就是因为家里的路由器还是百兆的路由器，导致内网传视频特别变，而且带宽很容易跑满。所以一台千兆的路由器还是必不可少。对了，购买了千兆路由器之后，不要忘了把你的网线也全部换成六类线。

![bandwidth](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/introduction-of-apple-tv/bandwith.png)

关于 4K 资源在服务端还是客户端解码的问题，这个还是看你用的播放软件，我的答案是由于 Apple TV 性能还是不错的，所以我都会选择在客户端解码，实际体验下来也是不错的。另一个原因是 DS 118 的性能还是比较差的。

##### 软件支持

- Youtube
- Netflix
- Infuse
- Plex

前两个最常用的流媒体软件不说了，而 Infuse 据说是 tvOS 上最好用的播放器，能自动识别 Nas 上的资源，自动下载海报，并且可以显示电影的简介和 IMDB 得分等等。实际使用下来，基本可以识别 95% 上的海报，如果有些没识别，还可以手动下载海报，命名 Folder.jpg，放在该电影的母文件夹下即可。

![infuse-1](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/introduction-of-apple-tv/infuse-1.jpg)

![infuse-2](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/introduction-of-apple-tv/infuse-2.jpg)

Plex 我还没用过，听说特点是可以支持流式播放和共享，具体等我有机会体验之后再来评价，目前来说 Infuse 已经满足了我的需求。
