title: Mac OS 下的 Python 多环境共存
date: 2018-5-1 14:49:13
desc:
---

1. pyenv - pyenv-virtualenv 安装.
2. pyenv - pyenv-virtualenv 常用命令.

<!--more-->

#### 前提步骤

* 安装zlib

```
    brew install zlib
```
* 指定zlib link

```
    brew link --overwrite zlib --force
```



# 安装 pyenv
##### 1. 安装pyenv
```
    brew install pyenv
```
##### 2.配置
```
    vim ~/.bash_profile

    # 写入以下命令（一般brew install pyenv会自动软连接到opt路径）
    export PYENV_ROOT=/usr/local/opt/pyenv
    if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi

    # 保存
    :wq

    # 使环境变量生效
    source ~/.bash_profile
```
##### 3. 常用命令
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

# 安装 pyenv-virtualenv
##### 1. 安装与配置
* 通常的安装方法：基本推荐使用 ` brew install pyenv-virtualenv` 安装，但我用brew安装时遇到了无法安装的情况，所以我就手动安装了。

* 手动安装方法

```
    # 下面命令的 /usr/local/Cellar/pyenv/1.2.4/plugins 路径为你本机Homebrew pyenv的路径
    git clone https://github.com/yyuu/pyenv-virtualenv.git /usr/local/Cellar/pyenv/1.2.4/plugins/pyenv-virtualenv

    # 添加环境变量
    echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bash_profile

    # 使环境变量生效
    source ~/.bash_profile
```

##### 2. 常用命令
```

    # 创建virtualenv（前提是你已经用pyenv安装了python 3.5.0）
    pyenv virtualenv 3.5.0 env350

    # 切换virtualenv
    pyenv activate env350

    # 切回系统环境
    pyenv deactivate env350
```
