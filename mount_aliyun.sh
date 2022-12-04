#!/bin/sh
basedir=$(cd $(dirname $0) && pwd)

modprobe fuse 
mkdir /mnt/aliyun
umount -fl /mnt/aliyun 
killall "webdavfs"
sleep 3
echo 35 > /proc/sys/vm/pagecache_ratio # by default, it's 50% ratio with page cache, it's too big!
$basedir/webdavfs -D -ousername=admin,password=admin,ro,async_read,readbuff=1048576 http://0.0.0.0:8080 /mnt/aliyun

