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
       sh 'mvn clean package'
   }
}
```
![image](https://github.com/firechiang/kubernetes-study/blob/master/jenkins/image/build03.PNG)