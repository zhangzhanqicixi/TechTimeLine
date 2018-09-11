---
title: ShadowsocksR 使用方法及各平台下载地址
date: 2018-08-15 10:01:37
tags:
---
<div class="tip">
让更多小白知道互联网原本该有的样子
</div>

<!--more-->

##### ZPanel 用户

> 有自己账号的同学可直接跳过，如果想购买流量的同学直接找[我](mailto:zhangzhanqicixi@gmail.com)，我会给你报价。

- 登录 [ZPanel](http://panel.timeline229.com/user)
- 选择左侧导航栏的 「节点列表」(如下 1 图）
- 选择一个节点（如下 2 图）
- 「配置Json」对话框内就是下面配置需要用到的信息(如下 3 图），包括：
    - server: IP 地址
    - server_port: 服务器端口
    - password: 密码
    - method: 加密方式
- 如果你的 APP 或软件支持扫码配置，可直接使用页面右侧「配置二维码」，更方便一点。

<div style="float:left;border:solid 1px 000;margin:40px;"><img src="https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/ssr-clients/nodelist.png" width="100" title="nodelist"></div><div style="float:left;border:solid 1px 000;margin:40px;"><img src="https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/ssr-clients/node.png" width="132" title="node"></div><div style="float:left;border:solid 1px 000;margin:40px;"> <img src="https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/ssr-clients/Json.png" width="207" title="json"></div><div style="float:none;clear:both;"></div>

##### 使用方式

各平台软件使用方式大同小异，大概步骤是：
1. 根据下面的表格，下载对应平台软件
2. 安装
3. 在对应栏输入 IP，Port（端口），Encryption（加密方法，有些软件叫 Method ），Password
4. 点击「设置系统代理」（如果有的话）
5. Start
6. 如果有 PAC 或者 Smart Routing 模式，建议选上，这样的话你访问国内网站就会走国内流量，访问境外网站才会走代理流量。


##### 各平台工具汇总

这一类的软件每个平台下很多，这里提供各平台开源，免费的软件一览

<style>
table th:nth-of-type(1) {
    width: 100px;
}
table th:nth-of-type(2) {
    width: 100px;
}
table th:nth-of-type(3) {
    width: 80px;
}
table th:nth-of-type(4) {
    width: 50px;
}
table th:nth-of-type(5) {
    width: 200px;
}
</style>

platform | client | official | oss | remark
:---: | :---: | :---: | :---: | :---
Windows | Shadowsocks-Win | [GitHub](https://github.com/shadowsocks/shadowsocks-windows/releases) | [OSS](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/ssr-clients/Shadowsocks-2.exe) | 国内用户直接点击 OSS 下载
Mac OS X | ShadowsocksX-NG | [GitHub](https://github.com/shadowsocks/ShadowsocksX-NG/releases) | [OSS](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/ssr-clients/ShadowsocksX-NG.app.zip) | 国内用户直接点击 OSS 下载
Android | Shadowsocks-Android | [Google Play](https://play.google.com/store/apps/details?id=com.github.shadowsocks) | [OSS](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/ssr-clients/Shadowsocks.apk) | 国内用户直接点击 OSS 下载
iOS | Potatso Lite | [App Store](https://itunes.apple.com/us/app/potatso-lite/id1239860606?mt=8) | 无 | 中国区 Apple ID 是无法搜到 SSR 的 APP 的。如果你没有非中国大陆区的 Apple ID，可参考我的另一篇 [Blog](https://blog.timeline229.com/transfer-appleid-to-us/) 进行转区，或联系[我](mailto:zhangzhanqicixi@gmail.com)提供临时 Apple ID。
Linux | Shadowsocks-Qt5 | [GitHub](https://github.com/shadowsocks/shadowsocks-qt5/wiki/Installation) | 无 | Linux 用户直接参考 GitHub 教程



**如有疑问请留言**