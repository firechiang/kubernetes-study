#### 一、创建Playbooks相关工作目录（在Ansible机器上创建）
```bash
# 创建Playnooks测试工作目录
$ mkdir -p /home/playbooks-test && cd /home/playbooks-test

# 该文件夹用来存储目标部署服务器列表相关信息
$ mkdir -p inventory

# roles            文件夹用来存储部署任务列表
# properties-test  任务名称
# tasks            任务配置文件存放目录
# main.yml         是properties-test任务逻辑配置文件
$ mkdir -p roles && mkdir ./roles/properties-test && mkdir ./roles/properties-test/tasks && touch ./roles/properties-test/tasks/main.yml
```

#### 二、[mkdir -p /home/playbooks-test/template && vi /home/playbooks-test/template/test.conf.j2] 创建模板配置文件
```bash
server_name={{server_name}}
user={{user}}
output={{output}}
```

#### 三、[vi /home/playbooks-test/inventory/testenv] 配置目标部署服务器以及配置相关信息（注意：实际配置时删除注释）
```bash
# 目标部署服务器列表而且需要可以免密登录（注意：可以写IP或域名，testservers是名称可以随便起）
[testservers]
suse01-server08

# 配置信息，就要将下面的配置信息替换模板配置文件里面的信息（下面的配置信息使用，比如 {{ server_name }} 获取值）
[testservers:vars]
server_name=suse01-server08
user=root
output=/home/ansible-playbook-log
```

#### 四、[vi /home/playbooks-test/roles/properties-test/tasks/main.yml] 配置properties-test任务要执行的逻辑（注意：properties-test任务是我们上面已经创建好了的）
```bash
# 任务名称
- name: Properties test
  # src=模板配置文件地址， dest=替换后的配置文件拷贝到目标服务器地址
  template: "src=/home/playbooks-test/template/test.conf.j2 dest=/home/test.conf"
```

#### 五、[vi /home/playbooks-test/deploy.yml] 配置Playbooks任务入口配置文件
```bash
# 要连接目标部署服务器列表（testservers是我们上面已经配置好了的目标部署服务器列表）
- hosts: "testservers"
  # 可以获取目标部署服务器的相关信息
  gather_facts: true
  # 在目标部署服务器上使用root账户
  remote_user: root
  # 执行properties-test目录的所有任务（注意：如果是单个任务最好是放到单个文件夹下）
  roles:
    - properties-test
```

#### 六、执行部署文件（执行完成后可到目标部署服务器上查看是否有 /home/ansible-playbook-log 文件存在）
```bash
# /home/playbooks-test/inventory/testenv 是目标部署服务器列表相关信息
# /home/playbooks-test/deploy.yml        是Playbooks任务入口配置文件
$ ansible-playbook -i /home/playbooks-test/inventory/testenv /home/playbooks-test/deploy.yml
# 执行成功会有以下输出
PLAY [testservers] *************************************************************************************************************************************************************

TASK [Gathering Facts] *********************************************************************************************************************************************************
ok: [suse01-server08]

TASK [properties-test : Properties test] ***********************************************************************************************************************************************
changed: [suse01-server08]

PLAY RECAP *********************************************************************************************************************************************************************
suse01-server08            : ok=3    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0 
```

