---
title: Mac OS 下的 Python 多环境共存
date: 2018-5-26 14:49:13
desc: 文章主要介绍 pyenv 和 pyenv-virtualenv 的安装与使用
---

文章主要介绍两部分，第一部分关于 [**pyenv**](https://github.com/pyenv/pyenv) 安装与常用命令，第二部分 [**pyenv-virtualenv**](https://github.com/pyenv/pyenv-virtualenv) 常用命令，最终实现的效果是使用 `pyenv activate [python version]` 可以自由切换 Python 版本且不对现有运行环境产生影响。

![pyenv](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/pyenv-with-macos/cover1.png)

<div class="tip">
 pyenv 能做什么 ？
</div>

- 改变你的全局 Python 版本
- 提供任何你想要的 Python 版本
- 让你覆盖你环境变量中的 Python 版本
- 使用命令行切换不同的 Python 版本

<div class="tip">
 pyenv-virtualenv 能做什么 ？
</div>

- 作为 pyenv 的插件， pyenv-virtualenv 可以根据不同的由 pyenv 创建的 Python 版本提供对应的虚拟环境，使不同 Python 版本之间的环境互不影响

以下均由 [**Homebrew**](https://brew.sh/) 安装

#### 前提步骤



```
    # 安装 zlib
    brew install zlib
    
    # 指定 zlib link
    brew link --overwrite zlib --force
```

<!--more-->


##### 安装 pyenv
```
    brew install pyenv
```
##### 配置 pyenv
```
    # 进入环境变量 bash_profile 文件
    vim ~/.bash_profile

    # 写入以下命令（一般 brew install pyenv 会自动软连接到opt路径）
    export PYENV_ROOT=/usr/local/opt/pyenv
    if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi

    # 保存
    :wq

    # 使环境变量生效
    source ~/.bash_profile
```
顺利的话你的 **pyenv** 命令就已经安装好了。

##### pyenv 常用命令
```
    # pyenv 可以安装的 python 版本
    pyenv  install --list

    # 安装 python 2.7.1 版本（卸载时替换 install 为 uninstall）
    pyenv install -v 2.7.1

    # 查看已安装的 python 版本
    pyenv versions

    # 查看当前 pyenv 使用的环境
    pyenv version

    # 切换全局版本（另有local shell 模式）
    pyenv global 2.7.1
```


##### pyenv-virtualenv 安装与配置
* 通常的安装方法：推荐使用 ` brew install pyenv-virtualenv` 安装，但我用brew安装时遇到了无法安装的情况，所以我就手动安装了。

* 手动安装方法

```
    # 下面命令的 /usr/local/Cellar/pyenv/1.2.4/plugins 路径为你本机 Homebrew pyenv 的路径
    git clone https://github.com/yyuu/pyenv-virtualenv.git /usr/local/Cellar/pyenv/1.2.4/plugins/pyenv-virtualenv

    # 添加环境变量
    echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bash_profile

    # 使环境变量生效
    source ~/.bash_profile
```

##### pyenv-virtualenv 常用命令
```

    # 创建virtualenv（前提是你已经用 pyenv 安装了python 3.5.0）
    pyenv virtualenv 3.5.0 env350

    # 切换virtualenv
    pyenv activate env350

    # 切回系统环境
    pyenv deactivate env350
```


