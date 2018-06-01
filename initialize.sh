#!/bin/bash

#检测是否为root用户
if [ $UID -ne 0 ];then
        echo "Must be root can do this."
        exit 9
fi

#检测网络
echo "检测网络中......"
/bin/ping www.baidu.com -c 2 &>/dev/null
if [ $? -ne 0 ];then
        echo "现在网络无法通信，准备设置网络"
        read -p 'pls enter your ip: ' IP
        read -p 'pls enter your gateway: ' GW 
        read -p 'pls enter your netmask: ' NM 
        read -p 'pls enter your netcard: ' NC
        echo "IPADDR=$IP" >> /etc/sysconfig/network-scripts/ifcfg-$NC
        echo "NETMASK=$NM" >> /etc/sysconfig/network-scripts/ifcfg-$NC
        echo "GATEWAY=$GW" >> /etc/sysconfig/network-scripts/ifcfg-$NC
        echo "DNS1=114.114.114.114" >> /etc/sysconfig/network-scripts/ifcfg-$NC
        echo "DNS2=8.8.8.8" >> /etc/sysconfig/network-scripts/ifcfg-$NC
        sed -i 's/dhcp/static/g' /etc/sysconfig/network-scripts/ifcfg-$NC
        sed -i 's/ONBOOT=no/ONBOOT=yes/g' /etc/sysconfig/network-scripts/ifcfg-$NC
        /etc/init.d/network restart
        echo -e "\033[031m network is configure ok.\033[0m"
else
        echo -e "\033[031m network is ok.\033[0m"
fi

#关闭 ctrl + alt + del
echo "关闭 ctrl + alt + del ......."
sed -i "s/ca::ctrlaltdel:\/sbin\/shutdown -t3 -r now/#ca::ctrlaltdel:\/sbin\/shutdown -t3 -r now/" /etc/inittab
sed -i 's/^id:5:initdefault:/id:3:initdefault:/' /etc/inittab

#关闭ipv6
echo "关闭IPv6....."
echo "alias net-pf-10 off" >> /etc/modprobe.conf
echo "alias ipv6 off" >> /etc/modprobe.conf
/sbin/chkconfig --level 35 ip6tables off
echo -e "\033[031m ipv6 is disabled.\033[0m"

#关闭selinux
echo "关闭SElinux......"
sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config
echo -e "\033[31m selinux is disabled,if you need,you must reboot.\033[0m"

#更新yum源
echo "备份yum源......"
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
sys_ver=`cat /etc/redhat-release |awk '{print $3}' | awk -F '.' '{print $1}'`
if [ $sys_ver -eq 6 ];then
        wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo
        yum clean all
        yum makecache
elif [ $sys_ver -eq 7 ];then
        wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo 
        yum clean all
        yum makecache
elif [ $sys_ver -eq 5 ];then
        wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-5.repo
        yum clean all
        yum makecache
fi

#安装基础库
echo "安装基础环境和库......"
yum -y install gcc gcc-c++ autoconf libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel libxml2 libxml2-devel zlib zlib-devel glibc glibc-devel glib2 glib2-devel bzip2 bzip2-devel ncurses ncurses-devel curl curl-devel e2fsprogs e2fsprogs-devel krb5-devel libidn libidn-devel openssl openssl-devel nss_ldap openldap openldap-devel  openldap-clients openldap-servers libxslt-devel libevent-devel ntp  libtool-ltdl bison libtool vim-enhanced

#设置时钟同步
echo "设置时钟同步......"
echo "*/5 * * * * root /usr/sbin/ntpdate time7.aliyun.com &>/dev/null" >> /etc/crontab

#修改Bash提示符字符串
echo "改Bash提示符字符串......"
echo 'PS1="\[\e[37;40m\][\[\e[32;40m\]\u\[\e[37;40m\]@\h \[\e[36;40m\]\w\[\e[0m\]]\\$ "' >> ~/.bashrc
source .bashrc

#修改文件打开数
echo "修改文件打开数......"
cat >> /etc/security/limits.conf <<EOF
* soft nproc 65535
* hard nproc 65535
* soft nofile 65535
* hard nofile 65535
EOF
echo "ulimit -SH 65535" >> /etc/rc.local

#优化内核参数
echo "优化内核参数....."
sed -i 's/net.ipv4.tcp_syncookies.*$/net.ipv4.tcp_syncookies = 1/g' /etc/sysctl.conf
cat >> /etc/sysctl.conf << ENDF
net.ipv4.tcp_max_syn_backlog = 65536
net.core.netdev_max_backlog =  32768
net.core.somaxconn = 32768
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_tw_recycle = 1
#net.ipv4.tcp_tw_len = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.ip_local_port_range = 1024  65535
ENDF
sysctl -p

#优化ssh参数
echo "优化ssh....."
sed -i '/^#UseDNS/s/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config
#sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords no/g' /etc/ssh/sshd_config
/etc/init.d/sshd restart
