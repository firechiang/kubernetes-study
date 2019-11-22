#### 一、创建任务
![image](https://github.com/firechiang/kubernetes-study/blob/master/jenkins/image/build01.PNG)
![image](https://github.com/firechiang/kubernetes-study/blob/master/jenkins/image/build02.PNG)
#### 二、编写脚本（注意：该机器需手动安装Maven工具）
```bash
node {
   // 定义环境变量（在其它的地方可以使用$MODULE_NAME获取该值）
   env.MODULE_NAME = "springboot-demo"
   // 拉取代码
   stage('Preparation') { // staged的名字可以随便取
      git 'https://github.com/firechiang/springboot-demo.git'
   }
   // 使用Maven打包 
   stage('Maven Build') {
      // sh 就是要执行的命令
      // 多模块工程，只打包一个模块可使用命令（mvn -pl 模块名称 -am clean package）打包
      sh 'mvn clean package'
   }
   // 构建Docker镜像并推送到镜像仓库
   stage('Docker Build') {
      // 构建Docker镜像，${JOB_NAME}是Jenkins自带的环境变量，就是取当前构建的名称（springboot-demo）。. 表示Dockerfile在当前目录
      // 注意：${BUILD_TIMESTAMP}环境变量是需要安装插件ZenTimestamp，并在 系统管理>系统配置>全局属性中，开启Date pattern for the BUILD_TIMESTAMP
      sh 'docker build -t chiangfire/${JOB_NAME}:${BUILD_TIMESTAMP} .'
      // 推送镜像到仓库（注意：要事先在机器上登录镜像仓库，否则无法推送，会报没有权限的错误）
      sh 'docker push chiangfire/${JOB_NAME}:${BUILD_TIMESTAMP}'
   }
}
```
![image](https://github.com/firechiang/kubernetes-study/blob/master/jenkins/image/build04.PNG)