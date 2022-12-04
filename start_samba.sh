#!/bin/sh

basedir=$(cd $(dirname $0) && pwd)

logger -t "【启动SAMBA】" "samba"
killall "smbd"
rm /var/run/smbd-smb.conf.pid
mkdir /etc/samba
/bin/smbpasswd admin admin
/sbin/smbd -D -s $basedir/smb.conf
killall "nmbd"
/sbin/nmbd -D -s $basedir/smb.conf

logger -t "【SAMBA服务器】" "失效SAMBA访问"
while ip_rule_num=$(iptables -L INPUT --line-numbers | grep -E -i -w 'netbios|icmp' | cut -d" " -f1)
do
    if [ -z $ip_rule_num ]; then
        break
    fi
    for n in $ip_rule_num; do
        iptables -D INPUT $n
        echo delete ip rule no.$n - ok
        break
    done
done

logger -t "【SAMBA服务器】" "允许SAMBA访问"
iptables -I INPUT 1 -p udp -m multiport --dport 137,138 -j ACCEPT 
iptables -I INPUT 1 -p tcp -m state --state NEW,RELATED,ESTABLISHED -m multiport --dport 139,445 -j ACCEPT
iptables -I INPUT -p icmp -j ACCEPT
