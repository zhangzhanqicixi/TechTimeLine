---
layout: hexo
title: 基于 Hexo 博客搭建
date: 2018-7-22 22:52:07
---

搭建这个 Blog 用到的技术其实都很大众且成熟的，基本都是可以直接拿来用的。

##### 技术框架
博客框架我用的是 [**Hexo**](https://hexo.io/zh-cn/docs/index.html)， 模版用的是 [**Apollo**](https://github.com/pinggod/hexo-theme-apollo)， 运营商选择了 [**Google Cloud**](https://cloud.google.com/)，反向代理还是 **Nginx**，实现了基于 **Python Flask** 的 **API RESTFul** 的自动更新，最后用 **Docker** 封装了上面这些服务，为的是以后迁移服务器时可以更加快捷和方便。

评论系统用的 [**Disqus**](https://disqus.com/)， 之后还会找一个 **PV** 统计插件。



##### 项目 TIMELINE

- [x] 确认使用 Hexo 作为博客框架
- [x] Theme 选择
- [x] 本地部署测试
- [x] 代码托管至 Github
- [x] Google Cloud 服务器部署
- [x] Docker with Nginx 安装
- [x] Nginx 反向代理及禁止 IP 访问
<!--more-->
- [x] 将整个 Hexo 项目也打包成 Docker
- [x] 挂载宿主机 **/source/_posts/** 目录作为 Hexo Docker 的外部 Volumn，使之可以动态更新
- [x] 开发 API RESTFul 服务，使服务端可通过 HTTP 请求自动更新
- [x] 阿里云万网 DNS 注册及解析
- [x] Disqus 评论系统集成
- [ ] PV 系统集成

##### Hexo 框架及 Apollo 模版

updating ...

##### Nginx 及 Docker

updating ...

##### API 远程更新

updating ...

