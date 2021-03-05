#!/bin/bash
#请先去华为云解析后台增加一条A记录或AAAA记录。
domain = "你的域名（可以是子域名）"
zone_id = "域名 ID（控制台可查）"
account = "用户账户"
password = "用户密码"
#以上为需要手动填写的内容。
cd `dirname $BASH_SOURCE`
curl = `command -v curl 2> /dev/null`

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
    cp -f ipv6.txt ipv6.tmp
    echo "" >> ipv6.tmp
    echo "$ip/128" >> ipv6.tmp
    ./CloudflareST -p 0 -ipv6 -f ipv6.tmp
    rm -f ipv6.tmp
}

function get_header { #登录
    local body = "{\"auth\":{\"identity\":{\"methods\":[\"password\"],\"password\":{\"user\":{\"domain\":{\"name\":\"$account\"//IAM用户所属账号名},\"name\":\"$account\",//IAM用户名\"password\":\"$password\"//IAM用户密码}}},\"scope\":{\"domain\":{\"name\":\"$account\"//IAM用户所属账号名}}}}"
    local link = "https://iam.myhuaweicloud.com/v3/auth/tokens?nocatalog=true"
    if [ $curl ] ; then
        response = `curl -fiks -X POST -o /dev/null -H "Content-Type: application/json" -d "$body" $link -D -`
    else
        response = `wget -O /dev/null -qS --body-data "$body" --header "Content-Type: application/json" --method POST --no-check-certificate $link`
    fi
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
    local link = "https://dns.myhuaweicloud.com/v2.1/recordsets?name=$domain&records=$ip"
    if [ $curl ] ; then
        response = `curl -fiks -H "$header" $link`
    else
        response = `wget -O- -q --header "$header" --no-check-certificate $link`
    fi
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
    best = `sed -n 2p result.csv | cut -d, -f1`
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
    local link = "https://dns.myhuaweicloud.com/v2.1/zones/$zone_id/recordsets/$recordset_id"
    if [ $curl ] ; then
        response = `curl -fiks -X PUT -H "$header" -d "$body" $link`
    else
        response = `wget -O- -q --method PUT --header "$header" --body-data "$body" --no-check-certificate $link`
    fi
    if [ ! $response ] ; then
        echo "Recordset error"
        exit 41
    fi
    rm -f recordset.json
    echo "$response" > recordset.json
    echo "Recordset OK"
}