#### 一、创建Playbooks相关工作目录（在Ansible机器上创建）
```bash
# 创建Playnooks测试工作目录
$ mkdir -p /home/playbooks-test && cd /home/playbooks-test

# 该文件夹用来存储目标部署服务器列表相关信息
$ mkdir -p inventory

# roles        文件夹用来存储部署任务列表
# copy-file    任务名称
# tasks        任务配置文件存放目录
# main.yml     是copy-file任务逻辑配置文件
$ mkdir -p roles && mkdir ./roles/copy-file && mkdir ./roles/copy-file/tasks && touch ./roles/copy-file/tasks/main.yml
```

#### 二、[vi /home/playbooks-test/inventory/testenv] 配置目标部署服务器相关信息（注意：实际配置时删除注释）
```bash
# 目标部署服务器列表而且需要可以免密登录（注意：可以写IP或域名，testservers是名称可以随便起）
[testservers]
suse01-server08

# 连接目标部署服务器可使用的参数（就是可以使用，比如 {{ server_name }} 获取值）
[testservers:vars]
server_name=suse01-server08
user=root
output=/home/ansible-playbook-log
```

#### 三、[vi /home/playbooks-test/roles/copy-file/tasks/main.yml] 配置copy-file任务要执行的逻辑（注意：copy-file任务是我们上面已经创建好了的）
```bash
# 任务名称
- name: Copy file
  # remote_src=开启远程文件传输，src=源文件地址，dest=目标服务器地址，mode=文件权限，force=任务是否强制执行
  copy: "remote_src=no src=/home/copy-file dest=/home/copy-file mode=0644 force=yes"
```

#### 四、[vi /home/playbooks-test/deploy.yml] 配置Playbooks任务入口配置文件
```bash
# 要连接目标部署服务器列表（testservers是我们上面已经配置好了的目标部署服务器列表）
- hosts: "testservers"
  # 可以获取目标部署服务器的相关信息
  gather_facts: true
  # 在目标部署服务器上使用root账户
  remote_user: root
  # 执行copy-file目录的所有任务（注意：如果是单个任务最好是放到单个文件夹下）
  roles:
    - copy-file
```

#### 五、执行部署文件（执行完成后可到目标部署服务器上查看是否有 /home/ansible-playbook-log 文件存在）
```bash
# /home/playbooks-test/inventory/testenv 是目标部署服务器列表相关信息
# /home/playbooks-test/deploy.yml        是Playbooks任务入口配置文件
$ ansible-playbook -i /home/playbooks-test/inventory/testenv /home/playbooks-test/deploy.yml
# 执行成功会有以下输出
PLAY [testservers] *************************************************************************************************************************************************************

TASK [Gathering Facts] *********************************************************************************************************************************************************
ok: [suse01-server08]

TASK [copy-file : Copy file] ***********************************************************************************************************************************************
changed: [suse01-server08]

PLAY RECAP *********************************************************************************************************************************************************************
suse01-server08            : ok=3    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0 
```

