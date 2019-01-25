---
title: 几个给 Docker 镜像瘦身的小技巧
date: 2019-01-25 20:00:17
tags:
---



Docker 用了大半年了，随着越来越多的业务都迁移到了 Docker，带来的一个问题就是镜像太大，导致如果是走外网的 Push 还是 Pull 都要等很久，所以操作了一番之后，总结一下给镜像瘦身的几个点，中心原则是确保镜像内的环境只需要满足我们运行时条件就可以了。

先看眼压缩前的容器大小：
```
[root@izbp1il8g6sk611nfyth3bz chatterbot]# docker images
REPOSITORY    TAG        IMAGE ID            CREATED             SIZE
chatbot      3.0.11    576315999dc5         9 days ago          3.77GB
```

<!--more-->

##### 1. 代码自查，删除不需要的代码和依赖包
这个其实没啥好讲的，根据自己业务删代码删依赖。

- 对于算法任务，请检查是否有多余的模型，或者之前已经废弃的模型，或者训练时才需要用到的数据仍然存在当前工程中，这个在我们使用过程中很容易被忽略。

- 对于工程任务查看是否有多余的依赖，以 Python 项目举例，查看 requirements.txt 中是否有已经不需要包，构建时多一个包就很影响镜像大小。

##### 2. 使用 .dockerignore 
删掉无用的代码和依赖之后，发现项目还是非常大，使用
``` 
[root@izbp1il8g6sk611nfyth3bz chatterbot]# du -hs * .[^.]* 
4.0K    config.py
96K     core
7.0M	data
12K	decryption
4.0K	Dockerfile
4.0K	inner.log
59M	intention_classify
56K	logs
4.0K	parse.py
4.0K	readme.txt
4.0K	requirements.txt
8.0K	service.py
575M	train
14M	sims
12K	test
24K	utils
4.0K	.dockerignore
876M	.git
4.0K	.gitignore
20K	.idea 
```
看了眼当前文件夹下各文件的大小，发现是版本控制文件夹（.git）占了大头，第二大的是训练文件夹（train）。我们的服务运行时并不需要用到训练时的文件和数据，所以这些都可以使用 .dockerignore 让镜像在 build 的时候忽略掉。

.dockerignore 的官方解释：

> To use a file in the build context, the Dockerfile refers to the file specified in an instruction, for example, a COPY instruction. To increase the build’s performance, exclude files and directories by adding a .dockerignore file to the context directory. For information about how to create a .dockerignore file see the documentation on this page.

使用方式和 git 的 .gitignore 文件相似，只要在 dockerfile 准备 build 的项目文件夹下建立一个 .dockerignore 的空文件，然后把需要忽略的文件/文件夹写进去，之后在使用 docker build 命令时，Docker 就会自动忽略这些文件夹。

``` 
[root@izbp1il8g6sk611nfyth3bz chatterbot]# vim .dockerignore
```
```
train
.git
.env
.test
.readme.txt
```

##### 3. 更换更小的官方基础镜像

我们大多数的镜像（服务），都是基于 Linux 内核开发的程序，那么先看下常见的 Linux 操作系统构建的 Docker 基础镜像大小。

![linux-image](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/docker-image-loss-weight/linux-image.jpg)



可以看到 CentOS 是最大的系统级镜像，光一个基础镜像就达到 210M 了，而我们之前的镜像就是基于 CentOS 镜像上构建的。本来很兴奋的想使用 alpine 系统，但问了运维同学，他们说 apline 太小了，以至于基本所有的环境都要自己装（比如 gcc），所以之后选择了相对来说也很小的 debian，对我来说也够用了。

##### 4. 尝试使用 Google Container Tools 下的 Distroless 作为基础镜像

其实通过上面的方法之后，镜像的大小已经从原来的 3.7G 瘦身到了 1.6G，理论上来说已经很不错了，但我总觉得瘦得还不够。
> 镜像可以瘦身大小的极限预测方法，可以观察你项目 requirements.txt 文件中写的所依赖的包 install 之后的大小。理论上来讲你的项目运行，只需要这些依赖加一个 PVM （python 运行时环境），其他系统层面的东西，对你的运行是没有任何用处的

