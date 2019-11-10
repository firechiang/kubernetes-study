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

#### 三、创建[vi /etc/init.d/jenkins]启动脚本（注意：修改jenkins的绑定端口和war包目录以及java的安装目录）
```bash
#!/bin/sh
# jenkins服务必须在2，3，4，5运行级下被启动或关闭，启动的优先级是80，关闭的优先级是93
#chkconfig: 2345 80 93
#description: this script to start and stop jenkins server
#version: 1.0
#setting variable

# 绑定端口
HTTP_PORT=8099
# jenkins war包目录（注意：这个目录会被当成jenkins的根目录）
JENKINS_WAR_HOME=/home/jenkins
# java安装目录（注意：因为init.d目录下脚本无法加载/etc/profile文件里面的环境变量，所以要定义java安装目录）
JAVA_HOME=/usr/lib/jvm/jdk1.8.0_171

# 内存溢出导出堆文件
JENKINS_DUMP_FILE=$JENKINS_WAR_HOME/jenkins.dump
# 日志文件
JENKINS_LOG_FILE=$JENKINS_WAR_HOME/jenkins.log
# 插件安装目录
JENKINS_PLUGIN_DIR=$JENKINS_WAR_HOME/plugin
# 源码解压目录
JENKINS_SRC_DIR=$JENKINS_WAR_HOME/src
# jenkins数据目录
export JENKINS_HOME=$JENKINS_WAR_HOME/data

JENKINS_PID=`ps -ef | grep jenkins.war | grep -v 'grep'| awk '{print $2}'`

case "$1" in
    start)
        if [ -n "$JENKINS_PID" ]
        then
                echo "jenkins-$JENKINS_PID exists, process is already running or crashed"
        else
                nohup $JAVA_HOME/bin/java -Xms768m -Xmx768m         \
	                   -XX:+UseConcMarkSweepGC                  \
	                   -XX:+CMSParallelRemarkEnabled            \
	                   -XX:+HeapDumpOnOutOfMemoryError          \
	                   -XX:HeapDumpPath=$JENKINS_DUMP_FILE      \
	                   -jar $JENKINS_WAR_HOME/jenkins.war       \
	                   --webroot=$JENKINS_SRC_DIR               \
	                   --pluginroot=$JENKINS_PLUGIN_DIR         \
	                   --logfile=$JENKINS_LOG_FILE              \
	                   --httpPort=$HTTP_PORT >/dev/null 2>&1 &
	        echo "Jenkins Started"       
        fi
        ;;
    stop)
        if [ ! -n "$JENKINS_PID" ]
        then
                echo "Jenkins does not exist, process is not running"
        else
                kill -9 $JENKINS_PID
                echo "Jenkins stopped"
        fi
        ;;
    *)
        echo "Please use start or stop as first argument"
        ;;
esac
```

#### 四、给jenkins.sh脚本赋予权限
```bash
$ chmod +x /etc/init.d/jenkins
```

#### 五、启动Jenkins
```bash
$ service jenkins start           # 启动jenkins
$ service jenkins stop            # 停止jenkins
$ sudo chkconfig jenkins on       # 设置jenkins开机启动（建议开启）
$ sudo chkconfig jenkins off      # 关闭jenkins开机启动
```

#### 六、初始化Jenkins配置
![image](https://github.com/firechiang/kubernetes-study/raw/master/jenkins/image/setup-jenkins-01.jpg)
![image](https://github.com/firechiang/kubernetes-study/raw/master/jenkins/image/setup-jenkins-02.jpg)
![image](https://github.com/firechiang/kubernetes-study/raw/master/jenkins/image/setup-jenkins-03.jpg)
