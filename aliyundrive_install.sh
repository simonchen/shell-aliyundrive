#!/bin/sh
# one-click setup Aliyun Drive on your router that have installed Padavan or other firmware based on linux.
# usage: ./aliyundrive_install.sh [refresh_token] [platform]
#        [platform] is optional by default is mipsel, the valid platform can be in [aarch64, arm, arm5te, armv7, mips, mipsel, x86_64]

basedir=$(cd $(dirname $0) && pwd)
basename=$(basename $0)

git_root=messense/aliyundrive-webdav
get_latest_release() {
  output=$(curl --silent "https://api.github.com/repos/$git_root/releases/latest" | # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/')                                    # Pluck JSON value
  
  echo $output
}

refresh_token=$1
if [ -z "$refresh_token" ]; then
	logger -s -t "【ERROR】" "缺少refresh_token"
	exit 0
fi
logger -s -t "refresh_token" "$refresh_token"


platform=mipsel
arch_float_mode=musl
if [ ! -z "$2" ]; then
	platform=$2
	for p in arm arm5te armv7; do
		if [ $platform == $p ]; then
			arch_float_mode=musleabi # if you make sure that your platform uses hard-float mode, just change it to musleabihf
		fi
	done
fi
latest_ver=$(get_latest_release)
if [ -z "$latest_ver" ]; then
	logger -s -t "�【ERROR�" "Could not found latest version from $git_roo, exit!"
	exit 0
else
	logger -s -t "Found latest version" "$latest_ver"
fi

download_url=https://github.com/messense/aliyundrive-webdav/releases/download/$latest_ver/aliyundrive-webdav-$latest_ver.$platform-unknown-linux-$arch_float_mode.tar.gz

tmp_dir=/tmp/etc_storage_apps

logger -s -t "【 创建临时目录 】:" ""$tmp_dir""
mkdir "$tmp_dir"

logger -s -t "【 下 载 】" "$download_url"
path=$tmp_dir/aliyundrive-webdav.tar.gz
wget "$download_url" -O "$path"
if [ "$?" != "0" ]; then
	logger -s -t "【下载失败】" "1分钟后自动重试"
fi
tar -xzf "$path" -C "$tmp_dir"
rm "$path"

watch_script=aliyundrive_watch.sh
cat >$tmp_dir/$watch_script <<'EOF'
#!/bin/sh
# detecting if aliyun drive service is down

LOGTIME=$(date "+%Y-%m-%d %H:%M:%S")
wget --spider --quiet http://admin:admin@0.0.0.0:8080
if [ "$?" == "0" ]; then
        logger -s -t "【 监控aliyundrive 】" "['$LOGTIME'] No Problem."
        exit 0
else
        logger -s -t "【 阿里云盘异常, 重启 】" "aliyundrive-webdav."
EOF
cat <<EOF >> $tmp_dir/$watch_script
	killall "aliyundrive-webdav"
	$basedir/$basename "$refresh_token"
fi 
EOF

chmod 777 $tmp_dir/*

logger -s -t "【 启动aliyundrive 】" "start"
killall "aliyundrive-webdav"
$tmp_dir/aliyundrive-webdav --host 0.0.0.0 -I --no-trash --no-redirect --no-self-upgrade -p 8080 -r $refresh_token -U admin -W admin > /dev/null &

logger -s -t "【 监控aliyundrive 】" "start"
line="*/1 * * * * $tmp_dir/$watch_script"
if crontab -l | grep "$watch_script"; then
	logger -s -t "Replace Cronjob: " "$watch_script" 
	(crontab -l | grep -v "$watch_script"; echo "$line" ) | crontab -
else
	logger -s -t "Running Cronjob: " "$watch_script"
	(crontab -l; echo "$line" ) | crontab -
fi

