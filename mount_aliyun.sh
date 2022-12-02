#!/bin/sh
modprobe fuse 
mkdir /mnt/aliyun
umount -fl /mnt/aliyun 
killall "webdavfs"
sleep 3
/etc/storage/apps/webdavfs -D -ousername=admin,password=admin http://0.0.0.0:8080 /mnt/aliyun

