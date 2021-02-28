#!/bin/bash
#请先去华为云解析后台增加一条A记录或AAAA记录。
domain = "你的域名（可以是子域名）"
zone_id = "域名ID（控制台可查）"
account = "用户账户"
password = "用户密码"

cd `dirname $BASH_SOURCE`

get_ip
echo
get_header
echo
search_recordset_id
case $ip in 
*"."*)
    test_ipv4;;
*":"*)
    test_ipv6;;
*)
    exit 2;;
esac
echo
get_best
echo
update_ip
exit

function get_ip {
    echo "Domain name: $domain"
    ip=`ping -c 1 $domain | grep -o ' ([^)]*' | grep -o '[^ (]*$'`
    if [ ! $ip ]; then
        echo "Can not get the IP of $domain"
        exit 1
    fi
    echo "Current IP: $ip"
}

function test_ipv4 {
    cp -f ip.txt ip.tmp
    echo "" >> ip.tmp
    echo "$ip/32" >> ip.tmp
    ./CloudflareST.exe -tl 500 -sl 0.1 -p 0 -f ip.tmp
    rm -f ip.tmp
}

function test_ipv6 {
    cp -f ipv6.txt ip.tmp
    echo "" >> ip.tmp
    echo "$ip/128" >> ip.tmp
    ./CloudflareST -p 0 -ipv6 -f ip.tmp
    rm -f ip.tmp
}

function get_header { #登录
    if [ $header ] ; then #非空
        return
    fi
    local body = "{\"auth\":{\"identity\":{\"methods\":[\"password\"],\"password\":{\"user\":{\"domain\":{\"name\":\"$account\"//IAM用户所属账号名},\"name\":\"$account\",//IAM用户名\"password\":\"$password\"//IAM用户密码}}},\"scope\":{\"domain\":{\"name\":\"$account\"//IAM用户所属账号名}}}}"
    local response = `curl -fiks -X POST -o /dev/null -H "Content-Type: application/json" -d "$body" https://iam.myhuaweicloud.com/v3/auth/tokens?nocatalog=true -D -`
    local token = `echo $response | grep -o 'X-Subject-Token: \w*'` #截取 header
    if [ ! $token ] ; then #空
        echo "Auth as $account failed"
        exit 11
    fi
    echo "Auth as $account successful"
    #header = ${token/Subject/Auth} #bash only
    local token = `echo "$token" | grep -o '\w*$'` #截取 header value
    header = "X-Auth-Token: $token"
}

function search_recordset_id { #查找ip对应的记录集id
    local response=`curl -fiks -H "$headers" https://dns.myhuaweicloud.com/v2.1/recordsets?name=$domain&records=$ip`
    #recordset_id = ${recordset_id##*\"recordsets\":\[\{\"id\":\"} #bash only
    #recordset_id = ${recordset_id%%\"*} #bash only
    recordset_id = `echo "$response" | grep -o '"recordsets":\[{"id":"[^"]*' | grep -o '[^"]*$'`
    if [ ! $recordset_id ] ; then #空
        echo "No valid recordsets with $ip for $domain.If it has been updated just now, please wait until it takes effect"
        exit 21
    fi
}

function get_best {
    #best = `sed -n 2p result.csv | grep -o '^[^,]*'`
    best = `sed -n 2p result.csv | cut -d, -f1` #cut 效率更高
    if [ ! $best ] ; then
        echo "Can not get the best Cloudflare IP"
        exit 31
    fi
    echo "Best Cloudflare IP: $best"
    if [ "$ip" == "$best" ] ; then
        exit
    fi
}

function update_ip {
    local body = "{\"records\":[\"$best\"]}"
    local response = `curl -fiks -X PUT -H "$headers" -d "$body" https://dns.myhuaweicloud.com/v2.1/zones/$zone_id/recordsets/$recordset_id`
    if [ ! $response ] ; then
        echo "Recordset error"
        exit 41
    fi
    rm -f recordset.json
    echo "$response" > recordset.json
    echo "Recordset OK"
}