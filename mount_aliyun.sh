#!/bin/sh
basedir=$(cd $(dirname $0) && pwd)

modprobe fuse 
mkdir /mnt/aliyun
umount -fl /mnt/aliyun 
killall "webdavfs"
sleep 3
$basedir/webdavfs -D -ousername=admin,password=admin,ro,async_read http://0.0.0.0:8080 /mnt/aliyun

