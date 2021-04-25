#### 一、创建任务
![image](https://github.com/firechiang/kubernetes-study/blob/master/jenkins/image/build01.PNG)
![image](https://github.com/firechiang/kubernetes-study/blob/master/jenkins/image/build02.PNG)
#### 二、编写脚本
```bash
#!groovy

pipeline {
    // 配置该任务在Jenkins master节点上执行
    agent {node {label 'master'}}
    // 配置全局环境变量
    environment {
        PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin"
	// 配置运行Jenkins的用户的主目录（注意：比如以root用户运行就是/root,如果是chiangfire用户运行就是/home/chiangfire）
        HOME="/root"
    }
    // 配置参数（注意：这些参数在打包时可以使用，在脚本里面也可以使用${xxx}获取，还有参数也可以在界面上配置）
    parameters {
	// 配置一个选项参数（注意：这个选项参数，在打包时可以选择具体要使用的值）
        choice(
	    // 选项参数具体的值，以换行符分割（注意：这里是配置了两个值一个dev一个prod，这样在打包时就可以选择具体的环境了）
	    choices: 'dev\nrprod',
	    // 选项参数的说明
	    description: 'Choose deploy environment',
	    // 选项参数的名称
	    name: 'deploy_env'
	)
        // 配置一个文本参数 name=参数名称，defaultValue=参数的值，description=参数说明
        string (name: 'version', defaultValue: '1.10', description: 'Fill in your ansible repo branch')
    }
    
    stages {
        // 拉取Git代码
        stage ("Pull deploy code") {
	    steps{
	        // 命令行模块，写Shell命令
	        sh 'git config --global http.sslVerify false'
	        // 拉取代码 dir=在那个目录下执行命令，${env.WORKSPACE}=从Jenkins环境变量里面获取值（注意：WORKSPACE的值是Jenkins拉取代码的存放目录）
		dir ("${env.WORKSPACE}"){
		    // Git模块
	            // branch=代码分支
		    // credentialsId=拉取Git所使用凭据的ID（注意：在Jenkins里面配置Git账号密码或SSH秘钥之后，再返回查看凭据列表时会有凭据ID）
		    // url=Git源码地址
	            git branch: 'master', credentialsId: '63374ba5-4891-4f21-b5df-87fb5b925ca1', url: 'https://github.com/firechiang/springboot-demo.git'
	        }
	    }
        }
	
        // 将上面配置的参数打印到test.properties文件里面
	stage ("Print env variable") {
	    steps{
	        // dir=在那个目录下执行命令，${env.WORKSPACE}=从Jenkins环境变量里面获取值（注意：WORKSPACE的值是Jenkins拉取代码的存放目录）
	        dir ("${env.WORKSPACE}"){
		    // 命令行模块，写Shell命令（注意：三个双引号包裹的Shell命令可以换行，还有下面的获取的环境变量都是我们在上面配置好了的参数）
		    sh """
		    echo "Current deployment envrionment is $deploy_env" >> test.properties
		    echo "THe build is $version" >> test.properties
		    echo "[INFO] Done..."
		    """
		}
	    }
	}
		
	// 验证上面配置的参数是否打印到test.properties文件
	stage("Check test properties") {
            steps{
                // dir=在那个目录下执行命令，${env.WORKSPACE}=从Jenkins环境变量里面获取值（注意：WORKSPACE的值是Jenkins拉取代码的存放目录）
                dir ("${env.WORKSPACE}") {
                    // 命令行模块，写Shell命令（注意：三个双引号包裹的Shell命令可以换行）
                    sh """
                    echo "[INFO] Check test properties"
                    if [ -s test.properties ]
                    then 
                        cat test.properties
                        echo "[INFO] 文件写入成功，可到 ${env.WORKSPACE} 目录查看"
                    else
                        echo "test.properties is empty"
                    fi
                    """
		    // 打印输出模块，后面写要在控制台输出的信息即可
                    echo "[INFO] Build finished（构建成功）..."
                }
            }
        }
    }
}
```
![image](https://github.com/firechiang/kubernetes-study/blob/master/jenkins/image/pipeline-job-simple01.png)


#### 三、打包示例
![image](https://github.com/firechiang/kubernetes-study/blob/master/jenkins/image/freestyle-job-simple05.png)
