---
title: Mac Homebrew 如何指定版本安装
date: 2020-05-01 23:40:39
tags:
---

![homebrew](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/homebrew-set-software-elder-version/homebrew.png)

Homebrew 默认只安装最新版本的软件，如何制定版本？下面以安装 `brew install apache-flink` 为例，指定安装特定版本的 Flink。

在写这篇文章时， Flink 的最新版本为 1.11.1，使用 `brew info apache-flink ` 查看版本信息：

<!--more-->

```
➜  ~ brew info apache-flink
apache-flink: stable 1.11.1, HEAD
Scalable batch and stream data processing
https://flink.apache.org/
Not installed
From: https://github.com/Homebrew/homebrew-core/blob/HEAD/Formula/apache-flink.rb
License: Apache-2.0
==> Requirements
Required: java = 1.8 ✔
==> Options
--HEAD
	Install HEAD version
==> Analytics
install: 583 (30 days), 2,189 (90 days), 13,565 (365 days)
install-on-request: 577 (30 days), 2,176 (90 days), 13,517 (365 days)
build-error: 0 (30 days)
```

而我需要的版本为 apache-flink 1.9.0，下面就开始安装指定版本。

##### Clone Homebrew Core
首先访问 [homebrew-core](https://github.com/Homebrew/homebrew-core) 项目，并 Clone 该项目到本地。

> Homebrew Core 是 Homebrew 软件的管理器，如果无法访问，访问下面 Clone 地址：https://github.com/Homebrew/homebrew-core.git

##### 查看提交记录

进入 Homebrew Core 项目的根目录，使用 `git log master -- Formula/apache-flink.rb` 查看 Flink 提交记录，如果是其他软件，则替换成对应软件名即可.

找到 apache-flink 1.9.0 的 commit id。

```
➜ ~ cd homebrew-core 
➜  homebrew-core git:(master) git log master -- Formula/apache-flink.rb

commit fd679805d6722d515e26226d54c4b6728fabba48
Author: chenrui <chenrui333@gmail.com>
Date:   Wed Oct 23 21:50:06 2019 -0400

    apache-flink 1.9.1 (#45746)

commit 1cfab9bd5691406e475341014b8cd52dc0b351c8
Author: chenrui <rchen@meetup.com>
Date:   Mon Aug 26 21:35:37 2019 -0400

    apache-flink 1.9.0 (#43445)

commit 704666803e1c315c4ba7244443755163a54e7aac
Author: Sung Gon Yi <skonmeme@gmail.com>
Date:   Wed Jul 10 17:34:46 2019 +0900

    apache-flink 1.8.1 (#41813)

commit 9312171d224f9ab2f32b57abea3f1c99d5fc4332
Author: Aljoscha Krettek <aljoscha.krettek@gmail.com>
Date:   Thu Apr 11 19:37:03 2019 +0200

    Merge pull request #38807 from aljoscha/update-flink-1.8.0
    
    apache-flink 1.8.0

```

可以看到，apache-flink 1.9.0 的 commit hash id 为 `1cfab9bd5691406e475341014b8cd52dc0b351c8`，我们要记住这个 id。

##### 安装指定版本 

根据上面的 id，即可安装对应的软件版本
```
➜  ~ brew install https://raw.githubusercontent.com/Homebrew/homebrew-core/1cfab9bd5691406e475341014b8cd52dc0b351c8/Formula/apache-flink.rb
Updating Homebrew...
Warning: Calling Installation of apache-flink from a GitHub commit URL is deprecated! Use 'brew extract apache-flink' to stable tap on GitHub instead.
######################################################################## 100.0%
==> Downloading https://archive.apache.org/dist/flink/flink-1.9.0/flink-1.9.0-bin-scala_2.11.tgz
######################################################################## 100.0%
Warning: apache-flink 1.11.1 is available and more recent than version 1.9.0.
🍺  /usr/local/Cellar/apache-flink/1.9.0: 161 files, 276.9MB, built in 4 seconds
Removing: /Users/Library/Caches/Homebrew/apache-flink--1.9.0.tgz... (243.4MB)
```

这里再介绍另外一种安装方法，得到 id 后，进入 homebrew-core 项目的根目录，checkout id 对应的分支，然后进入 Formula 文件夹，通过 `brew install *.rb`，也是可行的。

```
➜  homebrew-core git:(master) git checkout 1cfab9bd5691406e475341014b8cd52dc0b351c8
homebrew-core git:(1cfab9bd56) cd Formula
➜  Formula git:(1cfab9bd56) brew install apache-flink.rb                       
==> Downloading https://archive.apache.org/dist/flink/flink-1.9.0/flink-1.9.0-bin-scala_2.11.tgz
Warning: apache-flink 1.11.1 is available and more recent than version 1.9.0.
🍺  /usr/local/Cellar/apache-flink/1.9.0: 161 files, 276.9MB, built in 3 seconds
Removing: /Users/Library/Caches/Homebrew/apache-flink--1.9.0.tgz... (243.4MB)
``` 

##### 禁止更新
如果不打算更新，可以使用 `brew pin apache-flink` 来固定 flink 的版本，避免 `brew upgrade` 时自动升级

```
# pin 版本
➜  ~ brew pin apache-flink

# 查看被 pin 版本
➜  ~ brew list --pinned
apache-flink
```

##### Reference
[https://www.vitah.net/posts/2020/05/use-homebrew-install-elder-version/](https://www.vitah.net/posts/2020/05/use-homebrew-install-elder-version/)


