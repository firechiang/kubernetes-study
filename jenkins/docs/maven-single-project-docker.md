#### 一、创建任务
![image](https://github.com/firechiang/kubernetes-study/blob/master/jenkins/image/build01.PNG)
![image](https://github.com/firechiang/kubernetes-study/blob/master/jenkins/image/build02.PNG)
#### 二、编写脚本（注意：该机器需手动安装Maven工具）
```bash
node {
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
   // 构建Docker镜像
   stage('Docker Build') {
       // 构建Docker镜像，名为k8s-deploy-job-demo，版本v1，. 表示构建完成后放到当前目录
       // 注意：这个命令需要Dockerfile配置文件，已经写好了，可查看（就在当前目录）
       sh 'docker build -t springboot-demo:v1 .'
   }
}
```
![image](https://github.com/firechiang/kubernetes-study/blob/master/jenkins/image/build04.PNG)