#### 一、创建任务
![image](https://github.com/firechiang/kubernetes-study/blob/master/jenkins/image/build01.PNG)
![image](https://github.com/firechiang/kubernetes-study/blob/master/jenkins/image/freestyle-job-simple01.png)

#### 二、配置Shell脚本代码
```bash
#!/bin/sh

user=`whoami`

if [ $user == 'deploy' ]
then
	echo "Hello, my name is $user"
else
	echo "Sorry, I am not $user"
fi

ip addr

cat /etc/system-release

free -m

df -h

py_cmd=`which python`

$py_cmd --version

echo "任务执行完成"
```

![image](https://github.com/firechiang/kubernetes-study/blob/master/jenkins/image/shell-freestyle-job01.png)