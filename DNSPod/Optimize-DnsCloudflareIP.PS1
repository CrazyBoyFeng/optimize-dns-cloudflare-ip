Param([switch]$ExitEnd,[switch]$ExitError)
#����ȥ DNSPod ��̨����һ������̬ DNS ��¼��Ȼ����д���²�����
$sub_domain = "�����������������������"
$domain = "���������"
#��������ӿ���̨���� https://console.dnspod.cn/account_id/token
$account_id = "ID"
$token = "Token"
#����Ϊ��Ҫ�ֶ���д�����ݡ�
Set-Location -Path $PSScriptRoot

function Exit-Error {
    Param ($Code)
    If (!$ExitError) {
        Pause
    }
    Exit $Code
}

function Get-IP {
    Param($SubDomain)
    Write-Host "Domain name: $SubDomain"
    $ip = [System.Net.Dns]::GetHostAddresses($SubDomain)[0].IPAddressToString
    If (!$ip) {
        Write-Error "Can not get the IP of $SubDomain"
        Exit-Error 1
    }
    Write-Host "Current IP: $ip"
    Return $ip
}

function Search-Record {
    Param($Headers,$IP)
    $body = "$headers&keyword=$IP&length=1"
    $response = Invoke-RestMethod -Uri "https://dnsapi.cn/Record.List" -Method POST -Body $body
    $record = $response.records[0]
    If (!$record) {
        Write-Error "No valid records with $IP. If it has been updated just now, please wait until it takes effect."
        Exit-Error 21
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
    Param($Headers,$RecordId,$RecordLineId,$IP)
    $body = "$headers&record_id=$RecordId&record_line_id=$RecordLineId&value=$IP"
    try {
        $response = Invoke-RestMethod -Uri "https://dnsapi.cn/Record.Ddns" -Method POST -Body $body
        Write-Output $response | Out-File -FilePath record.txt
        $response
    } catch {
        Write-Error $_.Exception.Message
        Exit-Error 41
    }
    Exit-End
}

$ip = Get-IP $sub_domain
$headers = "login_token=$account_id,$token&lang=cn&format=json&domain=$domain&sub_domain=$sub_domain"
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