# aliyundrive-webdav-router-install  一键自动安装脚本
One-click setup Aliyun-drive webdav service on your wireless router that have installed Padavan or other firmware based on linux kernel.

Optional setup: Mount webdav as filesytem and sharing with SAMBA (linux kernel module `fuse` is required and setup [fusermount](https://github.com/simonchen/libfuse), [webdavfs - recommended](https://github.com/simonchen/webdavfs) or [davfs2](https://github.com/simonchen/davfs2)

在路由器上一键安装阿里云盘webdav服务（路由器需要刷Padavan或OpenWRT等基于linux内核的固件）

可选安装：阿里云盘挂载和SAMBA共享 (需要linux内核集成`fuse`，并安装[fusermount](https://github.com/simonchen/libfuse), [webdavfs - 推荐](https://github.com/simonchen/webdavfs) 或 [davfs2](https://github.com/simonchen/davfs2)

![Aliyun drive](webdav.png)

## 快速安装阿里云WebDav服务 / fuse mount (可选，加载WebDav服务作为本地磁盘)

以Padavan固件路由器安装为例：下载aliyundrive_install.sh 到路径/etc/storage/

执行命令：
```
cd /etc/storage && chmod +x aliyundrive_install.sh && ./aliyundrive_install.sh [refresh token]
```

替换参数[refresh token]：[点我获取refresh token](https://github.com/messense/aliyundrive-webdav#%E8%8E%B7%E5%8F%96-refresh_token)

**上面命令可以不指定[refresh_token]，但必须在ssh终端控制台运行命令，安装过程中将会看到【 扫描二维码登录获取refresh_token 】: 打开手机阿里云APP扫描 , 请按提示完成后续操作即可。**

### 可选插件安装 - webdavfs / fusermount
支持fuse mount插件，
需要下载mount_aliyun.sh放到与主安装程序aliyundrive_install.sh同一目录下，执行相同的快速安装命令(见上面)
加载后的阿里云盘作为文件系统，默认路径/mnt/aliyun

<hr />

## Quick setup webdav serivce & fuse mount (optional)

Please copy `./aliyundrive_install.sh` to `/etc/storage/` or anywhere you like
then copy / run the following command as follows to finish the installation.
```
chmod +x /etc/storage/aliyundrive_install.sh &&
/etc/storage/aliyundrive_install.sh [refresh_token] [platform]
```
[refresh_token] is required that you extracted from web browser on aliyundrive.com

[Click me to get refresh token](https://github.com/messense/aliyundrive-webdav#%E8%8E%B7%E5%8F%96-refresh_token)

**If you don't give [refresh_token], then you'll have to run the command in terminal console, then you will see the following instruction:【 扫描二维码登录获取refresh_token 】: 打开手机阿里云APP扫描 , Please launch AliYun app on your phone, then scanning the QR code for login to finish the setup.**

[platform] is optional by default is mipsel (联发科soc), the valid platform can be in [aarch64, arm, arm5te, armv7, mips, mipsel, x86_64]
如果你的路由器是 Intel soc, 选x86_64; 如果你的路由器是 ARM soc, 选arm | arm5te | armv7

Now, the main script **aliyundrive_install.sh** will launch **aliyundrive-webdav** with specific parameters,
the webdav service works on **http://admin:admin@0.0.0.0:8080**

For Padavan, you would like to run the following extra command to permanently save the script, 
you will be able to rerun the script once you encounter any throuble~
```
/sbin/mtd_storage.sh save
```

## How to fetch refresh token
[点我查看获取refresh token](https://github.com/messense/aliyundrive-webdav#%E8%8E%B7%E5%8F%96-refresh_token)

## Optional setup (only support MIPS little endian arch.)
Please copy `./mount_aliyun.sh' to the same directory with `./aliyundrive_install.sh`
When running the following command, it will auto-install and mount the webdav service **http://admin:admin@0.0.0.0:8080** into local directory **/mnt/aliyun**
```
/etc/storage/aliyundrive_install.sh [refresh_token] [platform]
```
Now, you can access AliCloud storage more easily at local disk.
Furthermore, you can share the directory **/mnt/aliyun** with other network devices in same sub-network,
this can be finished by SAMBA , you simply copy `smb.conf` `start_samba.sh` to somewhere,
then change `start_samba.conf` with executable permission and execute it to setup SAMBA share service.
```
chmod +x ./start_samba.sh && ./start_samba.sh
```

## Uninstall [卸载]
```
/etc/storage/aliyundrive_install.sh uninstall
```

## Performance [性能]
There are two special parameters that you would like to tweak in the script, please find the codes as follows:
```
--read-buffer-size 1048576 --upload-buffer-size 1048576
```
if your router owns plenty of memory more than 256MB , you should remove the two parameters or increase the buffer size in bytes.
otherwise, please keep it at the fixed buffer size at 1MB, this will avoid crashing with error **memory allocation failed**.

## Development story
k2p is a router branding by phicomm (this company has bankrapted for years for some reasons ), 
the router is able to flash custom firmware that will increases a great performance on wireless connection.
I was going to deploy the AliyunDrive on it using 'WebDav' protocol , but the router has lower memory at 128M RAM, and 16M flash memory only!
due to the low flash memory, I couldn't put the binary in the flash memory then launch it, **But it's able to run the binary from the 128M RAM**!!
Finally, I've created the main script **aliyundrive_install.sh** that successfully setup / run **aliyundrive-webdav** from RAM .

## Reference
**aliyundrive-webdav**
https://github.com/messense/aliyundrive-webdav

**webdavfs**
https://github.com/simonchen/webdavfs

**libfuse**
https://github.com/simonchen/libfuse

**davfs2**
https://github.com/simonchen/davfs2
