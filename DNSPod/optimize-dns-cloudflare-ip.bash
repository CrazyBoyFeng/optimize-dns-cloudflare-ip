#!/bin/bash
#请先去 DNSPod 后台增加一条“动态 DNS 记录”然后填写以下参数：
sub_domain = "你的域名（可以是子域名）"
domain = "你的主域名"
#以下两项从控制台生成 https://console.dnspod.cn/account_id/token
account_id = "ID"
token = "Token"
#以上为需要手动填写的内容。
cd `dirname $BASH_SOURCE`
curl = `command -v curl 2> /dev/null`

get_ip
headers = "login_token=$account_id,$token&lang=cn&format=json&domain=$domain&sub_domian=$sub_domain"
echo
search_record
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
    echo "Domain name: $sub_domain"
    ip=`ping -c 1 $sub_domain | grep -o ' ([^)]*' | grep -o '[^ (]*$'`
    if [ ! $ip ]; then
        echo "Can not get the IP of $sub_domain"
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

function search_record { #查找ip对应的记录集id
    local link = "https://dnsapi.cn/Record.List"
    local body = "$headers&keyword=$IP&length=1"
    if [ $curl ] ; then
        response = `curl -fiks -X POST -d "$body" $link`
    else
        response = `wget -O- -q --method POST --body-data "$body" --no-check-certificate $link
    fi
    #records = ${recordset_id##*\"records\":\[\{\"id\":\"} #bash only
    #record_id = ${records%%\"*} #bash only
    record_id = `echo "$response" | grep -o '"records":\[{"id":"[^"]*' | grep -o '[^"]*$'`
    record_line_id = `echo "$response" | grep -o '"line_id":"[^"]*' | grep -o '[^"]*$'`
    if [ ! $recordset_id ] ; then #空
        echo "No valid records with $ip for $sub_domain. If it has been updated just now, please wait until it takes effect"
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
    local body = "$headers&record_id=$record_id&record_line_id=$record_line_id&value=$best"
    local link = "https://dnsapi.cn/Record.Ddns"
    if [ $curl ] ; then
        response = `curl -fiks -X POST -d "$body" $link`
    else
        response = `wget -O- -q --method POST --body-data "$body" --no-check-certificate $link
    fi
    if [ ! $response ] ; then
        echo "Record error"
        exit 41
    fi
    rm -f record.json
    echo "$response" > record.json
    echo "Record OK"
}