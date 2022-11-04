# aliyundrive-webdav-router-install  一键自动安装脚本
one-click setup Aliyun Drive on your wireless router that have installed Padavan or other firmware based on linux.

# Development story
k2p is a router branding by phicomm (this company has bankrapted for years for some reasons ), 
the router is able to flash custom firmware that will increases a great performance on wireless connection.
I was going to deploy the AliyunDrive on it using 'WebDav' protocol , but the router has lower memory at 128M RAM, and 16M flash memory only!
due to the low flash memory, I couldn't put the binary in the flash memory then launch it, **But it's able to run the binary from the 128M RAM**!!
Finally, I've created the main script **aliyundrive_install.sh** that successfully setup / run **aliyundrive-webdav** from RAM .

# Quick start
Please copy ./aliyundrive_install.sh to /etc/storage/ 
then running command as follows to finish the installation.
```
chmod 777 /etc/storage/aliyundrive_install.sh
/etc/storage/aliyundrive_install.sh [refresh_token] [platform]
```
[refresh_token] is required that you extracted from web browser on aliyundrive.com
[platform] is optional by default is mipsel (联发科soc), the valid platform can be in [aarch64, arm, arm5te, armv7, mips, mipsel, x86_64]
如果你的路由器是 Intel soc, 选x86_64; 如果你的路由器是 ARM soc, 选arm | arm5te | armv7

For Padavan, you would like to run the following extra command to permanently save the script, 
you will be able to rerun the script once you encounter any throuble~
```
/sbin/mtd_storage.sh save
```

# Performance
By default, the main script **aliyundrive_install.sh** will launch **aliyundrive-webdav** with specific parameters,
the webdav service works on http://admin:admin@0.0.0.0:8080
There are two special parameters that you would like to tweak in the script, please find the codes as follows:
```
--read-buffer-size 1048576 --upload-buffer-size 1048576
```
if your router owns plenty of memory more than 256MB , you should remove the two parameters or increase the buffer size in bytes.
otherwise, please keep it at the fixed buffer size at 1MB, this will avoid crashing with error **memory allocation failed**.

# Reference - aliyundrive-webdav
https://github.com/messense/aliyundrive-webdav
