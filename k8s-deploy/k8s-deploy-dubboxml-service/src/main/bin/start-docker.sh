#!/bin/bash

cd `dirname $0`
BIN_DIR=`pwd`
cd ..
# 获取当前目录
DEPLOY_DIR=`pwd`
# 定义配置文件目录
CONF_DIR=${DEPLOY_DIR}/conf
# 获取dubbo.properties配置文件里面的服务名称
SERVER_NAME=`sed '/dubbo.application.name/!d;s/.*=//' conf/dubbo.properties | tr -d '\r'`
# 获取dubbo.properties配置文件里面的服务端口
SERVER_PORT=`sed '/dubbo.protocol.port/!d;s/.*=//' conf/dubbo.properties | tr -d '\r'`
# 判断服务名称是否为空
if [ -z "${SERVER_NAME}" ]; then
    echo "ERROR: can not found 'dubbo.application.name' config in 'dubbo.properties' !"
	exit 1
fi
# 判断服务进程是否存在
PIDS=`ps  --no-heading -C java -f --width 1000 | grep "${CONF_DIR}" |awk '{print $2}'`
if [ -n "${PIDS}" ]; then
    echo "ERROR: The ${SERVER_NAME} already started!"
    echo "PID: ${PIDS}"
    exit 1
fi
# 判断服务端口是否被占用
if [ -n "${SERVER_PORT}" ]; then
	SERVER_PORT_COUNT=`netstat -ntl | grep ${SERVER_PORT} | wc -l`
	if [ ${SERVER_PORT_COUNT} -gt 0 ]; then
		echo "ERROR: The ${SERVER_NAME} port ${SERVER_PORT} already used!"
		exit 1
	fi
fi
# 配置日志目录
LOGS_DIR=""
if [ -n "${LOGS_FILE}" ]; then
	LOGS_DIR=`dirname ${LOGS_FILE}`
else
	LOGS_DIR=${DEPLOY_DIR}/logs
fi
if [ ! -d ${LOGS_DIR} ]; then
	mkdir ${LOGS_DIR}
fi
STDOUT_FILE=${LOGS_DIR}/stdout.log
# 指定服务依赖目录
LIB_DIR=${DEPLOY_DIR}/lib
LIB_JARS=`ls ${LIB_DIR} | grep .jar | awk '{print "'${LIB_DIR}'/"$0}'|tr "\n" ":"`

JAVA_OPTS=" -Djava.awt.headless=true -Djava.net.preferIPv4Stack=true "
JAVA_DEBUG_OPTS=""
if [ "$1" = "debug" ]; then
    JAVA_DEBUG_OPTS=" -Xdebug -Xnoagent -Djava.compiler=NONE -Xrunjdwp:transport=dt_socket,address=8000,server=y,suspend=n "
fi

echo -e "Starting the ${SERVER_NAME} ...\c"
# 注意：这里使用了Dubbo自带的启动类 com.alibaba.dubbo.container.Main
${JAVA_HOME}/bin/java -Dapp.name=${SERVER_NAME} ${JAVA_OPTS} ${JAVA_DEBUG_OPTS} ${JAVA_JMX_OPTS} -classpath ${CONF_DIR}:${LIB_JARS} com.alibaba.dubbo.container.Main >> ${STDOUT_FILE} 2>&1