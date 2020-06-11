---
layout: hexo
title: 基于 Hexo & Docker 的博客搭建流程
date: 2018-7-22 22:52:07
desc: 搭建这个 Blog 用到的技术其实都很大众且成熟的，基本都是可以直接拿来用的。
---

搭建这个 Blog 用到的技术其实都很大众且成熟的，基本都是可以直接拿来用的。

##### 技术框架

![hexo](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/hexo-blog-installed/hexo-official.png)

博客框架我用的是 [**Hexo**](https://hexo.io/zh-cn/docs/index.html)， 模版用的是 [**Apollo**](https://github.com/pinggod/hexo-theme-apollo)， 运营商选择了 [**Google Cloud**](https://cloud.google.com/)，反向代理还是 **Nginx**，实现了基于 **Python Flask** 的 **API RESTFul** 的自动更新，最后用 **Docker** 封装了上面这些服务，为的是以后迁移服务器时可以更加快捷和方便。

> 2018-08-13 更新：运营商换回了 Aliyun HK，Google Cloud 在国内用起来还是不方便，而且整体收费比阿里云要贵一丢丢

评论系统用的 [**Disqus**](https://disqus.com/)，~~之后还会找一个 **pv** 统计插件。~~ 

> **pv,uv** 统计，感谢 [busuanzi](http://busuanzi.ibruce.info/)。



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
- [x] 挂载宿主机 **/source/_posts/** 目录作为 Docker Hexo 的外部 Volumn，使之可以动态更新
- [x] 开发 API RESTFul 服务，使服务端可通过 HTTP 请求自动更新
- [x] 阿里云万网 DNS 注册及解析
- [x] Disqus 评论系统集成
- [x] 全站部署 HTTPS

##### Docker

<div class="tip">
 如果你不了解 Docker，可以暂时把 Docker 比作一台虚拟机。
</div>

为什么先讲 Docker ？因为我的整个博客和服务的搭建都是基于 Docker 的，下面我给出的代码也是建立 Repository 的 Dockerfile。

PS: 当然你也可以根据 Dockerfile 里的内容在宿主机上跑。

- 从 Docker Hub 拉取需要用到的原生 Repository

```
# 拉取 Python3 仓库
docker pull python:3

# 拉取 Node 仓库
docker pull node

# 拉取 Nginx 仓库
docker pull nginx
```

##### Hexo 框架及 Apollo 模版

Hexo + Apollo 最终呈现的效果就现在博客的样子，目前我是挺喜欢这样的样式和布局的。

基本的 Hexo 和 Theme 配置官网写的很清楚了，再写一遍感觉没啥必要，可以移步  [**Hexo**](https://hexo.io/zh-cn/docs/index.html) 官网。

我给出基于 node 的 Dockerfile

```
FROM node
MAINTAINER ZHANGZHANQI <zhangzhanqicixi@gmail.com>

# 定义工作空间
WORKDIR /app

# install hexo
RUN npm install hexo-cli -g

# 初始化当前路径 (/app) 为 hexo 路径
RUN hexo init .

# 安装 npm 包管理工具
RUN npm install

# install apollo theme 依赖包
RUN npm install --save hexo-renderer-jade hexo-generator-feed hexo-generator-sitemap hexo-generator-archive

# COPY 本地 Hexo 的 (注意不是 Theme 的 _config.yml) 到容器内
COPY _config.yml .

# COPY source 文件夹
COPY ./source ./source

# COPY themes
COPY ./themes/apollo ./themes/apollo

CMD ["hexo", "s", "-l"]
```

- 这里有一个技巧，因为上面的 Dockerfile 中的每一行命令在构建时，就会自动生成一层，底层命令依赖上层。我们可以把 **变化较少的命令放在上层**，这样如果你的代码修改了之后，最上层的就不会动，加快构建速度。

1. **构建容器**：Dockerfile 配置好后，可以在 Dockerfile 路径下使用 `docker build -t blog .` 来构建容器。

2. **Docker 启动 Hexo 博客**： `docker run --name=blog -d --rm -p 4000:4000 --privileged -v /root/TechTimeLine/source/_posts:/app/source/_posts blog`
    
    - `-p 4000:4000`  暴露 docker 端口
    - `--privileged`  给这个容器最高的权限，默认 `--privileged=false`
    - `-v /root/TechTimeLine/source/_posts:/app/source/_posts ` 给容器挂载存储卷，挂载到容器的某个目录（ **用于自动更新** ）


##### Nginx 配置

Nginx 放在这里的最重要的用处：

- 隐藏 Blog 服务的真实 IP 地址。
- 负载均衡，后端可以部署多台 Blog 服务，Nginx 默认会使用「轮询」机制。
- 更方便的实现 HTTPS。

给出 nginx.conf

```
user  nginx;
worker_processes  5;
worker_rlimit_nofile 8192;

events {
  worker_connections  1024;
  accept_mutex on;
  multi_accept on;
}

http {
  include    /etc/nginx/conf.d/*.conf;
  index    index.html index.htm index.php;

  default_type application/octet-stream;
  log_format   main '$remote_addr - $remote_user [$time_local]  $status '
    '"$request" $body_bytes_sent "$http_referer" '
    '"$http_user_agent" "$http_x_forwarded_for"';
  sendfile     on;
  tcp_nopush   on;
  server_names_hash_bucket_size 128;

  # 上游服务器，两台 blog 服务器
  upstream blog_server_com {
    server 10.140.0.2:4000;
    server 10.140.0.1:4000;
  }

  # HTTP 请求配置，全部转发到 HTTPS 443 端口
  server { 
    listen          80;
    server_name     blog.timeline229.com;
    rewrite ^(.*) https://$server_name$1 permanent;
  }

  # HTTPS 配置
  server {
    listen 443 ssl;
    server_name blog.timeline229.com;
    root /usr/share/nginx/html;
    index index.html index.htm;
    # 替换 ssl_certificate 和 ssl_certificate_key
    ssl_certificate   /etc/nginx/cert/*.pem;
    ssl_certificate_key  /etc/nginx/cert/*.key;
    ssl_session_timeout 5m;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;
    location / {
        proxy_pass    http://blog_server_com;
        root /usr/share/nginx/html;
        index index.html index.htm;
    }
  }
  # 禁止 IP 地址访问服务器，如果是 IP 地址，则返回 500
  server {
     listen    80 default;
     listen    443 ssl default;
     ssl_certificate   /etc/nginx/cert/*.pem;
     ssl_certificate_key  /etc/nginx/cert/*.key;
     return 500;
  }
}
```
该 nginx.conf 为 HTTPS 的配置文件，把上面的 nginx.conf 复制到你的 /etc/nginx/nginx.conf 路径下，你需要修改的只有：

- 修改 **server_name** 为你自己的域名
- 把 **upstream** 下的服务器地址改成你的 IP 地址
- 将 **ssl_certificate** 和  **ssl_certificate_key** 替换成你自己的 Certificate 

在配置完 Nginx 之后，我们不需要 Build，因为我们可以直接使用 Docker Hub 上的 Nginx 容器。

- Nginx 容器启动 `docker run -d --rm --name=nginx -p 443:443 -p 80:80 -v /etc/nginx/nginx.conf:/etc/nginx/nginx.conf nginx`

  - `-p 443:443 -p 80:80` 暴露 443 和 80 端口
  - `-v /etc/nginx/nginx.conf:/etc/nginx/nginx.conf` 将宿主机的 nginx.conf 配置文件挂载到 nginx 容器内


##### API 远程更新

基本的逻辑是在服务端有一个自动更新文章目录的脚本，给这个脚本套一层 API 服务，每次来请求的时候带上一个 **API KEY** 参数，服务端验证这个值，通过就自动更新。

由于服务端只会做目录更新，所以万一 **API KEY** 泄露也不会影响什么。

- 给出基于 **Flask** 写的 API RESTful 代码

```
import json
import git
import traceback
import requests
from flask import Flask, Response, request
from flask_restful import reqparse

@app.route('/api/auto_update')
def auto_update():
    response = {'status': 'error'}
    parser = reqparse.RequestParser()
    parser.add_argument('key', type=str)
    args = parser.parse_args()
    if args['key'] == KEY:
        response['status'] = 'ok'
        try:
            git_pull()
        except:
            response['status'] = 'error'
            response['traceback'] = traceback.format_exc()
    return Response(json.dumps(response, ensure_ascii=False), mimetype='application/json;charset=utf-8')
    
# 在指定的目录更新 (git pull)    
def git_pull():
    repo = git.Repo('/app/timeline')
    remote = repo.remote()
    remote.pull()
```

##### 接下来要完成

- ~~上线 **PV** 流量统计功能~~
    - 基于 [**不蒜子**](http://ibruce.info/2015/04/04/busuanzi/) 的 **访问次数**，**访问人数** 统计，配置很简单，可以直接点进去看官网。 
- ~~禁止直接访问服务器 IP 地址~~
    - 已经更新在 nginx.conf 上了，需要注意的是在 default server 配置时，也需要添加 **ssl_certificate** 和  **ssl_certificate_key**

    ``` 
    # 禁止 IP 地址访问服务器，如果是 IP 地址，则返回 500
    server {
     listen    80 default;
     listen    443 ssl default;
     ssl_certificate   /etc/nginx/cert/*.pem;
     ssl_certificate_key  /etc/nginx/cert/*.key;
     return 500;
    }
    ```
    
- ~~让墙内的用户知道博客有基于 **Disqus** 的评论~~
    -  网上很多解决方案，大致思路是自己写样式，由服务器直接加载样式。
    -  数据部分则通过墙外的服务器做反向代理，通过 **Disqus** 提供的 **API** 去拿评论数据。
    -  而我更倾向让你知道有 **Disqus** 这个东西，且让你知道这个东西被墙了，这样如果你有兴趣，可以自己翻墙去看。
    -  具体做法：请求自己搭建的接口，接口服务部署在墙外的服务器，返回内容是 **Disqus** 的 **Javascript** 文件，并将加载框的英文注释改为中文注释。
    -  具体代码如下
   
    ```
    import requests
    from flask import Flask, Response, request
    from flask_restful import reqparse
    
    @app.route('/api/disqus')
    def disqus():
        short_name = request.args.get('short_name', None)
        path = request.args.get('path', None)
        if short_name is not None and path is not None:
            url = 'https://' + short_name + '.disqus.com/' + path + '.js'
            notice = '评论如果一直加载不了, 说明被墙了, 自己看着办吧... >_<.'
            r = requests.get(url).text \
                .replace('Disqus seems to be taking longer than usual.', notice) \
                # 默认 15 秒才出现 notice，我改成了 0 秒就出现
                .replace('15e3', '0e3')
            return Response(r, mimetype='text/javascript; charset=utf-8')
    ```


