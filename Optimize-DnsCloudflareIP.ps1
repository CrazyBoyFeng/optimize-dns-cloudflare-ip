Param([switch]$ExitEnd,[switch]$ExitError)
#请先去华为云解析后台增加一条A记录或AAAA记录。
$domain = "你的域名（可以是子域名）"
$zone_id = "域名ID（控制台可查）"
$account = "用户账户"
$password = "用户密码"

Set-Location -Path $PSScriptRoot

function Exit-Error {
    Param ($Code)
    If (!$ExitError) {
        Pause
    }
    Exit $Code
}

function Get-IP {
    Param($Domain)
    Write-Host "Domain name: $Domain"
    $ip = [System.Net.Dns]::GetHostAddresses($Domain)[0].IPAddressToString
    If (!$ip) {
        Write-Error "Can not get the IP of $Domain"
        Exit-Error 1
    }
    Write-Host "Current IP: $ip"
    Return $ip
}

function Get-Token {
    Param($Account,$Password)
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
                        "name": "$Account"//IAM用户所属账号名
                    },
                    "name": "$Account",//IAM用户名
                    "password": "$Password"//IAM用户密码
                }
            }
        },
        "scope": {
            "domain": {
                "name": "$Account"//IAM用户所属账号名
            }
        }
    }
}
"@
    Try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri "https://iam.myhuaweicloud.com/v3/auth/tokens?nocatalog=true" -ContentType "application/json" -Method POST -Body $body
        $token = $response.Headers["X-Subject-Token"]
        If (!$token) {
            Write-Error "Auth as $Account failed"
            Exit-Error 11
        }
        Write-Host "Auth as $Account successful"
        Return $token
    } Catch {
        Write-Error $_.Exception.Message
        Exit-Error 12
    }
}

function Get-Headers {
    Param($Account,$Password)
    If (!$headers) {
        $token = Get-Token $Account $Password
        $script:headers = @{"X-Auth-Token" = $token }
    }
    Return $headers
}

function Search-RecordsetId {
    Param($Headers,$Domain,$IP)
    $response = Invoke-RestMethod -Uri "https://dns.myhuaweicloud.com/v2.1/recordsets?name=$Domain&records=$IP" -Headers $Headers
    $recordset_id = $response.recordsets[0].id
    If (!$recordset_id) {
        Write-Error "No valid recordsets with $IP for $Domain. If it has been updated just now, please wait until it takes effect."
        Exit-Error 21
    }
    Return $recordset_id
}

function Test-IPv4 {
    Param ($IP)
    Copy-Item ip.txt ip.tmp
    Add-Content -Path ip.tmp -Value "`r`n$IP/32"
    &".\CloudflareST.exe" -tl 500 -sl 0.1 -p 0 -f ip.tmp
    Remove-Item ip.tmp
}

function Test-IPv6 {
    Param ($IP)
    Copy-Item ipv6.txt ip.tmp
    Add-Content -Path ip.tmp "`r`n$IP/128"
    &".\CloudflareST.exe" -p 0 -ipv6 -f ip.tmp
    Remove-Item ip.tmp
}

function Exit-End {
    If (!$ExitEnd) {
        Pause
    }
    Exit
}

function Get-Best {
    Param($IP)
    $best = (Import-CSV result.csv)[0].psobject.properties.value[0]
    If (!$best) {
        Write-Error "Can not get the best Cloudflare IP"
        Exit-Error 31
    }
    Write-Host "Best Cloudflare IP: $best"
    If ("$IP" -Eq "$best") {
        Exit-End
    }
    Return $best
}

function Update-IP {
    Param($Headers,$ZoneId,$RecordsetId,$Best)
    $body = @"
{
    "records": ["$Best"]
}
"@
    try {
        $response = Invoke-RestMethod -Uri "https://dns.myhuaweicloud.com/v2.1/zones/$ZoneId/recordsets/$RecordsetId" -Headers $Headers -Method PUT -Body $body
        Write-Output $response | Out-File -FilePath recordset.txt
        $response
    } catch {
        Write-Error $_.Exception.Message
        Exit-Error 41
    }
    Exit-End
}

$ip = Get-IP $domain
Write-Host ""
$headers = Get-Headers $account $password
Write-Host ""
$recordset_id = Search-RecordsetId $headers $domain $ip
If ($ip.Contains(".")) {
    Test-IPv4 $ip
} ElseIf ($ip.Contains(":")) {
    Test-IPv6 $ip
}
Write-Host ""
$best = Get-Best $ip
Write-Host ""
Update-IP $headers $zone_id $recordset_id $best
