#### 一、创建Playbooks相关工作目录（在Ansible机器上创建）
```bash
# 创建Playnooks测试工作目录
$ mkdir -p /home/playbooks-test && cd /home/playbooks-test

# 该文件夹用来存储目标部署服务器列表相关信息
$ mkdir -p inventory

# roles        文件夹用来存储部署任务列表
# stat-file    任务名称
# tasks        任务配置文件存放目录
# main.yml     是stat-file任务逻辑配置文件
$ mkdir -p roles && mkdir ./roles/stat-file && mkdir ./roles/stat-file/tasks && touch ./roles/stat-file/tasks/main.yml
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

#### 三、[vi /home/playbooks-test/roles/stat-file/tasks/main.yml] 配置stat-file任务要执行的逻辑（注意：stat-file任务是我们上面已经创建好了的）
```bash
# 任务名称
- name: Stat file
  # path=要获取的文件地址
  stat: "path=/home/copy-file"
  # 文件状态信息保存在script_stat变量里面
  register: script_stat

# 使用上一步生成的变量script_stat信息
- debug:
     # 如果文件存在就在任务执行过程中打印下面的信息（注意：script_stat 变量是上一步就创建好了的）
    msg: "文件信息: {{ script_stat }}"
  # 根据script_stat变量信息里面的stat信息里面的exists判断文件是否存在
  # 注意：下面这个判断不写，上面的信息是一定会打印的
  when: script_stat.stat.exists
```

#### 四、[vi /home/playbooks-test/deploy.yml] 配置Playbooks任务入口配置文件
```bash
# 要连接目标部署服务器列表（testservers是我们上面已经配置好了的目标部署服务器列表）
- hosts: "testservers"
  # 可以获取目标部署服务器的相关信息
  gather_facts: true
  # 在目标部署服务器上使用root账户
  remote_user: root
  # 执行stat-file目录的所有任务（注意：如果是单个任务最好是放到单个文件夹下）
  roles:
    - stat-file
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

TASK [stat-file : Stat file] ***************************************************************************************************************************************************
ok: [suse01-server08]

TASK [stat-file : debug] *******************************************************************************************************************************************************
ok: [suse01-server08] => {
    "msg": "文件信息: {'stat': {'charset': 'binary', 'uid': 0, 'exists': True, 'attr_flags': '', 'woth': False, 'isreg': True, 'device_type': 0, 'mtime': 1618558858.848555, 'block_size': 4096, 'inode': 67144926, 'isgid': False, 'size': 884808379, 'executable': False, 'isuid': False, 'readable': True, 'version': '18446744072709358605', 'pw_name': 'root', 'gid': 0, 'ischr': False, 'wusr': True, 'writeable': True, 'mimetype': 'application/x-rpm', 'blocks': 1728144, 'xoth': False, 'islnk': False, 'nlink': 1, 'issock': False, 'rgrp': True, 'gr_name': 'root', 'path': '/home/copy-file', 'xusr': False, 'atime': 1618559420.7936745, 'isdir': False, 'ctime': 1618558861.382542, 'isblk': False, 'wgrp': False, 'checksum': 'e33056103f378a6ac5c27360682dd5d26967b6ec', 'dev': 64768, 'roth': True, 'isfifo': False, 'mode': '0644', 'xgrp': False, 'rusr': True, 'attributes': []}, 'changed': False, 'failed': False}"
}

PLAY RECAP *********************************************************************************************************************************************************************
suse01-server08            : ok=4    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0 
```

