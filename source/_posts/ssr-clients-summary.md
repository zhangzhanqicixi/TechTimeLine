---
title: ShadowsocksR 各平台下载地址及使用方法
date: 2018-08-15 10:01:37
tags:
---

> 你在有了 IP，端口，加密方式，密码 之后，还需要一个「梯子」才能连接到墙外

这一类的软件每个平台下很多，这里提供各平台开源，免费的软件一览

##### 各平台工具汇总
platform | clients | official | oss | remark
--- | --- | --- | --- | ---
Windows | shadowsocks-win | [GitHub](https://github.com/shadowsocks/shadowsocks-windows/releases) | [OSS](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/ssr-clients/Shadowsocks-2.exe) | 国内用户直接点击 OSS 下载
Mac OS X | ShadowsocksX-NG | [GitHub](https://github.com/shadowsocks/ShadowsocksX-NG/releases) | [OSS](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/ssr-clients/ShadowsocksX-NG.app.zip) | 国内用户直接点击 OSS 下载
Android | shadowsocks-android | [Google Play](https://play.google.com/store/apps/details?id=com.github.shadowsocks) | [OSS](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/ssr-clients/Shadowsocks.apk) | 国内用户直接点击 OSS 下载
iOS | Phtatso Lite | [App Store](https://itunes.apple.com/us/app/wingy-http-s-socks5-proxy-utility/id1178584911) | 无 | 中国区 Apple ID 是无法搜到 SSR 的 APP 的。如果你没有非中国大陆区的 Apple ID，可参考我的另一篇 [Blog](https://blog.timeline229.com/transfer-appleid-to-us/) 进行转区，或联系[我](mailto:zhangzhanqicixi@gmail.com)提供临时 Apple ID。
Linux | Shadowsocks-Qt5 | [GitHub](https://github.com/shadowsocks/shadowsocks-qt5/wiki/Installation) | 无 | Linux 用户直接参考 GitHub 教程

##### 使用方式

各平台软件使用方式大同小异，大概步骤是：
1. 下载对应平台软件
2. 安装
3. 在对应栏输入 IP，Port（端口），Encryption（加密方法），Password
4. 点击「设置系统代理」（如果有的话）
5. Start
6. 如果有 PAC 或者 Smart Routing 模式，建议选上，这样的话你访问国内网站就会走国内流量，访问境外网站才会走代理流量。

**如有疑问请留言**