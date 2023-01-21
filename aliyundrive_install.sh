#!/bin/sh
# copyright by simonchen
# one-click setup Aliyun Drive on your router that have installed Padavan or other firmware based on linux.
# usage: ./aliyundrive_install.sh [refresh_token] [platform]
#        [platform] is optional by default is mipsel, the valid platform can be in [aarch64, arm, arm5te, armv7, mips, mipsel, x86_64]

basedir=$(cd $(dirname $0) && pwd)
basename=$(basename $0)

git_root=messense/aliyundrive-webdav
tmp_dir=/tmp/etc_storage_apps
watch_script=aliyundrive_watch.sh

proc_name=${basename:0:15}
proc_num=`pgrep -x $basename | grep -v $$ | wc -l`
if [ "$(expr $proc_num \> 1)" == "1"  ]; then
        logger -s -t "【安装阿里云drive】" "正在运行"
        exit 1
fi

get_latest_release() {
  output=$(curl --silent "https://api.github.com/repos/$git_root/releases/latest" | # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/')                                    # Pluck JSON value
  
  echo $output
}

setup_iptables_http_alt() {
is_remove=$1
logger -s -t "【失效本地webdav服务】" "port:8080"
while ip_rule_num=$(iptables -L INPUT --line-numbers | grep -E -i -w 'tcp dpt:http-alt' | cut -d" " -f1)
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
if [ "$is_remove" == "1" ]; then
  return
fi
logger -s -t "【允许本地webdav服务】" "port:8080"
iptables -I INPUT -p tcp --dport 8080 -j ACCEPT
}

padavan_setup() {
  is_remove=$1
  setup_iptables_http_alt "$is_remove"
  ### for Padavan router only ###
  padavan_post_script="/etc/storage/script0_script.sh"
  if [ -f "$padavan_post_script" ]; then
        logger -s -t "【 移除阿里云drive自定义脚本】" "自定义脚本0"
	sed -i "/#阿里云drive/d" $padavan_post_script
        sed -i "/$basename/d" $padavan_post_script
        if [ "$is_remove" == "0" ]; then
                logger -s -t "【 添加阿里云drive自定义脚本】" "自定义脚本0"
		echo "#阿里云drive" >> $padavan_post_script
                echo "$basedir/$basename $refresh_token $platform crontab &" >> $padavan_post_script
		
		
        fi
  fi

  padavan_mtd_script="/sbin/mtd_storage.sh"
  if [ -f "$padavan_mtd_script" ]; then
        logger -s -t "【 保存阿里云drive配置】" ""
        $padavan_mtd_script save
  fi
}

download_file() {
  url=$1
  path=$2
  success=0
  secs=15
  while true
  do
    wget "$url" -O "$path"
    if [ "$?" != "0" ]; then
      secs=$(expr $secs \* 2)
      if [ "$secs" -ge "1000" ]; then
        break
      fi
      logger -s -t "【下载失败】" "$secs秒后重试：$url"
      sleep $secs
    else
      success=1
      break
    fi
  done
  echo $success
}


uninstall() {
  killall "webdavfs" 2>/dev/null
  killall "aliyundrive-webdav" 2>/dev/null
  if [ -d "$tmp_dir" ]; then
    rm -rf $tmp_dir
    logger -s -t "$tmp_dir is removed" "done"
  fi
  if [ ! -z "$(crontab -l | grep "$watch_script")" ]; then
    (crontab -l | grep -v "$watch_script"; echo "" ) | crontab -
    logger -s -t "aliyun watch is removed" "done"
  fi
  padavan_setup 1
  
  logger -s -t "aliyundrive is removed" "done"
}
if [ "$1" == "uninstall" ]; then
    uninstall
    exit 0
fi

# environment detection
LEAST_FREE_MEMORY_KB=51200 #50MB
LEAST_FREE_MEMORY_MB=$(expr $LEAST_FREE_MEMORY_KB \/ 1024)
cur_free_kb=$(cat /proc/meminfo | grep 'MemFree:' | sed -E 's/MemFree\:[^0-9]+(.+) kb/\1/i')
if [ $cur_free_kb -lt $LEAST_FREE_MEMORY_KB ]; then
  logger -s -t "【 安装aliyundrive 】" "可用内存低于$LEAST_FREE_MEMORY_MB MB, 无法安装!"
  exit 1
fi 

refresh_token=$1
crontab_flag=$3
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

if [ ! -f "$tmp_dir/aliyundrive-webdav" ]; then
  latest_ver=$(get_latest_release)
  if [ -z "$latest_ver" ]; then
        logger -s -t "【 ERROR 】" "Could not found latest version from $git_root, exit!"
        exit 0
  else
        logger -s -t "Found latest version" "$latest_ver"
  fi

  download_url=https://github.com/$git_root/releases/download/$latest_ver/aliyundrive-webdav-$latest_ver.$platform-unknown-linux-$arch_float_mode.tar.gz

  logger -s -t "【 创建临时目录 】:" ""$tmp_dir""
  mkdir "$tmp_dir" 2>/dev/null

  logger -s -t "【 下 载 】" "$download_url"
  path=$tmp_dir/aliyundrive-webdav.tar.gz
  success=$(download_file "$download_url" "$path")
  if [ "$success" != "1" ]; then
	logger -s -t "【下载失败】" "退出"
	exit 1
  fi
  tar -xzf "$path" -C "$tmp_dir" && rm "$path"
fi

if [ -z "$refresh_token" ]; then
        #refresh_token=$(get_refresh_token_from_login "$tmp_dir/aliyundrive-webdav")
	logger -s -t "【 扫描二维码登录获取refresh_token 】" "打开手机阿里云APP扫描"
	bin_path=$tmp_dir/aliyundrive-webdav
	tmp_token_file=$tmp_dir/aliyun_token.txt
	exec $bin_path qr login | tee $tmp_token_file
	refresh_token=$(cat $tmp_dir/aliyun_token.txt | grep refresh_token | sed -E 's/refresh_token: ([^\s]+)/\1/gi')
	echo "refresh_token="$refresh_token
	rm -f $tmp_token_file

        if [ -z "$refresh_token" ]; then
                logger -s -t "【ERROR】" "缺少refresh_token"
                exit 1
        fi
fi
logger -s -t "refresh_token" "$refresh_token"

cat >$tmp_dir/$watch_script <<'EOF'
#!/bin/sh
# detecting if aliyun drive service is down

LOGTIME=$(date "+%Y-%m-%d %H:%M:%S")
wget --spider --quiet http://admin:admin@0.0.0.0:8080
if [ "$?" == "0" ]; then
        #logger -s -t "【 监控aliyundrive 】" "['$LOGTIME'] No Problem."
        exit 0
else
        logger -s -t "【 阿里云盘异常, 重启 】" "aliyundrive-webdav."
EOF
cat <<EOF >> $tmp_dir/$watch_script
	killall "aliyundrive-webdav"
	$basedir/$basename "$refresh_token" "$platform" "crontab" &
fi 
EOF

chmod 777 $tmp_dir/*

logger -s -t "【 启动aliyundrive 】" "start"
killall "aliyundrive-webdav"
$tmp_dir/aliyundrive-webdav --host 0.0.0.0 -I --no-trash --no-redirect --no-self-upgrade --read-buffer-size 1048576 --upload-buffer-size 1048576 -p 8080 -r $refresh_token -U admin -W admin > /dev/null &
max_wait_time=10 #secs
cur_wait_time=0
while [ -z "$(ps | grep "[a]liyundrive-webdav")" ]
do
  sleep 1
  cur_wait_time=$(expr $t + 1)
  if [ $cur_wait_time -ge 10 ]; then
    logger -s -t "【 启动aliyundrive 】" "启动失败! 可用内存可能不够，或者本机8080端口被其它APP占用!"
    exit 1
  fi
done

if [ -f $basedir/mount_aliyun.sh ]; then
	logger -s -t "【 安装阿里云drive加载模块】" "webdavfs / fusermount"
	chmod +x $basedir/mount_aliyun.sh
	$basedir/mount_aliyun.sh
	if [ "$?" == "0" ]; then
		logger -s -t "【 安装阿里云drive加载模块】" "成功"
	else
		logger -s -t "【 安装阿里云drive加载模块】" "失败"
	fi 
fi

logger -s -t "【 监控aliyundrive 】" "start"
line="*/1 * * * * $tmp_dir/$watch_script"
if crontab -l | grep "$watch_script"; then
	logger -s -t "Replace Cronjob: " "$watch_script" 
	(crontab -l | grep -v "$watch_script"; echo "$line" ) | crontab -
else
	logger -s -t "Running Cronjob: " "$watch_script"
	(crontab -l; echo "$line" ) | crontab -
fi
killall crond && crond -l 15 &2>1 &

logger -s -t "【 阿里云drive】" "安装成功!"

if [ "$crontab_flag" == "crontab" ]; then
  exit 0
fi

padavan_setup 0
