自动安装脚本
#!/bin/bash
#date:2017-05-25
#version:0.0.1
#开始安装vsftpd
echo ">>> 1. Start install Vsftpd ......"
yum -y install pam pam-devel db4 de4-devel db4-tcl vsftpd
mkdir /var/ftp/virtual
useradd vsftpd -M -s /sbin/nologin
useradd ftpvload -d /var/ftp/virtual/ -s /sbin/nologin
sleep 3
#开始配置vsftpd
echo ">>> 2. Start config Vsftpd ......"
cp /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf.back
sed -i '/^[^#]/s/^/#/g' vsftpd.conf
echo "
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
anon_upload_enable=NO
anon_mkdir_write_enable=NO
dirmessage_enable=YES
xferlog_enable=YES
connect_from_port_20=YES
chown_uploads=NO
xferlog_file=/var/log/vsftpd.log
xferlog_std_format=YES
async_abor_enable=YES
ascii_upload_enable=YES
ascii_download_enable=YES
ftpd_banner=Welcome to FTP Server
#chroot_local_user=YES
ls_recurse_enable=NO
listen=YES
hide_ids=YES
pam_service_name=vsftpd
userlist_enable=YES
tcp_wrappers=YES
guest_enable=YES
guest_username=ftpvload
virtual_use_local_privs=YES
user_config_dir=/etc/vsftpd/vconf
" >> /etc/vsftpd/vsftpd.conf
cp /etc/pam.d/vsftpd /etc/pam.d/vsftpd.backup
sed -i s/^/#/g /etc/pam.d/vsftpd
echo "auth sufficient /lib64/security/pam_userdb.so db=/etc/vsftpd/virtusers
account sufficient /lib64/security/pam_userdb.so db=/etc/vsftpd/virtusers
" >> /etc/pam.d/vsftpd
sleep 3
#开始配置其它
echo ">>> 3. Start config other ......"
touch /var/log/vsftpd.log
chown vsftpd.vsftpd /var/log/vsftpd.log
mkdir /etc/vsftpd/vconf/ -pv
sleep 3
#配置虚拟用户
echo ">>> 4. Start config vitual user"
echo -e "test\ntest1234" >> /etc/vsftpd/virtusers
db_load -T -t hash -f /etc/vsftpd/virtusers /etc/vsftpd/virtusers.db
mkdir /var/ftp/virtual/test
echo "local_root=/var/ftp/virtual/username
#指定虚拟用户的具体主路径
anonymous_enable=NO
#设定不允许匿名用户访问
write_enable=YES
#设定允许写操作
local_umask=022
#设定上传文件权限掩码
anon_upload_enable=NO
#设定不允许匿名用户上传
anon_mkdir_write_enable=NO
#设定不允许匿名用户建立目录
idle_session_timeout=600
#设定空闲连接超时时间
data_connection_timeout=120
#设定单次连续传输最大时间
max_clients=10
#设定并发客户端访问个数
max_per_ip=5
#设定单个客户端的最大线程数，这个配置主要来照顾Flashget、迅雷等多线程下载软件
local_max_rate=50000
#设定该用户的最大传输速率，单位b/s
" >> /etc/vsftpd/vconf/vconf.tmp
cp /etc/vsftpd/vconf/vconf.tmp /etc/vsftpd/vconf/test
sed -i s/username/test/g /etc/vsftpd/vconf/test
echo "Alll OVER! "

新增用户

#!/bin/bash
#date:2017-05-25
if read -t 5 -p "Please enter you name: " username
then
if [ -f /etc/vsftpd/vconf/$username ] #判断用户是否存在
then
echo "The $username is exists, please input another name."
else
read -s -p "Please enter your password: " passwd
echo -e "$username\n$passwd" >> /etc/vsftpd/virtusers
rm -rf /etc/vsftpd/virtusers.db
db_load -T -t hash -f /etc/vsftpd/virtusers /etc/vsftpd/virtusers.db
mkdir -pv /var/ftp/virtual/$username
cp /etc/vsftpd/vconf/vconf.tmp /etc/vsftpd/vconf/$username
sed -i s/username/$username/g /etc/vsftpd/vconf/$username
echo "The config is over."
fi
else
echo -e "\nThe 5s has passed, you are to slow! "
fi
