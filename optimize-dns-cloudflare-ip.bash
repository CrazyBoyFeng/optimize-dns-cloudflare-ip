#!/bin/bash
#请先去华为云解析后台增加一条A记录或AAAA记录。
domain = "你的域名（可以是子域名）"
zone_id = "域名ID（控制台可查）"
account = "用户账户"
password = "用户密码"

cd `dirname $BASH_SOURCE`

get_ip
exit

function get_ip {
    echo "Domain name: $domain"
    ip=`ping -c 1 $domain | grep -o ' ([^)]*' | grep -o '[^ (]*$'`
    if [ ! $ip ]; then
        echo "Can not get the IP of $domain"
        exit 1
    fi
    echo "Current IP: $ip"
    case $ip in 
    *"."*)
        test_ipv4;;
    *":"*)
        test_ipv6;;
    *)
        exit 2;;
    esac
    get_best
}

function test_ipv4 {
    search_recordset_id
    cp -f ip.txt ip.tmp
    echo "" >> ip.tmp
    echo "$ip/32" >> ip.tmp
    echo
    ./CloudflareST.exe -tl 500 -sl 0.1 -p 0 -f ip.tmp
    rm -f ip.tmp
}

function test_ipv6 {
    search_recordset_id
    cp -f ipv6.txt ipv6.tmp
    echo "" >> ipv6.tmp
    echo "$ip/128" >> ipv6.tmp
    echo
    ./CloudflareST -p 0 -ipv6 -f ipv6.tmp
    rm -f ipv6.tmp
}

function get_token { #登录
    if [ $header ] ; then #非空
        return
    fi
    echo
    local body = "{\"auth\":{\"identity\":{\"methods\":[\"password\"],\"password\":{\"user\":{\"domain\":{\"name\":\"$account\"//IAM用户所属账号名},\"name\":\"$account\",//IAM用户名\"password\":\"$password\"//IAM用户密码}}},\"scope\":{\"domain\":{\"name\":\"$account\"//IAM用户所属账号名}}}}"
    #local response = `curl -fiks -X POST -o /dev/null -H "Content-Type: application/json" -d "$body" https://iam.myhuaweicloud.com/v3/auth/tokens?nocatalog=true -D -`
    #有些系统默认没装curl，所以用wget替代
    local response = `wget -O /dev/null -qS --body-data "$body" --header "Content-Type: application/json" --method POST --no-check-certificate https://iam.myhuaweicloud.com/v3/auth/tokens?nocatalog=true`
    local token = `echo $response | grep -o 'X-Subject-Token: \w*'` #截取 header
    if [ $token ] ; then #非空
        echo "Auth as $account successful"
    else
        echo "Auth as $account failed"
        exit 11
    fi
    #header = ${token/Subject/Auth} #bash only
    local token = `echo "$token" | grep -o '\w*$'` #截取 header value
    header = "X-Auth-Token: $token"
}

function search_recordset_id { #查找ip对应的记录集id
    get_token
    #local response=`curl -fiks -H "$headers" https://dns.myhuaweicloud.com/v2.1/recordsets?name=$domain&records=$ip`
    local response = `wget -O- -q --header "$header" --no-check-certificate https://dns.myhuaweicloud.com/v2.1/recordsets?name=$domain&records=$ip`
    #recordset_id = ${recordset_id##*\"recordsets\":\[\{\"id\":\"} #bash only
    #recordset_id = ${recordset_id%%\"*} #bash only
    recordset_id = `echo "$response" | grep -o '"recordsets":\[{"id":"[^"]*' | grep -o '[^"]*$'`
    if [ ! $recordset_id ] ; then #空
        echo
        echo "No valid recordsets with $ip for $domain.If it has been updated just now, please wait until it takes effect"
        exit 21
    fi
}

function get_best {
    echo
    #best = `sed -n 2p result.csv | grep -o '^[^,]*'`
    best = `sed -n 2p result.csv | cut -d, -f1`
    if [ ! $best ] ; then
        echo "Can not get the best Cloudflare IP"
        exit 31
    fi
    echo "Best Cloudflare IP: $best"
    if [ "$ip" == "$best" ] ; then
        exit
    fi
    update_ip
}

function update_ip {
    get_token
    local body = "{\"records\":[\"$best\"]}"
    #local response = `curl -fiks -X PUT -H "$headers" -d "$body" https://dns.myhuaweicloud.com/v2.1/zones/$zone_id/recordsets/$recordset_id`
    local response = `wget -O- -q --header "$header" --method PUT --no-check-certificate https://dns.myhuaweicloud.com/v2.1/zones/$zone_id/recordsets/$recordset_id`
    if [ $response ] ; then
        rm -f recordset.json
        echo "$response" > recordset.json
        echo "Recordset OK"
    else
        echo "Recordset error"
        exit 41
    fi
}