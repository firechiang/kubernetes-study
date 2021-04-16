#### 一、创建Playbooks相关工作目录（在Ansible机器上创建）
```bash
# 创建Playnooks测试工作目录
$ mkdir -p /home/playbooks-test && cd /home/playbooks-test

# 该文件夹用来存储目标部署服务器列表相关信息
$ mkdir -p inventory

# roles        文件夹用来存储部署任务列表
# create-file  任务名称
# tasks        任务配置文件存放目录
# main.yml     是create-file任务逻辑配置文件
$ mkdir -p roles && mkdir ./roles/create-file && mkdir ./roles/create-file/tasks && touch ./roles/create-file/tasks/main.yml
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

#### 三、[vi /home/playbooks-test/roles/create-file/tasks/main.yml] 配置create-file任务要执行的逻辑（注意：create-file任务是我们上面已经创建好了的）
```bash
# 任务名称
- name: Create file
  # path=文件要创建在那个目录，mode=文件权限，0755是系统权限，owner=文件所属用户，group=文件所属组
  file: "path=/home/test-file.txt state=touch mode=0755 owner=root group=root"
```

#### 四、[vi /home/playbooks-test/deploy.yml] 配置Playbooks任务入口配置文件
```bash
# 要连接目标部署服务器列表（testservers是我们上面已经配置好了的目标部署服务器列表）
- hosts: "testservers"
  # 可以获取目标部署服务器的相关信息
  gather_facts: true
  # 在目标部署服务器上使用root账户
  remote_user: root
  # 执行create-file目录的所有任务（注意：如果是单个任务最好是放到单个文件夹下）
  roles:
    - create-file
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

TASK [create-file : Create file] ***********************************************************************************************************************************************
changed: [suse01-server08]

PLAY RECAP *********************************************************************************************************************************************************************
suse01-server08            : ok=3    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0 
```

