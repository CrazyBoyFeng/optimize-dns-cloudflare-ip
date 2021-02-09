# HuaweiCloud Optimize DNS Cloudflare IP
[CloudflareSpeedTest](https://github.com/XIU2/CloudflareSpeedTest) 脚本：查找最快 Cloudflare IP 并更新华为云域名解析记录。

## 如何使用
请先登录你的华为云账户，在云解析服务中添加你的域名或子域名的解析记录。  
_提示：华为云解析可以分地区按运营商线路解析。如果你使用该功能，请注意不同线路的 IP 不能重复。_

### 类 Unix
下载 `optimize-dns-cloudflare-ip.bash` 至 `CloudflareST` 所在目录。  
修改 `optimize-dns-cloudflare-ip.bash`，填写：域名 `domain`、域名 ID `zone_id`、账户 `account`、密码  `password`。  
执行 `optimize-dns-cloudflare-ip.bash`。

如需自动定时执行，请查阅 `cron` 相关知识。

### Windows
下载 `Optimize-DnsCloudflareIp.cmd` 和 `Optimize-DnsCloudflareIp.ps1` 至 `CloudflareST.exe` 所在目录。  
修改 `Optimize-DnsCloudflareIp.ps1`，填写：域名 `domain`、域名 ID `zone_id`、账户 `account`、密码  `password`。  
执行 `Optimize-DnsCloudflareIp.cmd`。

如需自动定时执行，请查阅任务计划相关知识。
