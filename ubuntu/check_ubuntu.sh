#!/bin/bash
##Filename:     check_ubuntu.sh
##Date:         2023-08-27
##Description:  Security detection script

echo "##########################################################################"
echo "#                                                                        #"
echo "#                        Epoint health check script                      #"
echo "#                                                                        #"
echo "#警告:本脚本只是一个检查的操作,未对服务器做任何修改,管理员可以根据此报告 #"
echo "#进行相应的安全整改                                                      #"
echo "##########################################################################"
echo " "
#read -p "=====================Are You Ready,Please press enter=================="
echo " "
echo "##########################################################################"
echo "#                                                                        #"
echo "#                               主机安全检测                             #"
echo "#                                                                        #"
echo "##########################################################################"
echo " "
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>系统基本信息<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
hostname=$(uname -n)
system=$(cat /etc/os-release | grep "^NAME" | awk -F\" '{print $2}')
version=$(lsb_release -cs)
kernel=$(uname -r)
platform=$(uname -p)
address=$(ip addr | grep inet | grep -v "inet6" | grep -v "127.0.0.1" | awk '{ print $2; }' | tr '\n' '\t' )
cpumodel=$(cat /proc/cpuinfo | grep name | cut -f2 -d: | uniq)
cpu=$(cat /proc/cpuinfo | grep 'processor' | sort | uniq | wc -l)
machinemodel=$(dmidecode | grep "Product Name" | sed 's/^[ \t]*//g' | tr '\n' '\t' )
date=$(date)

echo "主机名:           $hostname"
echo "系统名称:         $system"
echo "系统版本:         $version"
echo "内核版本:         $kernel"
echo "系统类型:         $platform"
echo "本机IP地址:       $address"
echo "CPU型号:          $cpumodel"
echo "CPU核数:          $cpu"
echo "机器型号:         $machinemodel"
echo "系统时间:         $date"
echo " "
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>资源使用情况<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
summemory=$(free -h |grep "Mem:" | awk '{print $2}')
freememory=$(free -h |grep "Mem:" | awk '{print $4}')
usagememory=$(free -h |grep "Mem:" | awk '{print $3}')
uptime=$(uptime | awk '{print $2" "$3" "$4" "$5}' | sed 's/,$//g')
loadavg=$(uptime | awk '{print $9" "$10" "$11" "$12" "$13}')

echo "总内存大小:           $summemory"
echo "已使用内存大小:       $usagememory"
echo "可使用内存大小:       $freememory"
echo "系统运行时间:         $uptime"
echo "系统负载:             $loadavg"
echo "=============================dividing line================================"
echo "内存状态:"
vmstat 2 5
echo "=============================dividing line================================"
echo "僵尸进程:"
ps -ef | grep zombie | grep -v grep
if [ $? == 1 ];then
    echo ">>>无僵尸进程"
else
    echo ">>>有僵尸进程------[需调整]"
fi
echo "=============================dividing line================================"
echo "耗CPU最多的进程:"
ps auxf |sort -nr -k 3 |head -5
echo "=============================dividing line================================"
echo "耗内存最多的进程:"
ps auxf |sort -nr -k 4 |head -5
echo "=============================dividing line================================"
echo  "环境变量:"
env
echo "=============================dividing line================================"
echo  "路由表:"
route -n
echo "=============================dividing line================================"
echo  "监听端口:"
netstat -tunlp
echo "=============================dividing line================================"
echo  "当前建立的连接:"
netstat -n | awk '/^tcp/ {++S[$NF]} END {for(a in S) print a, S[a]}'
echo "=============================dividing line================================"
echo "开机启动的服务:"
systemctl list-unit-files | grep enabled
echo " "
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>系统用户情况<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
echo  "活动用户:"
w | tail -n +2
echo "=============================dividing line================================"
echo  "系统所有用户:"
cut -d: -f1,2,3,4 /etc/passwd
echo "=============================dividing line================================"
echo  "系统所有组:"
cut -d: -f1,2,3 /etc/group
echo "=============================dividing line================================"
echo  "当前用户的计划任务:"
crontab -l
echo " "
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>身份鉴别安全<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
grep -i "^password.*requisite.*pam_cracklib.so" /etc/pam.d/system-auth  > /dev/null
if [ $? == 0 ];then
    echo ">>>密码复杂度:已设置"
else
    grep -i "pam_pwquality\.so" /etc/pam.d/system-auth > /dev/null
    if [ $? == 0 ];then
	echo ">>>密码复杂度:已设置"
    else
	echo ">>>密码复杂度:未设置,请加固密码--------[需调整]"
    fi
fi