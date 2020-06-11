---
title: 将中国区 Apple ID 转到美国区及绑定 PayPal
date: 2018-08-11 14:38:16
tags:
---

> ~~因为「众所周知」的原因，我还是更愿意我的数据被美国「监管」。~~

我是在 Apple 宣布中国区的账号由「云上贵州」运营后，将我的 Apple ID 转移到了美区，由于我有 Google Cloud 和 Aliyun 的梯子，这么多月体验下来，感觉速度也还 ok。

转区的整个过程虽然不难，但刚开始由于没有美国当地的信用卡，也稍微有些麻烦，所以记录一下。

<!--more-->
##### 准备
1. **一张支持双币的信用卡**：这个很容易申请，我原来就有一张招商银行的人民币信用卡，登录招商银行官网，找到在线申请信用卡的入口，按里面的步骤就可以很轻松的申请，大概 3-5 个工作日就可以收到。
    ![credit card](
https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/transfer-apple-id/1533968994.png)
2. **确保你能翻墙**：确保你访问 Apple 的 IP 地址是海外的 IP 地址，因为似乎 Apple 对中国的 IP 地址是做了限制，用中国的 IP 转美区后，可能无法出现 PayPal 或 None 的付款选项。
3. **Apple ID**。

##### 申请 Paypal

 > 如果你已经有 PayPal **美国**的账户，就直接跳过这一步吧。
 
- 登录 [PayPal](https://www.paypal.com/us/home) 官网，点击右上角「Sign Up」注册，根据提示注册一个账号，注意注册过程中「地区」一栏选择美国。

- 登录你的账户，选择「Link a bank or card」，根据提示把你的信用卡信息输入，「Billing address」 可以网上用地址生成器生成一个美国地址，电话号码也如此（PS：如果你输入的电话号码提示需要被验证，建议换一个 IP 地址访问，我用 Google Cloud 的美国地址是需要验证电话的，但是用 Aliyun 日本的 IP 地址就不需要访问）。
<center>
<img src="https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/transfer-apple-id/1533968982.png" width="300" title="node">
</center>


##### 转区
接下来就很简单了，登录 iTunes，选择「账号」 - 「检查我的账号」 - 「改变国家和地区」，选择美国，一路点 Next，到选择 「Payment Method」 时，如果你按我之前说的挂着国外的 IP 地址，就会出现 「PayPal」 或 「None」 选项，「Biliing address」也可以随便填，顺利的话点击「Done」就搞定了。
![Payment](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/transfer-apple-id/1533968988.png)

<div class="tip">
由于美国各个州的税法不同，大部分州买 APP 需要另外付一部分 Tax，我们可以选择免税州作为你的 State，比如我选择了「OR-Oregon」。如下图。
</div>
![tax](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/transfer-apple-id/1533969728.png)

##### 为什么不直接使用 iTunes 默认的 Payment Method 选择 Visa？

Apple 只支持当地区域的信用卡，也就是说美区的 Apple ID 只支持美国的信用卡，而 Paypal 就没有这个限制。

**如果有问题欢迎留言**