#### 一、[安装Python3环境](https://github.com/firechiang/python-study/blob/main/README.md)

#### 二、安装Virtualenv（这个工具可为每个Python程序创建独立的依赖运行环境）
```bash
$ pip3 install virtualenv
# 创建软连接使我们在命令行可以直接用virtualenv命令（就相当于创建了环境变量）
$ ln -s /usr/local/python3/bin/virtualenv /usr/bin/virtualenv
```

#### 三、使用virtualenv创建一个Python3.8独立运行环境
```bash
# -p指定独立运行环境所使用的Python，后面是指定独立运行环境目录
$ virtualenv -p /usr/local/python3/bin/python3.8 /usr/local/python3/py3.8-ansible-2.10-env
```

#### 四、安装Ansible
```bash
# 定位到Ansible独立运行环境目录（也就是上面使用virtualenv所创建的目录）
$ cd /usr/local/python3/py3.8-ansible-2.10-env

# 克隆Ansible源码
$ git clone https://github.com/ansible/ansible.git

# 到Ansible源码目录
$ cd ansible

# 切换Ansible源码到2.10
$ git checkout stable-2.10

# 加载Ansible独立运行环境
$ source /usr/local/python3/py3.8-ansible-2.10-env/bin/activate

# 安装Ansible相关依赖
$ pip3 install paramiko PyYAML jinja2

# 加载安装Ansible-2.10版本
$ source /usr/local/python3/py3.8-ansible-2.10-env/ansible/hacking/env-setup -q

# 验证Ansible是否安装完成
$ ansible --version
```
