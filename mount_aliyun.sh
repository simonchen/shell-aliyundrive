#!/bin/sh
#copyright by simonchen

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

tmp_dir=/tmp/etc_storage_apps

logger -s -t "【 创建临时目录 】:" ""$tmp_dir""
mkdir "$tmp_dir" 2>/dev/null

export PATH="$PATH:$tmp_dir"

if [ ! -f "$tmp_dir/webdavfs" ]; then
  latest_ver_1=$(get_latest_release "$git_root_1")
  if [ -z "$latest_ver_1" ]; then
        logger -s -t "【 ERROR 】" "Could not found latest version from $git_rt_1, exit!"
        exit 1
  else
        logger -s -t "Found latest version" "$latest_ver_1"
  fi
  download_url_1=https://github.com/$git_root_1/releases/download/$latest_ver_1/webdavfs-linux-mipsle.tar.gz
  logger -s -t "【 下 载 】" "$download_url_1"
  path_1=$tmp_dir/webdavfs.tar.gz
  wget "$download_url_1" -O "$path_1"
  if [ "$?" != "0" ]; then
	logger -s -t "【下载失败 】" "exit"
	exit 1
  fi
  tar -xzf "$path_1" webdavfs -C "$tmp_dir"
  rm -f "$path_1"
fi

if [ ! -f "$tmp_dir/fusermount" ]; then
  latest_ver_2=$(get_latest_release "$git_root_2")
  if [ -z "$latest_ver_2" ]; then
        logger -s -t "【 ERROR 】" "Could not found latest version from $git_ot_2, exit!"
        exit 1
  else
        logger -s -t "Found latest version" "$latest_ver_2"
  fi
  download_url_2=https://github.com/$git_root_2/releases/download/$latest_ver_2/mipsel-unknown-linux-gnu-bin.tar.gz
  logger -s -t "【 下 载 】" "$download_url_2" 
  path_2=$tmp_dir/libfuse.tar.gz
  wget "$download_url_2" -O "$path_2"
  if [ "$?" != "0" ]; then
        logger -s -t "【下载失败 】" "exit"
        exit 1
  fi
  tar -xzf "$path_2" ./fusermount -C "$tmp_dir"
  rm -f "$path_2"
fi

max_wait_time=10 #secs
cur_wait_time=0
while [ -z "$(ps | grep "[a]liyundrive-webdav")" ]
do
  sleep 1
  cur_wait_time=$(expr $t + 1)
  if [ $cur_wait_time -ge 10 ]; then
    logger -s -t "【 安装阿里云drive加载模块】" "退出, 阿里云drive服务没有运行，请重新安装运行！"
    exit 1
  fi
done
sleep 3
logger -s -t "【 安装阿里云drive加载模块】" "启动"
modprobe fuse 
mkdir /mnt/aliyun 2>/dev/null
umount -fl /mnt/aliyun 2>/dev/null 
killall "webdavfs"
echo 35 > /proc/sys/vm/pagecache_ratio # by default, it's 50% ratio with page cache, it's too big!
$tmp_dir/webdavfs -D -ousername=admin,password=admin,usepagecache,readbuff=1048576 http://0.0.0.0:8080 /mnt/aliyun
logger -s -t "【 安装阿里云drive加载模块】" "完成"
exit 0
