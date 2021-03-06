# 优化 DNS Cloudflare IP
[CloudflareSpeedTest](https://github.com/XIU2/CloudflareSpeedTest) 脚本：查找最快 Cloudflare IP 并更新域名解析记录。

## 如何使用
登录你的 DNS 服务商，添加你的域名解析记录。  
_如果使用分地区按运营商线路解析功能，请注意不同线路的初始 IP 不能重复。_

### Windows
1. 下载脚本启动器 `Optimize-DnsCloudflareIP.Cmd` 和所用 DNS 服务商对应目录内的 `Optimize-DnsCloudflareIP.PS1` 脚本至 `CloudflareST.Exe` 所在文件夹。  
2. 修改 `Optimize-DnsCloudflareIP.PS1`，按要求填写参数。
3. 执行 `Optimize-DnsCloudflareIP.Cmd`。默认常规窗口，脚本结束后会暂停，可通过参数调整：
  * 启动器参数 `Optimize-DnsCloudflareIP.Cmd Minimized` 最小化窗口，脚本仅在错误时暂停。
  * 启动器参数 `Optimize-DnsCloudflareIP.Cmd Hidden` 隐藏窗口，脚本会在结束后退出。可通过退出码判断执行结果。
  * 通用参数 `-ExitEnd` 正常结束时立即退出。最小化和隐藏窗口模式使用了此参数。
  * 通用参数 `-ExitError` 发生错误时立即退出。隐藏窗口模式使用了此参数。

如需自动定时执行，请查阅任务计划相关知识。

### 其它操作系统
1. 下载所用 DNS 服务商对应目录内的 `optimize-dns-cloudflare-ip.bash` 至 `CloudflareST` 所在目录。  
2. 修改 `optimize-dns-cloudflare-ip.bash`，按要求填写参数。  
3. 执行 `optimize-dns-cloudflare-ip.bash`。

如需自动定时执行，请查阅 `cron` 相关知识。

<<<<<<< HEAD
## 捐赠与赞助
![alipay](https://user-images.githubusercontent.com/1733254/110204402-bbcabc80-7ead-11eb-8bbc-9be2041214c2.png)
![wechat](https://user-images.githubusercontent.com/1733254/110204405-bd948000-7ead-11eb-9c8a-13094e252d7a.png)

付款代表您同意就捐赠与赞助事项与我[约定](https://gist.github.com/CrazyBoyFeng/a53994e5cfb129110c150fb6ea802a87#file-donationandsponsorshipagreement-md)。
=======
<details><summary># 捐赠与赞助</summary>
![alipay](https://user-images.githubusercontent.com/1733254/110204402-bbcabc80-7ead-11eb-8bbc-9be2041214c2.png)
![wechat](https://user-images.githubusercontent.com/1733254/110204405-bd948000-7ead-11eb-9c8a-13094e252d7a.png)

付款代表您同意就捐赠与赞助事项与我[约定](https://gist.github.com/CrazyBoyFeng/a53994e5cfb129110c150fb6ea802a87#file-donationandsponsorshipagreement-md)。
</details>

>>>>>>> a89c5788f74bea68fbc2a4eb581141baf9f8a545
