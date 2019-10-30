---
title: 罗技 Logitech Unifying 优联模式在 macOS Catalina 10.15 版本下的 bug 及解决方案
date: 2019-10-30 20:46:30
---

最近升级到了 macOS Catalina 10.15，发现我的 MX Master 2S 鼠标在 10.15 系统下，使用 Unifying 优联模式，光标和左右按键全部失效，而功能键正常（蓝牙模式一切正常）。尝试了重装 Logi Option on Mac ，结果还是一样

网上找到很多中文的资料，但罗技中文的论坛几乎没人谈这个 bug。差点就要回滚系统的时候，在罗技的美国官网论坛，发现了解决方案。

<!--more-->

文章最下面提供官方地址

按官网给出的解释

> NOTE: We are aware that after upgrading from macOS 10.14 Mojave or earlier to macOS 10.15 Catalina with LCC (Logitech Control Center) versions 3.9.8 or below, some Logitech Unifying-based devices may stop working. This is a known issue on macOS 10.15 Catalina and we’re actively working with Apple to address it.
In the meantime, if your Unifying device is not working after upgrading to macOS Catalina, please upgrade to LCC 3.9.9 from this link and reboot the system to complete the installation.

那么按照官方提供，只要下载最新 LCC 软件就可以了，最新 LCC 下载地址，点击[这里](https://support.logi.com/hc/articles/360025297833)

但下载安装完之后，如果你的鼠标还是无法正常工作，那么就要按下面步骤来检查

1. 打开终端 Terminal, cd 到 /Application/Utilities 文件夹
2. 输入命令 `kextstat | grep -i Logi`

```
105    1 0xffffff7f8252b000 0x47000    0x47000 com.Logitech.ControlCenter.HIDDriver (3.9.9) BB513FDB-C9C7-3A6F-AD71-58CDD322B095 <104 76 49 25 6 5 3>
106    0 0xffffff7f82582000 0x16000    0x16000 com.Logitech.Unifying.HIDDriver (1.3.9) 4E15EC6B-3BB3-3644-B366-F5EFB857C2BB <105 104 49 25 6 5 3>
```

如果 `com.Logitech.Unifying.HIDDriver` 不是 1.3.9 版本，说明你最新安装的驱动并没有生效，那么就要继续按接下来的步骤重启电脑

1. 以恢复模式重启 Mac
    1. 重启电脑
    2. 当启动状态时，按住 Command + R，直到进入恢复模式的界面
2. 进入恢复模式 ![recovery model](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/macos1015-logitech-update/RecoveryMode.png)
3. 关闭这个窗口（点击左上的红叉叉）
4. 点击选择启动盘 ![chooseDisk](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/macos1015-logitech-update/ChooseStartupDisk.png)
5. 选择你的硬盘，点击重启（如果有密码，需要先解锁）![disk](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/macos1015-logitech-update/Disk.png)
7. 再次点击重启按钮，等待重启 ![restart](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/macos1015-logitech-update/Restart.png)

重启之后，再用 Logitech Unifying Software 重新配对优联模式，鼠标就重新 work 了

不得不吐槽苹果这个 bug 简直折腾了我半个多月，因为 Logitech 的蓝牙模式，一点都不好用

附官方提供的解决方案地址：

https://support.logi.com/hc/en-us/community/posts/360036740513-Important-information-for-Logitech-Control-Center-and-macOS-Catalina-Update-LCC-before-installing-macOS-Catalina