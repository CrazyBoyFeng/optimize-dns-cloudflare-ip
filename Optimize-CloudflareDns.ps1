#请先去华为云解析后台增加一条按线路解析的A记录或AAAA记录。
$domain = "你的域名"
$zone_id = "域名ID控制台可查"
$account = "用户账户"
$password = "用户密码"

function Get-Token { #登录
    If ($headers) { #非空
        Return
    }
    $body = @"
{
    "auth": {
        "identity": {
            "methods": [
                "password"
            ],
            "password": {
                "user": {
                    "domain": {
                        "name": "$account"//IAM用户所属账号名
                    },
                    "name": "$account",//IAM用户名
                    "password": "$password"//IAM用户密码
                }
            }
        },
        "scope": {
            "domain": {
                "name": "$account"//IAM用户所属账号名
            }
        }
    }
}
"@
    try {
        $response = Invoke-WebRequest -Uri "https://iam.myhuaweicloud.com/v3/auth/tokens?nocatalog=true" -ContentType "application/json;charset=utf8" -Method POST -Body $body
        $token = $response.Headers["X-Subject-Token"]
        $script:headers = @{"X-Auth-Token" = $token }
    }
    catch {
        $status = $_.Exception.Response.StatusCode.value__
        "Auth HTTP $status"
        Exit -1
    }
}

function Search-RecordsetId {
    #查找ip对应的记录集id
    Get-Token
    $response = Invoke-RestMethod -Uri "https://dns.myhuaweicloud.com/v2.1/recordsets?name=$domain&records=$ip" -Headers $headers
    If ($response.metadata.total_count = 0) {
        "No valid recordsets for $ip in $domain. If you update DNS just now, it will take a while to take effect."
        Exit -1
    }
    $script:recordset_id = $response.recordsets[0].id
}

function Test-IPv4 {
    Search-RecordsetId
    Copy-Item ip.txt ip.tmp
    Add-Content -Path ip.tmp -Value "`r`n$ip/32"
    "`r`n"
    &".\CloudflareST.exe" -sl 0.1 -p 0 -f ip.tmp
    "`r`n"
    Remove-Item ip.tmp
}

function Test-IPv6 {
    Search-RecordsetId
    Copy-Item ipv6.txt ipv6.tmp
    Add-Content -Path ipv6.tmp "`r`n$ip/64"
    "`r`n"
    &".\CloudflareST.exe" -p 0 -ipv6 -f ipv6.tmp
    "`r`n"
    Remove-Item ipv6.tmp
}

function Update-IP {
    Get-Token
    $body = @"
{
    "records": ["$best"]
}
"@
    Invoke-RestMethod -Uri "https://dns.myhuaweicloud.com/v2.1/zones/$zone_id/recordsets/$recordset_id" -Headers $headers -Method PUT -Body $body
}

function Get-Best {
    $script:best = (Import-CSV result.csv)[0].psobject.properties.value[0]
    If (!$best) {
        "Can not get the best Cloudflare IP"
        Exit -1
    }
    "Best Cloudflare IP: $best"
    If ("$ip" -eq "$best") {
        Exit
    }
    Update-IP
}

function Get-IP {
    "Domain name: $domain"
    $ping = New-Object System.Net.NetworkInformation.Ping
    $script:ip = $($ping.Send($domain).Address).IPAddressToString
    If (!$ip) {
        "Can not get the IP of $domain"
        Exit -1
    }
    "Current IP: $ip"
    If ($ip.Contains(".")) {
        Test-IPv4
    }
    ElseIf ($ip.Contains(":")) {
        Test-IPv6
    }
    Else {
        "Error"
        Exit -1
    }
    Get-Best
}

Get-IP
pause