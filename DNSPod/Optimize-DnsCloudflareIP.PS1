#请先去 DNSPod 后台增加一条 A 或 AAAA 记录然后填写以下参数：
$sub_domain = "你的主机记录（不含主域名部分）若只有主域名则留空或删除该参数"
$domain = "你的主域名"
#以下两项从控制台生成 https://console.dnspod.cn/account_id/token
$account_id = "ID"
$token = "Token"
#以上为需要手动填写的内容。
Set-Location -Path $PSScriptRoot

function Get-IP {
    Param($Domain,$SubDomain)
    If ($sub_domain) {
        $name = "$SubDomain.$Domain"
    } Else {
        $name = $Domain
    }
    Write-Host "Domain name: $name"
    $ip = [System.Net.Dns]::GetHostAddresses($name)[0].IPAddressToString
    If (!$ip) {
        Write-Error "Can not get the IP of $name"
        Exit 1
    }
    Write-Host "Current IP: $ip"
    Return $ip
}

function Search-Record {
    Param($Headers,$IP)
    $body = "$Headers&keyword=$IP&length=1"
    $response = Invoke-RestMethod -Uri "https://dnsapi.cn/Record.List" -Method POST -Body $body
    $record = $response.records[0]
    If (!$record) {
        Write-Error "No valid records with $IP. If it has been updated just now, please wait until it takes effect."
        Exit 21
    }
    Return $record.id,$record.line_id
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

function Get-Best {
    Param($IP)
    $best = (Import-CSV result.csv)[0].psobject.properties.value[0]
    If (!$best) {
        Write-Error "Can not get the best Cloudflare IP"
        Exit 31
    }
    Write-Host "Best Cloudflare IP: $best"
    If ("$IP" -Eq "$best") {
        Exit
    }
    Return $best
}

function Update-IP {
    Param($Headers,$RecordId,$RecordLineId,$IP)
    $body = "$Headers&record_id=$RecordId&record_line_id=$RecordLineId&value=$IP"
    try {
        $response = Invoke-RestMethod -Uri "https://dnsapi.cn/Record.Ddns" -Method POST -Body $body
        Write-Output $response | Out-File -FilePath record.txt
        Write-Host $response
    } catch {
        Write-Error $_.Exception.Message
        Exit 41
    }
    Exit
}

$ip = Get-IP $domain $sub_domain
if ($sub_domain) {
    $rr = $sub_domain
} Else {
    $rr = "@"
}
$headers = "login_token=$account_id,$token&lang=cn&format=json&domain=$domain&sub_domain=$rr"
Write-Host ""
$record_id,$record_line_id = Search-Record $headers $ip
If ($ip.Contains(".")) {
    Test-IPv4 $ip
} ElseIf ($ip.Contains(":")) {
    Test-IPv6 $ip
}
Write-Host ""
$best = Get-Best $ip
Write-Host ""
Update-IP $headers $record_id $record_line_id $best
