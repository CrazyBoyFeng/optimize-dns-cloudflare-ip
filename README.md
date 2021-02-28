# HuaweiCloud Optimize DNS Cloudflare IP
[CloudflareSpeedTest](https://github.com/XIU2/CloudflareSpeedTest) 脚本：查找最快 Cloudflare IP 并更新华为云域名解析记录。

## 如何使用
请先登录你的华为云账户，在云解析服务中添加你的域名或子域名的解析记录。  
_提示：华为云解析可以分地区按运营商线路解析。如果你使用该功能，请注意不同线路的 IP 不能重复。_

### 类 Unix
下载 `optimize-dns-cloudflare-ip-wget.bash` 或 `optimize-dns-cloudflare-ip-curl.bash` 至 `CloudflareST` 所在目录。  
修改 `optimize-dns-cloudflare-ip*.bash`，填写：域名 `domain`、域名 ID `zone_id`、账户 `account`、密码  `password`。  
执行 `optimize-dns-cloudflare-ip*.bash`。

如需自动定时执行，请查阅 `cron` 相关知识。

### Windows
下载 `Optimize-DnsCloudflareIP.PS1` 和 `Optimize-DnsCloudflareIP.Cmd` 至 `CloudflareST.exe` 所在目录。  
修改 `Optimize-DnsCloudflareIP.PS1`，填写：域名 `domain`、域名 ID `zone_id`、账户 `account`、密码  `password`。  
执行 `Optimize-DnsCloudflareIP.Cmd`。默认常规窗口，脚本结束后会暂停，可通过参数调整：
* 启动器参数 `Optimize-DnsCloudflareIP.Cmd Minimized` 最小化窗口，脚本仅在错误时暂停。
* 启动器参数 `Optimize-DnsCloudflareIP.Cmd Hidden` 隐藏窗口，脚本会在结束后退出。可通过退出码判断执行结果。
* 通用参数 `-ExitEnd` 正常结束时立即退出。最小化和隐藏窗口启动模式使用了此参数。
* 通用参数 `-ExitError` 发生错误时立即退出。最小化窗口启动模式使用了此参数。

如需自动定时执行，请查阅任务计划相关知识。