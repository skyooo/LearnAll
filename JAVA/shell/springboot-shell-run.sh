#!/bin/bash
#set -euxo pipefail
# 2. 请给本脚本设备可执行权限
# 3. 启动示例         start.sh "/home/work/side-middle-office/java/xx.jar" "test" "start" "/home/work/project/java/logs/sys-info.log" "Started Application in"
# 4. 重启示例         start.sh "/home/work/side-middle-office/java/xx.jar" "test" "restart" "/home/work/project/java/logs/sys-info.log" "Started Application in"
# 5. 停止示例         start.sh "xx" "stop"
# 6. 查看状态示例     start.sh "xx" "check"

echo "======== 1. jar run start  =========="
	
jarPath=$1


APP_NAME=$1
profiles=$2 # xx.jar
OPERATE=$3
SYSTEM=`uname`
RUNNING="false";

keywords=$5
logfile=$4
keywordRegular="[Started[:space:]\w*Application[:space:]in[:space:]][0-9\.\-]*seconds"
#keywords="Started Application in"
#logfile="/home/work/project/java/logs/sys-info.log"
if [ ! $keywords ]; then
  echo "判断启动成功日志判断关键字未传..则默认使用正则表达式"
else
  echo "判断启动成功日志判断关键字已传..不使用默认正则表达式.$keywords"
  keywordRegular=$5
fi
echo "启动jar服务...$APP_NAME | spring.profiles.active=$profiles | 操作类型=$3"


## 输出本命令的使用方法 并退出
usage() {
    echo "Usage: start.sh [app_name].jar test [start|stop|restart|check]"
    exit 1
}


