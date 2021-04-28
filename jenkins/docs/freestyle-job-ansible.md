#### 一、[创建或配置Ansible部署任务,建议将Ansible的部署脚本写到代码里面（注意：这个里面的示例只是Ansible的简单使用并不是真实的部署脚本）](https://github.com/firechiang/kubernetes-study/blob/master/ansible/docs/playbooks-group.md)
#### 二、创建Jenkins构建任务
![image](https://github.com/firechiang/kubernetes-study/blob/master/jenkins/image/build01.PNG)
![image](https://github.com/firechiang/kubernetes-study/blob/master/jenkins/image/freestyle-job-simple01.png)

#### 三、配置参数，比如凭据参数，字符参数，密码参数，布尔值参数，文件参数，文本参数，运行时参数，选项参数等，用于打包时使用（注意：下面配置的是选项参数，配置的是开发和生产环境，在打包时可以选择具体要使用的选项值）
![image](https://github.com/firechiang/kubernetes-study/blob/master/jenkins/image/freestyle-job-simple02.png)

#### 四、配置Git代码
![image](https://github.com/firechiang/kubernetes-study/blob/master/jenkins/image/freestyle-job-simple03.png)


#### 五、配置Maven打包相关
![image](https://github.com/firechiang/kubernetes-study/blob/master/jenkins/image/freestyle-job-gitmaven01.png)

#### 六、配置Ansible部署脚本
```bash
#!/bin/sh
# 关闭命令行扩张功能（避免其它日志，干扰Jenkins日志）
set +x
# 加载Ansible独立运行环境（注意：这个的前提是我们的机器上已经安装好了Ansible）
source /home/py3.6-ansible-2.10-env/bin/activate
# 加载Ansible到内存（注意：这个的前提是我们的机器上已经安装好了Ansible）
source /home/py3.6-ansible-2.10-env/ansible/hacking/env-setup -q

# 打印源码编译目录（注意：这个环境变量是Jenkins内置的）
echo $WORKSPACE

# 打印输出Ansible相关信息
ansible --version
ansible-playbook --version

# 打印目标服务器IP网卡相关信息（注意：正常要在目标服务器上执行命令，一般不采用这种方式）
# /home/playbooks-test/inventory/testenv 是目标服务器相关的配置信息
# testservers                            是目标服务器列表信息（就是目标服务器IP等等）
# -m command -a "ip addr"                在目标服务器上执行"ip addr"命令，并将输出信息输出到Jenkins控制台
ansible -i /home/playbooks-test/inventory/testenv testservers -m command -a "ip addr"


# 执行Ansible部署任务（注意：这个Ansible部署任务是我们在第一步就创建好了的）
# /home/playbooks-test/inventory/testenv 是目标部署服务器列表相关信息
# /home/playbooks-test/deploy.yml        是Playbooks任务入口配置文件
# -e branch=$branch                      是添加参数branch它的值是$branch就是Jenkins参数branch的值（注意：这个参数在Ansible里面可以使用{{branch}}获取）
ansible-playbook -i /home/playbooks-test/inventory/testenv /home/playbooks-test/deploy.yml -e project=test-test -e branch=$branch

# 最后开启命令行扩张功能（因为我们上面把它给关了）
set -x
```

![image](https://github.com/firechiang/kubernetes-study/blob/master/jenkins/image/freestyle-job-simple04.png)

#### 七、打包示例
![image](https://github.com/firechiang/kubernetes-study/blob/master/jenkins/image/freestyle-job-simple05.png)