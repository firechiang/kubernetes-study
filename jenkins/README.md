#### 一、下载安装包，[如需Docker部署请参考官方文档](https://jenkins.io/zh/doc/book/installing/)
```bash
$ wget -P /home/jenkins http://mirrors.jenkins.io/war-stable/latest/jenkins.war
```

#### 二、修改jenkins数据目录（注意：这一步废弃了，不需要了，我们在最下面的脚本里面使用了环境变量的方式配置了）
```bash
# 到jenkins的war包目录
$ cd /home/jenkins

# 查看jenkins的启动参数说明
$ java -jar jenkins.war --help

# 提取war里面的web.xml配置文件
$ jar xf /home/jenkins/jenkins.war WEB-INF/web.xml

# 提取war里面的JENKINS.RSA签名文件
$ jar xf /home/jenkins/jenkins.war META-INF/JENKINS.RSA

# 修改jenkins数据目录（找到HUDSON_HOME为env-entry-value配置/home/jenkins/data值，这个就是jenkins的数据目录）
$ vi /home/jenkins/WEB-INF/web.xml

# 删除该文件里面的所有内容
$ vi /home/jenkins/META-INF/JENKINS.RSA

# 更新web.xml配置文件到war包（存在覆盖，不存在就新增）
$ jar uf /home/jenkins/jenkins.war WEB-INF/web.xml

# 更新JENKINS.RSA签名文件到war包（存在覆盖，不存在就新增）
$ jar uf /home/jenkins/jenkins.war META-INF/JENKINS.RSA
```

#### 三、创建[vi /home/jenkins/jenkins.sh]启动和关闭脚本文件
```bash
#!/bin/bash
# jenkins war包目录
export JENKINS_WAR_HOME=/home/jenkins
# jenkins数据目录
export JENKINS_HOME=$JENKINS_WAR_HOME/data

pid=`ps -ef | grep jenkins.war | grep -v 'grep'| awk '{print $2}'`    
if [ "$1" = "start" ];then 
    if [ -n "$pid" ];then
        echo 'jenkins is running...' 
    else
        nohup $JAVA_HOME/bin/java -Xms768m -Xmx768m        \
	           -XX:+UseConcMarkSweepGC                     \
	           -XX:+CMSParallelRemarkEnabled               \
	           -XX:+HeapDumpOnOutOfMemoryError             \
	           -XX:HeapDumpPath=/home/jenkins/jenkins.dump \
	           -jar $JENKINS_WAR_HOME/jenkins.war          \
	           --webroot=/home/jenkins/src                 \
	           --pluginroot=/home/jenkins/plugin           \
	           --logfile=/home/jenkins/jenkins.log         \
	           --httpPort=8099 >/dev/null 2>&1 &           
    fi
elif [ "$1" = "stop" ];then
    exec ps -ef | grep jenkins | grep -v grep | awk '{print $2}'| xargs kill -9 | echo 'jenkins is stop...'
else
    echo "Please input like this：./jenkins.sh start or ./jenkins stop"
fi
```

#### 四、给jenkins.sh脚本赋予权限
```bash
$ chmod +x /home/jenkins/jenkins.sh
```