#请先去华为云解析后台增加一条A记录或AAAA记录。
$domain = "你的域名（可以是子域名）"
$zone_id = "域名ID（控制台可查）"
$account = "用户账户"
$password = "用户密码"

Set-Location -Path $PSScriptRoot

Get-IP
Exit

function Get-IP {
    "Domain name: $domain"
    $ping = New-Object System.Net.NetworkInformation.Ping
    $script:ip = $($ping.Send($domain).Address).IPAddressToString
    If (!$ip) {
        "Can not get the IP of $domain"
        Exit 1
    }
    "Current IP: $ip"
    If ($ip.Contains(".")) {
        Test-IPv4
    }
    ElseIf ($ip.Contains(":")) {
        Test-IPv6
    }
    Else {
        Exit 2
    }
    Get-Best
}


function Test-IPv4 {
    Search-RecordsetId
    Copy-Item ip.txt ip.tmp
    Add-Content -Path ip.tmp -Value "`r`n$ip/32"
    ""
    &".\CloudflareST.exe" -tl 500 -sl 0.1 -p 0 -f ip.tmp
    Remove-Item ip.tmp
}

function Test-IPv6 {
    Search-RecordsetId
    Copy-Item ipv6.txt ipv6.tmp
    Add-Content -Path ipv6.tmp "`r`n$ip/128"
    ""
    &".\CloudflareST.exe" -p 0 -ipv6 -f ipv6.tmp
    Remove-Item ipv6.tmp
}

function Get-Token {
    #登录
    If ($headers) {
        #非空
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
        $response = Invoke-WebRequest -Uri "https://iam.myhuaweicloud.com/v3/auth/tokens?nocatalog=true" -ContentType "application/json" -Method POST -Body $body
        $token = $response.Headers["X-Subject-Token"]
        If ($token) {
            $script:headers = @{"X-Auth-Token" = $token }
        }
    }
    catch {
        "`r`nAuth: $_.Exception"
        Exit 11
    }
    If ($headers) {
        "`r`nAuth as $account successful"
    }
    Else {
        "`r`nAuth as $account failed"
        Exit 12
    }
}

function Search-RecordsetId {
    #查找ip对应的记录集id
    Get-Token
    $response = Invoke-RestMethod -Uri "https://dns.myhuaweicloud.com/v2.1/recordsets?name=$domain&records=$ip" -Headers $headers
    $script:recordset_id = $response.recordsets[0].id
    If (!$recordset_id) {
        #空
        "`r`nNo valid recordsets with $ip for $domain. If it has been updated just now, please wait until it takes effect."
        Exit 21
    }
}

function Get-Best {
    $script:best = (Import-CSV result.csv)[0].psobject.properties.value[0]
    If (!$best) {
        "`r`nCan not get the best Cloudflare IP"
        Exit 31
    }
    "`r`nBest Cloudflare IP: $best"
    If ("$ip" -eq "$best") {
        Exit
    }
    Update-IP
}

function Update-IP {
    Get-Token
    $body = @"
{
    "records": ["$best"]
}
"@
    try {
        $response = Invoke-RestMethod -Uri "https://dns.myhuaweicloud.com/v2.1/zones/$zone_id/recordsets/$recordset_id" -Headers $headers -Method PUT -Body $body
        $response | Out-File -FilePath recordset.txt
        $response
    }
    catch {
        "`r`nRecordset: $_.Exception"
        Exit 41
    }
}