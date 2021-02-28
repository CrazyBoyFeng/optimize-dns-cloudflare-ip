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
下载 `Optimize-DnsCloudflareIp.ps1` 和 `*.lnk` 至 `CloudflareST.exe` 所在目录。  
修改 `Optimize-DnsCloudflareIp.ps1`，填写：域名 `domain`、域名 ID `zone_id`、账户 `account`、密码  `password`。  
执行快捷方式文件。其中：
* `Optimize-DnsCloudflareIP.lnk` 正常模式，脚本结束后会暂停。
* `Optimize-DnsCloudflareIP Minimized.lnk` 最小化模式，脚本仅在错误时暂停。
* `Optimize-DnsCloudflareIP Hidden.lnk`，隐藏模式且脚本会在结束后退出。可通过退出码判断执行结果。

如需自动定时执行，请查阅任务计划相关知识。

#### 参数说明
* `-ExitEnd` 脚本正常结束时立即退出。隐藏模式使用了此参数。
* `-ExitError` 脚本发生错误时立即退出。最小化模式和隐藏模式使用了此参数。
如需修改参数，可直接修改快捷方式属性。