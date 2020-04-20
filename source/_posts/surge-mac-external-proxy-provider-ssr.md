---
title: Surge Mac 外部代理模式 - 使之支持 SSR/V2Ray
date: 2020-04-19 16:36:40
tags: 
---

订阅了一个机场主的服务，只提供 SSR/V2Ray 协议，而 Surge 原生支持 SS 协议，查了下文档后发现 Surge 提供外部代理模式 External Proxy Provider，可以变相支持 SSR/V2Ray

<!--more-->

大致的逻辑如下图

![surge-external-proxy-provider](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/surge-external-proxy-provider/surge-external-proxy-provider.png)


##### 节点配置文件

针对某个 SSR 节点，新建一个 .json 配置文件，下面是样例文件

```
{
  "enable" : true,
  "password" : "password",
  "method" : "chacha20",
  "server" : "example.server.jp",
  "obfs" : "tls1.2_ticket_auth",
  "protocol" : "auth_aes128_md5",
  "protocol_param" : "protocol_param",
  "obfs_param" : "baidu.com",
  "server_port" : 10086,
  "local_port": 1125
}
```
一定要配置 **local_port**，后续 surge 需要监控这个本地端口


##### ss-local 客户端
ss-local 是 shadowsocks-libev 提供的客户端工具，有了这个文件我们可以使用配置文件 + 一行命令启动 SS/SSR 客户端，如：

```
ss-local -c config.json
```

一般在 ShadowSocks App 内的 Resources 文件夹下有该文件，或者可以去 Github下载
[https://github.com/shadowsocks/ShadowsocksX-NG](https://github.com/shadowsocks/ShadowsocksX-NG)

```
/Applications/ShadowsocksX-NG-R8.app/Contents/Resources/ss-local
```


##### Surge 节点配置

接下来只要在 Surge 的配置文件中的 [Proxy] 组中，配置 External 模式，指定 json 文件路径及 ss-local 路径，就可以变相在 Surge 上使用 SSR 了，其中 local-port 就是 SSR 配置时的本地监听端口

- 一定要写 local_port
- args = "-c" 一定要写在 args "xxx.json" 路径之前

作者的文档链接
[https://medium.com/@Blankwonder/surge-mac-new-features-external-proxy-provider-375e0e9ea660](https://medium.com/@Blankwonder/surge-mac-new-features-external-proxy-provider-375e0e9ea660)

```
...

[Proxy]
🇭🇰 HK-CTCM0 = external, exec = "/ProxyExternal/ss-local", local-port = 1122, args = "-c", args = "/ProxyExternal/HK-Online-0.json"
🇰🇷 KR-Sel0 = external, exec = "/ProxyExternal/ss-local", local-port = 1123, args = "-c", args = "/ProxyExternal/KR-Sel-0.json"
🇸🇬 SG-Mi0 = external, exec = "/ProxyExternal/ss-local", local-port = 1124, args = "-c", args = "/ProxyExternal/SG-Micro-0.json"
🇸🇬 SG-Mi1 = external, exec = "/ProxyExternal/ss-local", local-port = 1125, args = "-c", args = "/ProxyExternal/SG-Micro-1.json"
🇯🇵 JP-A-0 = external, exec = "/ProxyExternal/ss-local", local-port = 1126, args = "-c", args = "/ProxyExternal/JP-Azure-0.json"

...
```

##### 测速延迟

第一次测速时由于分别要启动这几个 ss-local 进程，延迟会很大程度 delay，第二次开始后恢复正常延迟

![testing](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/surge-external-proxy-provider/surge-testing.png)
