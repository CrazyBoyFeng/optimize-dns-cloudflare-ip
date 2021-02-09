Rem 本来我是想直接写成 Batch 批处理的，结果发现 CMD 不支持 2 KB 以上的变量，也难以处理 JSON 和 CSV 数据，于是只好写成 PowerShell 脚本。
@Echo off
Echo 请先去华为云解析后台增加一条按线路解析的A记录或AAAA记录。
Set domain=你的域名
Set zone_id=域名ID控制台可查
Set account=用户账户
Set password=用户密码

SetLocal EnableDelayedExpansion
Call :GetIP
Pause

:GetIP
    Echo Domain name: %domain%
    For /f "Skip=1 Tokens=2 Delims=[" %%a In ('Ping %domain% -n 1') Do (
	    For /f "Tokens=1 Delims=]" %%b In ("%%a") Do (
		    Set ip=%%b
	    )
    )
    If "%ip%"=="" (
        Echo Can not get the IP of %domain%
        Exit -B -1
    )
    Echo Current IP: %ip%
    If "%ip%" NEq "%ip:.=%" (
        Call :TestIPv4
    ) Else If "%ip%" NEq "%ip::=%" (
        Call :TestIPv6
    ) Else (
        Exit -B -1
    )
    Call :GetBest
Goto :EOF

:TestIPv4
    Echo 测速 IPv4
    Call :SearchRecordsetId
    Copy -Y ip.txt ip.tmp
    Echo.>>ip.tmp
    Echo %ip%/32>>ip.tmp
    Echo.
    CloudflareST.exe -sl 0.1 -p 0 -f ip.tmp
    Echo.
    Del -F -Q ip.tmp
Goto :EOF

:TestIPv6
    Echo 测速 IPv6
    Call :SearchRecordsetId
    Copy -Y ipv6.txt ip.tmp
    Echo.>>ip.tmp
    Echo %ip%/128>>ip.tmp
    Echo.
    CloudflareST.exe -p 0 -ipv6 -f ip.tmp
    Echo.
    Del -F -Q ip.tmp
Goto :EOF

:SearchRecordsetId
    echo 查找 IP 对应的记录集 ID
    Call :GetToken
    Rem TODO
Goto :EOF

:GetBest
Goto :EOF

:UpdateIP
Goto :EOF

:GetToken
    Echo 登录
    If Defined headers Goto :EOF
    Set body={\"auth\":{\"identity\":{\"methods\":[\"password\"],\"password\":{\"user\":{\"domain\":{\"name\":\"%account%\"},\"name\":\"%account%\",\"password\":\"%password%\"}}},\"scope\":{\"domain\":{\"name\":\"%account%\"}}}}
    curl -iks -X POST -H "Content-Type=application/json;charset=utf8" -d "%body%" https://iam.myhuaweicloud.com/v3/auth/tokens?nocatalog=true -o NUL -D - > headers.txt
    type headers.txt | find "X-Subject-Token: " > header.txt
    findstr "X-Subject-Token" headers.txt > header.txt
    set /p header= < header.txt
    Rem TODO
Goto :EOF