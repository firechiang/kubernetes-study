#### 一、创建任务
![image](https://github.com/firechiang/kubernetes-study/blob/master/jenkins/image/build01.PNG)
![image](https://github.com/firechiang/kubernetes-study/blob/master/jenkins/image/freestyle-job-simple01.png)

#### 二、配置参数，比如凭据参数，字符参数，密码参数，布尔值参数，文件参数，文本参数，运行时参数，选项参数等，用于打包时使用（注意：下面配置的是选项参数，配置的是开发和生产环境，在打包时可以选择具体要使用的选项值）
![image](https://github.com/firechiang/kubernetes-study/blob/master/jenkins/image/freestyle-job-simple02.png)

#### 三、配置Git代码
![image](https://github.com/firechiang/kubernetes-study/blob/master/jenkins/image/freestyle-job-simple03.png)

#### 四、配置构建脚本（Shell）代码
```bash
#!/bin/sh

export PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

# Print env variable
echo "[INFO] Print env variable"

# $deploy_env是获取我们上面配置的参数（注意：$deploy_env是选项参数我们在上面配置了多个值，在打包时可以选择具体使用那个值）
echo "Current deployment envrionment is $deploy_env" >> test.properties

# $version是获取我们上面配置的参数
echo "THe build is $version" >> test.properties

echo "[INFO] Done..."

# Check test properties
echo "[INFO] Check test properties"
if [ -s test.properties ]
then
  cat test.properties
  echo "[INFO] Done..."
else
  echo "test.properties is empty"
fi

echo "[INFO] Build finished（构建完成）..."
```

![image](https://github.com/firechiang/kubernetes-study/blob/master/jenkins/image/freestyle-job-simple04.png)

#### 五、打包示例
![image](https://github.com/firechiang/kubernetes-study/blob/master/jenkins/image/freestyle-job-simple05.png)