## 判断是否输入了两个参数
if [ $# -lt 3 ]; then
    usage
fi


# 启动程序
function start() {
	filePah=${APP_NAME}
	# 处理相对路径
	if [ ${filePah:0:1} != "/" ]; then
		filePah="`pwd`/${filePah}"
	fi
	# 用文件名作为 APP_NAME
  JAR_DIRECTORY=${filePah%/*}
	JAR_NAME=${filePah##*/}
	APP_NAME=${JAR_NAME%%.*}

 echo "filePah=$filePah .. APP_NAME=$APP_NAME  | JAR_NAME=$JAR_NAME"
 # 切换目录
 cd $JAR_DIRECTORY
  
	# 检查是否已经存在
	check
	if [ ${RUNNING} == "true" ]; then
		echo "App already running!"
	else
		echo "start..."
		`nohup java -jar ${JAR_NAME} --name=${APP_NAME} --spring.profiles.active=${profiles} > /dev/null 2>&1 &`
        #sleep 20
	    # { sed /"$keywords"/q; exit 1; }< <(exec timeout 2m tail -Fn 0 $logfile)
		 { sed /"$keywordRegular"/q; kill $!; } < <(exec timeout 2m tail -Fn 0 $logfile)
        # { sed /[Started[:space:]\w*Application[:space:]in[:space:]][0-9\.\-]*seconds/q; kill $!; } < <(exec timeout 2m tail -Fn 0 $logfile)
		check
		echo "Start success!"
	fi
}

function check() {
	echo "check running status..."
	if [ "${SYSTEM}" == 'Linux' ]; then
		tpid=`ps -ef|grep -n " java.*--name=$APP_NAME"|grep -v grep|grep -v kill|awk '{print $2}'`
	else
		tpid=`ps -ef|grep -n " java.*--name=$APP_NAME"|grep -v grep|grep -v kill|awk '{print $3}'`
	fi
	if [ ${tpid} ]; then
    	echo 'App is running.'
    	RUNNING="true"
	else
	    echo 'App is NOT running.'
	    RUNNING="false"
	fi
}


# 停止程序
function stop() {
  
	if [ ${SYSTEM} == 'Linux' ]; then
		tpid=`ps -ef|grep -n " java.*--name=$APP_NAME"|grep -v grep|grep -v kill|awk '{print $2}'`
	else
		tpid=`ps -ef|grep -n " java.*--name=$APP_NAME"|grep -v grep|grep -v kill|awk '{print $3}'`
	fi
	if [ ${tpid} ]; then
	    echo 'Stop Process...'
	    kill -15 ${tpid}
	    # 检查程序是否停止成功
	    for ((i=0; i<10; ++i))  
		do  
			sleep 1
			if [ ${SYSTEM} == 'Linux' ]; then
				tpid=`ps -ef|grep -n " java.*--name=$APP_NAME"|grep -v grep|grep -v kill|awk '{print $2}'`
			else
				tpid=`ps -ef|grep -n " java.*--name=$APP_NAME$"|grep -v grep|grep -v kill|awk '{print $3}'`
			fi
			if [ ${tpid} ]; then
				echo -e ".\c"
			else
				echo 'Stop Success!'
				break;
			fi
		done
		# 强制杀死进程
		if [ ${SYSTEM} == 'Linux' ]; then
			tpid=`ps -ef|grep -n " java.*--name=$APP_NAME"|grep -v grep|grep -v kill|awk '{print $2}'`
		else
			tpid=`ps -ef|grep -n " java.*--name=$APP_NAME$"|grep -v grep|grep -v kill|awk '{print $3}'`
		fi
		if [ ${tpid} ]; then
		    echo 'Kill Process!'
		    kill -9 ${tpid}
		fi
	else
		echo 'App already stop!'
	fi
}

restart() {
  filePah=${APP_NAME}
	# 处理相对路径
	if [ ${filePah:0:1} != "/" ]; then
		filePah="`pwd`/${filePah}"
	fi
	# 用文件名作为 APP_NAME
  JAR_DIRECTORY=${filePah%/*}
	JAR_NAME=${filePah##*/}
	APP_NAME=${JAR_NAME%%.*}
  stop
  APP_NAME=${filePah}
  start
}

function list () {
	if [ ${APP_NAME} == "all" ]; then
		if [ ${SYSTEM} == 'Linux' ]; then
			ps -ef | grep -n "java.*--name="|grep -v grep|grep -v kill|awk '{printf $2"\t"$8"\t"} {split($11,b,"=");print b[2]}'
			res=`ps -ef | grep -n "java.*--name="|grep -v grep|grep -v kill|awk '{printf $2"\t"$8"\t"} {split($11,b,"=");print b[2]}' `
		else
			ps -ef | grep -n "java.*--name="|grep -v grep|grep -v kill|awk '{printf $3"\t"$9"\t"} {split($12,b,"=");print b[2]}'
			res=`ps -ef | grep -n "java.*--name="|grep -v grep|grep -v kill|awk '{printf $3"\t"$9"\t"} {split($12,b,"=");print b[2]}' `
		fi
	else
		if [ ${SYSTEM} == 'Linux' ]; then
			ps -ef | grep -n "java.*--name=${APP_NAME}$"|grep -v grep|grep -v kill|awk '{printf $2"\t"$8"\t"} {split($11,b,"=");print b[2]}'
			res=`ps -ef | grep -n "java.*--name=${APP_NAME}$"|grep -v grep|grep -v kill|awk '{printf $2"\t"$8"\t"} {split($11,b,"=");print b[2]}' `
		else
			ps -ef | grep -n "java.*--name=${APP_NAME}$"|grep -v grep|grep -v kill|awk '{printf $3"\t"$9"\t"} {split($12,b,"=");print b[2]}'
			res=`ps -ef | grep -n "java.*--name=${APP_NAME}$"|grep -v grep|grep -v kill|awk '{printf $3"\t"$9"\t"} {split($12,b,"=");print b[2]}' `
		fi
	fi
	if [ -z "$res" ]; then
		echo "None app running!"
	fi
}


# 参数检查
if [ -z ${OPERATE} ] || [ -z ${APP_NAME} ];then
	if [ -z ${OPERATE} ];
		then
			echo "OPERATE can not be null."
		else
			echo "APP_NAME can not be null."
	fi
else
	# 启动程序
	if [ ${OPERATE} == "start" ]; then
		start
	# 停止程序
	elif [ ${OPERATE} == "stop" ]; then
		stop
	# 检查查询运行状态
	elif [ ${OPERATE} == "check" ]; then
		check
	# 查询所有项目
	elif [ ${OPERATE} == "list" ]; then
		list
  elif [ ${OPERATE} == "restart" ]; then
		restart  
	else
		echo "Not supported the OPERATE."
	fi
fi



