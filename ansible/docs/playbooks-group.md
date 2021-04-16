#### 一、创建Playbooks相关工作目录（在Ansible机器上创建）
```bash
# 创建Playnooks测试工作目录
$ mkdir -p /home/playbooks-test && cd /home/playbooks-test

# 该文件夹用来存储目标部署服务器列表相关信息
$ mkdir -p inventory

# roles            文件夹用来存储部署任务列表
# group-test       任务名称
# tasks            任务配置文件存放目录
# main.yml         是group-test任务逻辑配置文件
$ mkdir -p roles && mkdir ./roles/group-test && mkdir ./roles/group-test/tasks && touch ./roles/group-test/tasks/main.yml
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

#### 四、[vi /home/playbooks-test/roles/group-test/tasks/main.yml] 配置group-test任务要执行的逻辑（注意：group-test任务是我们上面已经创建好了的）
```bash
# 在目标服务器上执行命令将下面的信息输出到目标部署服务器的/home/ansible-playbook-log文件里面
- name: Print server name and user to remote testbox
  # 执行命令（注意：user，server_name，output 都是在目标部署服务器相关信息里面配置的（在上面配置的））
  shell: "echo 'Currently {{ user }} is logining {{ server_name }}' > {{ output }}"
  
# 在目标服务器上创建文件 
- name: Create file
  # path=文件要创建在那个目录，mode=文件权限，0755是系统权限，owner=文件所属用户，group=文件所属组
  file: "path=/home/test-file.txt state=touch mode=0755 owner=root group=root"
  
# 在目标服务器上安装软件  
- name: Install yum
  # yum=标识使用yum包管理工具安装软件，pkg=要安装软件的名称，state=latest（标识安装最新版本）
  # 注意：也可以写apt就使用apt包管理工具，但是要目标服务器上有没有这个包管理工具
  yum: "pkg=net-tools state=latest"  
  
# 获取目标服务器上的某个文件信息并保存在某个变量里面供后面任务使用
- name: Stat file
  # path=要获取的文件地址
  stat: "path=/lib/sysctl.d"
  # 文件状态信息保存在script_stat变量里面
  register: script_stat

# 使用上一步生成的变量script_stat信息
- debug:
     # 如果文件存在就在任务执行过程中打印下面的信息（注意：script_stat 变量是上一步就创建好了的）
    msg: "文件信息: {{ script_stat }}"
  # 根据script_stat变量信息里面的stat信息里面的exists判断文件是否存在
  # 注意：下面这个判断不写，上面的信息是一定会打印的
  when: script_stat.stat.exists  
    
# 用配置信息替换模板配置文件里面的相关信息并将替换后的配置文件拷贝到目标服务器
- name: Properties test
  # src=模板配置文件地址， dest=替换后的配置文件拷贝到目标服务器地址
  template: "src=/home/playbooks-test/template/test.conf.j2 dest=/home/test.conf"
  
# 在目标服务器上启动或重启或关闭某个服务
- name: Service test
  # name=服务名称，state=要执行的状态（started=启动，reloaded=重新加载配置文件, restarted=重启, stopped=停止）
  service: "name=postfix state=started"  
```

#### 五、[vi /home/playbooks-test/deploy.yml] 配置Playbooks任务入口配置文件
```bash
# 要连接目标部署服务器列表（testservers是我们上面已经配置好了的目标部署服务器列表）
- hosts: "testservers"
  # 可以获取目标部署服务器的相关信息
  gather_facts: true
  # 在目标部署服务器上使用root账户
  remote_user: root
  # 执行group-test目录的所有任务（注意：如果是单个任务最好是放到单个文件夹下）
  roles:
    - group-test
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

TASK [group-test : Print server name and user to remote testbox] ***************************************************************************************************************
changed: [suse01-server08]

TASK [group-test : Create file] ************************************************************************************************************************************************
changed: [suse01-server08]

TASK [group-test : Install yum] ************************************************************************************************************************************************
ok: [suse01-server08]

TASK [group-test : Stat file] **************************************************************************************************************************************************
ok: [suse01-server08]

TASK [group-test : debug] ******************************************************************************************************************************************************
ok: [suse01-server08] => {
    "msg": "文件信息: {'stat': {'charset': 'binary', 'uid': 0, 'exists': True, 'attr_flags': '', 'woth': False, 'isreg': False, 'device_type': 0, 'mtime': 1618540244.8513303, 'block_size': 4096, 'inode': 67273211, 'isgid': False, 'size': 85, 'executable': True, 'isuid': False, 'readable': True, 'version': '204883002', 'pw_name': 'root', 'gid': 0, 'ischr': False, 'wusr': True, 'writeable': True, 'mimetype': 'inode/directory', 'blocks': 0, 'xoth': True, 'islnk': False, 'nlink': 2, 'issock': False, 'rgrp': True, 'gr_name': 'root', 'path': '/lib/sysctl.d', 'xusr': True, 'atime': 1618540275.9260335, 'isdir': True, 'ctime': 1618540244.8513303, 'isblk': False, 'wgrp': False, 'xgrp': True, 'dev': 64768, 'roth': True, 'isfifo': False, 'mode': '0755', 'rusr': True, 'attributes': []}, 'changed': False, 'failed': False}"
}

TASK [group-test : Properties test] ********************************************************************************************************************************************
ok: [suse01-server08]

TASK [group-test : Service test] ***********************************************************************************************************************************************
changed: [suse01-server08]

PLAY RECAP *********************************************************************************************************************************************************************
suse01-server08            : ok=8    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