后来发现了 Google 有个 [gcr.io/distroless](https://github.com/GoogleContainerTools/distroless) 项目，专门用来解决类似的问题，他们给出了基于不同语言的仅运行时需要的依赖所构建出的镜像，我们要做的只是把其他的依赖和项目代码 copy 到他的镜像中，从而达到实现最小化的项目镜像。

'Distroless' 镜像官方解释：
> "Distroless" images contain only your application and its runtime dependencies. They do not contain package managers, shells or any other programs you would expect to find in a standard Linux distribution.

For more information, see this talk ([video](https://www.youtube.com/watch?v=lviLZFciDv4)).

Distroless 给出基本镜像包括：
```
gcr.io/distroless/static
gcr.io/distroless/base
gcr.io/distroless/java
gcr.io/distroless/cc
```

在基础镜像之上给出的预装不同语言环境的基础镜像包括（注意**官方现在不推荐使用这些镜像上生产环境**）：
```
gcr.io/distroless/python2.7
gcr.io/distroless/python3
gcr.io/distroless/nodejs
gcr.io/distroless/java/jetty
gcr.io/distroless/dotnet
```

代码层面不需要改什么东西，只需要改 Dockerfile，给出参考的 Dockerfile

```
# 传统 Dockerfile 代码 - 已注释
# FROM python:3.5
# WORKDIR /app
# COPY . .
# ENV LANG C.UTF-8
# RUN pip3 install --upgrade pip && \
pip3 install -i https://pypi.tuna.tsinghua.edu.cn/simple/ --no-cache-dir -r requirements.txt
# HEALTHCHECK --timeout=10s --interval=20s --retries=5 CMD curl http://localhost:8081 || exit 1
# CMD ["python3.5", "service.py"]


# 使用 Google Distroless 镜像
FROM python:3.5 AS build-env
ADD . /app
WORKDIR /app
RUN pip3 install --upgrade pip && \
pip3 install -i https://pypi.tuna.tsinghua.edu.cn/simple/ --no-cache-dir -r requirements.txt


FROM gcr.io/distroless/python3
COPY --from=build-env /app /app
COPY --from=build-env /usr/local/lib/python3.5/site-packages /usr/local/lib/python3.5/site-packages
COPY --from=build-env /usr/local/lib/libpython3.5m.so.1.0 /usr/local/lib64/
COPY --from=build-env /usr/local/lib/libpython3.5m.so.1.0 /usr/local/lib/
# 复制 libpython3.5m.so.1.0 之后，需重新加载配置
RUN /sbin/ldconfig -v
WORKDIR /app
ENV PYTHONPATH=/usr/local/lib/python3.5/site-packages
ENV LANG C.UTF-8
COPY . /app
HEALTHCHECK --timeout=10s --interval=20s --retries=5 CMD curl http://localhost:8081 || exit 1
CMD ["service.py"]
```

如果你的代码没有和 C 语言的库有通信，可以不需要复制 libpython3.5m.so.1.0，亦不需要 
```
RUN /sbin/ldconfig -v
```
这一层的镜像了。

##### final - 最终结果
好了，现在看看基于 Google Distroless 镜像构建的项目镜像大小

```
[root@izbp1il8g6sk611nfyth3bz chatterbot]# docker images
REPOSITORY    TAG        IMAGE ID            CREATED           SIZE
chatbot      3.0.12    627062d75baa         21 hours ago       682MB
```

600M+, 相比之前的 3.77G，大小少了 3.17G，比例下降 80%+，基本已经是此业务镜像瘦身的极限了，也可以看到之前的镜像是多么的冗余。

另外，使用 Distroless 镜像官方明确指出了不推荐在生产环境上使用，虽然至今我没遇到什么问题，但是如果真的要上生产，还请尽量测试一下。

至此 Docker Image 瘦身成功。