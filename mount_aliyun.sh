#!/bin/sh
basedir=$(cd $(dirname $0) && pwd)

git_root_1=simonchen/webdavfs
git_root_2=simonchen/libfuse
get_latest_release() {
  git_root=$1
  output=$(curl --silent "https://api.github.com/repos/$git_root/releases/latest" | # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/')                                    # Pluck JSON value
  
  echo $output
}
latest_ver_1=$(get_latest_release "$git_root_1")
latest_ver_2=$(get_latest_release "$git_root_2")

if [ -z "$latest_ver_1" ]; then
	logger -s -t "【 ERROR 】" "Could not found latest version from $git_rt_1, exit!"
	exit 0
else
	logger -s -t "Found latest version" "$latest_ver_1"
fi

if [ -z "$latest_ver_2" ]; then
        logger -s -t "【 ERROR 】" "Could not found latest version from $git_ot_2, exit!"
        exit 0
else
        logger -s -t "Found latest version" "$latest_ver_2"
fi

download_url_1=https://github.com/$git_root_1/releases/download/$latest_ver_1/webdavfs-linux-mipsle.tar.gz
download_url_2=https://github.com/$git_root_2/releases/download/$latest_ver_2/mipsel-unknown-linux-gnu-bin.tar.gz

tmp_dir=/tmp/etc_storage_apps

logger -s -t "【 创建临时目录 】:" ""$tmp_dir""
mkdir "$tmp_dir"

logger -s -t "【 下 载 】" "$download_url_1"
path_1=$tmp_dir/webdavfs.tar.gz
wget "$download_url_1" -O "$path_1"
if [ "$?" != "0" ]; then
	logger -s -t "【下载失败 】" "exit 0"
	exit 0
fi
tar -xzf "$path_1" webdavfs -C "$tmp_dir"
rm "$path_1"

logger -s -t "【 下 载 】" "$download_url_2" 
path_2=$tmp_dir/libfuse.tar.gz
wget "$download_url_2" -O "$path_2"
if [ "$?" != "0" ]; then
        logger -s -t "【下载失败 】" "exit 0"
        exit 0
fi
tar -xzf "$path_2" ./fusermount -C "$tmp_dir"
rm "$path_2"

modprobe fuse 
mkdir /mnt/aliyun
umount -fl /mnt/aliyun 
killall "webdavfs"
sleep 3
echo 35 > /proc/sys/vm/pagecache_ratio # by default, it's 50% ratio with page cache, it's too big!
$tmp_dir/webdavfs -D -ousername=admin,password=admin,usepagecache,readbuff=1048576 http://0.0.0.0:8080 /mnt/aliyun

