---
title: Hadoop2.6 与 Spark1.5 分布式安装部署
date: 2018-09-04 21:00:54
tags:
---


> 机子是两台阿里云 ECS 上的实例，系统都是 CentOS 7.2，未预装任何东西，所以本教程可以帮助你从 0 开始搭建 Spark 分布式集群。下面是集群介绍

Hosts | IP Address | Configuration  | Environment
--- | --- | --- | ---
Master | 192.168.1.77 | CPU: 2 cores RAM: 8G | `JDK: 1.8.0_181` `Scala: 2.10.6` `Hadoop: 2.7.6` `Spark: 1.5.2` `Python: 2.7.5`
Slave | 192.168.1.78 | CPU: 2 cores RAM: 8G | `JDK: 1.8.0_181` `Scala: 2.10.6` `Hadoop: 2.7.6` `Spark: 1.5.2` `Python: 2.7.5`

> Environment 会在下面依次安装。

文章分为三步：准备阶段，Hadoop 安装配置阶段，Spark 安装配置阶段。

<!--more-->

##### 准备：设置 Hosts
- **Master**

    - 追加 Hosts 文件内容：
        ``` 
        vim /etc/hosts 
        ```
        ```
        192.168.1.77 master
        192.168.1.78 slave
        ```

    - 追加 network 内容：
        ```
        vim /etc/sysconfig/network
        ```
        ```
        NETWORKING=yes
        HOSTNAME=master
        ```

- **Slave**

    - 打开 Hosts 文件：
        ``` 
        vim /etc/hosts 
        ```
        ```
        192.168.1.77 master
        192.168.1.78 slave
        ```

    - 追加 network 内容：
        ```
        vim /etc/sysconfig/network
        ```
        ```
        NETWORKING=yes
        HOSTNAME=master
        ```

##### 准备：关闭 Selinux 和防火墙 Firewall
- **Master**

    - 修改 Selinux 配置文件：
        ```
        vim /etc/selinux/config
        ```
        ```
        SELINUX=disabled
        ```
        ```
        # This file controls the state of SELinux on the system.
        # SELINUX= can take one of these three values:
        #     enforcing - SELinux security policy is enforced.
        #     permissive - SELinux prints warnings instead of enforcing.
        #     disabled - No SELinux policy is loaded.
        SELINUX=disabled
        # SELINUXTYPE= can take one of three two values:
        #     targeted - Targeted processes are protected,
        #     minimum - Modification of targeted policy. Only selected processes are protected.
        #     mls - Multi Level Security protection.
        SELINUXTYPE=targeted
        ```

    - 关闭防火墙 Firewall：
        ```
        ipdatable -F;
        ```

    - 查看防火墙是否关闭：
        ```
        iptabls -nvL
        ```
        ```
        [root@izbp11ddoyj3i3tqpvtim9z conf]# iptables -nvL
        Chain INPUT (policy ACCEPT 1421K packets, 606M bytes)
         pkts bytes target     prot opt in     out     source               destination
    
        Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
         pkts bytes target     prot opt in     out     source               destination
    
        Chain OUTPUT (policy ACCEPT 851K packets, 1534M bytes)
         pkts bytes target     prot opt in     out     source               destination
        ```

    - 重新启动实例

- **Slave**

    - 修改 Selinux 配置文件：
        ```
        vim /etc/selinux/config
        ```
        ```
        SELINUX=disabled
        ```
        ```
        # This file controls the state of SELinux on the system.
        # SELINUX= can take one of these three values:
        #     enforcing - SELinux security policy is enforced.
        #     permissive - SELinux prints warnings instead of enforcing.
        #     disabled - No SELinux policy is loaded.
        SELINUX=disabled
        # SELINUXTYPE= can take one of three two values:
        #     targeted - Targeted processes are protected,
        #     minimum - Modification of targeted policy. Only selected processes are protected.
        #     mls - Multi Level Security protection.
        SELINUXTYPE=targeted
        ```

    - 关闭防火墙 Firewall：
        ```
        ipdatable -F;
        ```

    - 查看防火墙是否关闭：
        ```
        iptabls -nvL
        ```
        ```
        [root@izbp11ddoyj3i3tqpvtimaz conf]# iptables -nvL
        Chain INPUT (policy ACCEPT 1421K packets, 606M bytes)
         pkts bytes target     prot opt in     out     source               destination
    
        Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
         pkts bytes target     prot opt in     out     source               destination
    
        Chain OUTPUT (policy ACCEPT 851K packets, 1534M bytes)
         pkts bytes target     prot opt in     out     source               destination
        ```

    - 重新启动实例

##### 准备：配置免密钥登录
- **Master**
    - ssh-keygen 命令
        ```
        [root@izbp11ddoyj3i3tqpvtim9z ~]# ssh-keygen 
        cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
        scp ~/.ssh/authorized_keys slave:~/.ssh/
        ```
        > 注：第一次连接时，输入 yes 继续连接。
        
        > ` ssh-keygen ` 之后，一路回车。运行结束后，在 ` ~/.ssh/ ` 目录下，会生成两个新文件 `id_rsa` 和 `id_rsa.pub` ， 即私钥和公钥。
        ` cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys ` 将公钥输出到 ` authorized_keys`
        ` scp ~/.ssh/authorized_keys slave:~/.ssh/ ` 传到 Slave 节点（已配置域名映射）
        
    - 测试是否可免密钥登录 Slave
    
    ```
    [root@izbp11ddoyj3i3tqpvtim9z ~]# ssh slave
    Last login: Tue Aug 21 17:58:08 2018 from 192.168.1.77
    
    Welcome to Alibaba Cloud Elastic Compute Service !
    
    [root@izbp11ddoyj3i3tqpvtimaz ~]# exit
    logout
    Connection to slave closed.
    [root@izbp11ddoyj3i3tqpvtim9z ~]#
    ```

    

##### 准备：安装 Java

- **Master**

    1. 下载 JDK ，我使用 `jdk-8u181-linux-x64.tar.gz`，点击[这里](http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html)下载

    2. 解压 JDK
        ```
        tar zxvf jdk-8u181-linux-x64.tar.gz
        mv jdk1.8.0_181 /usr/local
        ```

    3. JDK 环境变量

        ```
        vim /etc/profile.d/java.sh
        ```
        ```
        export JAVA_HOME=/usr/local/jdk1.8.0_181
        export PATH=$PATH:$JAVA_HOME/bin
        export CLASSPATH=.:$JAVA_HOME/jre/lib/rt.jar:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
        ```

    4. 使环境变量生效

        ```
        source /etc/profile.d/java.sh
        java -version
        ```
        ```
        [root@izbp11ddoyj3i3tqpvtim9z local]# java -version
        java version "1.8.0_181"
        Java(TM) SE Runtime Environment (build 1.8.0_181-b13)
        Java HotSpot(TM) 64-Bit Server VM (build 25.181-b13, mixed mode)
        ```

    5. 将 JDK 压缩包和 JDK 配置文件传给 Slave

        ```
        scp jdk-8u181-linux-x64.tar.gz slave:/usr/local
        scp /etc/profile.d/java.sh slave:/etc/profile.d
        ```

- **Slave**

    1. 解压 JDK
        ```
        cd /usr/local
        tar zxvf jdk-8u181-linux-x64.tar.gz
        ```

    2. 使环境变量生效

        ```
        source /etc/profile.d/java.sh
        java -version
        ```
        ```
        [root@izbp11ddoyj3i3tqpvtimaz ~]# java -version
        java version "1.8.0_181"
        Java(TM) SE Runtime Environment (build 1.8.0_181-b13)
        Java HotSpot(TM) 64-Bit Server VM (build 25.181-b13, mixed mode)
        [root@izbp11ddoyj3i3tqpvtimaz ~]#
        ```

##### Hadoop：安装
- Master

    1. 下载 Hadoop2.7.6 安装包，可点击[这里](http://hadoop.apache.org/releases.html)下载

    2. 解压 及 新建文件夹
        ```
        tar zxvf hadoop-2.7.6.tar.gz
        mv hadoop-2.7.6 /usr/local
        cd /usr/local/hadoop-2.7.6
        mkdir tmp dfs dfs/data dfs/name
        ```

        <div class="tip">
        目录 ` /tmp ` ，用来存储临时生成的文件
        目录 ` /dfs ` ，用来存储集群数据
        目录 ` /dfs/data` ，用来存储真正的数据
        目录 ` /dfs/name` ，用来存储文件系统元数据
        </div>

    3. 安装 rsync
        ```
        yum install -y rsync
        ```

    4. 将 **Master** 配置迁移到 **Slave**
        ```
        rsync -av /usr/local/hadoop-2.7.6 slave:/usr/local
        ```


- **Slave**
    无需其他变动

##### Hadoop：配置

- **Master**

    - core-site.xml

        ```
        vim /usr/local/hadoop-2.7.6/etc/hadoop/core-site.xml
        ```
        ```
        <configuration>
            <property>
                <name>fs.defaultFS</name>
                <value>hdfs://master:9000</value>
            </property>
            <property>
                <name>hadoop.tmp.dir</name>
                <value>file:/usr/local/hadoop-2.7.6/tmp</value>
            </property>
            <property>
                <name>io.file.buffer.size</name>
                <value>131072</value>
            </property>
        </configuration>

        ```

        > 上述 ` hadoop.tmp.dir ` 变量的路径需要改成你自己的路径。
        > 变量 `fs.defaultFS` 保存了 NameNode 的位置，HDFS 和 MapReduce 组件都需要它，这也是它出现在 `core-site.xml` 文件中而不是 `hdfs-site.xml` 文件中的原因。

    - hdfs-site.xml

        ```
        vim /usr/local/hadoop-2.7.6/etc/hadoop/hdfs-site.xml
        ```
        ```
        <configuration>
            <property>
                <name>dfs.namenode.name.dir</name>
                <value>file:/usr/local/hadoop-2.7.6/dfs/name</value>
            </property>
            <property>
                <name>dfs.datanode.data.dir</name>
                <value>file:/usr/local/hadoop-2.7.6/dfs/data</value>
            </property>
            <property>
                <name>dfs.replication</name>
                <value>1</value>
            </property>
            <property>
                <name>dfs.namenode.secondary.http-address</name>
                <value>master:9001</value>
            </property>
            <property>
                <name>dfs.webhdfs.enabled</name>
                <value>true</value>
            </property>
        </configuration>
        ```
        > 变量 `dfs.replication` 指定了每个 HDFS 数据块的复制次数，即 HDFS 存储文件的副本个数，默认为 3，如果不修改，DataNode 少于 3 台就会报错。

    - mapred-site.xml

        ```
        mv /usr/local/hadoop-2.7.6/etc/hadoop/mapred-site.xml.template /usr/local/hadoop-2.7.6/etc/hadoop/mapred-site.xml
        vim /usr/local/hadoop-2.7.6/etc/hadoop/mapred-site.xml
        ```
        ```
       <configuration>
           <property>
                <name>mapreduce.framework.name</name>
                <value>yarn</value>
            </property>
            <property>
                <name>mapreduce.jobhistory.address</name>
                <value>master:10020</value>
            </property>
            <property>
                <name>mapreduce.jobhistory.webapp.address</name>
                <value>master:19888</value>
            </property>
        </configuration>
        ```
    - yarn-site.xml

       ```
       vim /usr/local/hadoop-2.7.6/etc/hadoop/yarn-site.xml
       ```
       ```
        <configuration>

        <!-- Site specific YARN configuration properties -->
            <property>
                <name>yarn.nodemanager.aux-services</name>
                <value>mapreduce_shuffle</value>
            </property>
            <property>
                <name>yarn.nodemanager.auxservices.mapreduce.shuffle.class</name>
                <value>org.apache.hadoop.mapred.ShuffleHandler</value>
            </property>
            <property>
                <name>yarn.resourcemanager.address</name>
                <value>master:8032</value>
            </property>
            <property>
                <name>yarn.resourcemanager.scheduler.address</name>
                <value>master:8030</value>
            </property>
            <property>
                <name>yarn.resourcemanager.resource-tracker.address</name>
                <value>master:8031</value>
            </property>
            <property>
                <name>yarn.resourcemanager.admin.address</name>
                <value>master:8033</value>
            </property>
            <property>
                <name>yarn.resourcemanager.webapp.address</name>
                <value>master:8088</value>
            </property>
        </configuration>
        ```

    - hadoop-env.sh

        ```
        vim /usr/local/hadoop-2.7.6/etc/hadoop/hadoop-env.sh
        ```
        ```
        # 将
        export JAVA_HOME=${JAVA_HOME}
        # 修改为
        export JAVA_HOME=/usr/local/jdk1.8.0_181
        ```

    - yarn-env.sh

        ```
        vim /usr/local/hadoop-2.7.6/etc/hadoop/yarn-env.sh
        ```
        ```
        # 将
        export JAVA_HOME=/home/y/libexec/jdk1.6.0/
        # 修改为
        export JAVA_HOME=/usr/local/jdk1.8.0_181
        ```

    - mapred-env.sh

        ```
        vim /usr/local/hadoop-2.7.6/etc/hadoop/mapred-env.sh
        ```
        ```
        # 将
        export JAVA_HOME=/home/y/libexec/jdk1.6.0/
        # 修改为
        export JAVA_HOME=/usr/local/jdk1.8.0_181
        ```

    - slaves

        ```
        vim /usr/local/hadoop-2.7.6/etc/hadoop/slaves
        ```
        ```
        # 替换内容为你的所有 slave 节点的域名
        slave
        ```

    - 同步 Hadoop 配置文件至 slave

        ```
        rsync -av /usr/local/hadoop-2.7.6/etc/ slave:/usr/local/hadoop-2.7.6/etc/
        ```

    - Hadoop 环境变量

        ```
        vim /etc/profile.d/hadoop.sh
        ```
        ```
        # 添加
        export HADOOP_HOME=/usr/local/hadoop-2.7.6
        export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH
        ```
        ```
        # 使之生效
        source /etc/profile.d/hadoop.sh
        ```
        ```
        [root@izbp11ddoyj3i3tqpvtim9z local]# hadoop version
        Hadoop 2.7.6
        Subversion https://shv@git-wip-us.apache.org/repos/asf/hadoop.git -r 085099c66cf28be31604560c376fa282e69282b8
        Compiled by kshvachk on 2018-04-18T01:33Z
        Compiled with protoc 2.5.0
        From source with checksum 71e2695531cb3360ab74598755d036
        This command was run using /usr/local/hadoop-2.7.6/share/hadoop/common/hadoop-common-2.7.6.jar
        ```

    - scp 到 slave
        ```
        scp /etc/profile.d/hadoop.sh slave:/etc/profile.d/
        ```

- **Slave**

    - Hadoop 环境变量

        ```
        source /etc/profile.d/hadoop.sh
        ```

        ```
        [root@izbp11ddoyj3i3tqpvtimaz ~]# hadoop version
        Hadoop 2.7.6
        Subversion https://shv@git-wip-us.apache.org/repos/asf/hadoop.git -r 085099c66cf28be31604560c376fa282e69282b8
        Compiled by kshvachk on 2018-04-18T01:33Z
        Compiled with protoc 2.5.0
        From source with checksum 71e2695531cb3360ab74598755d036
        This command was run using /usr/local/hadoop-2.7.6/share/hadoop/common/hadoop-common-2.7.6.jar
        ```

##### Hadoop：运行

- **Master**

    ```
    /usr/local/hadoop-2.7.6/bin/hdfs namenode -format
    /usr/local/hadoop-2.7.6/sbin/start-all.sh
    ```
    > 在执行格式化 `-format` 命令时，要避免 NameNode 的 namespace ID 和 DataNode 的 namespace ID 不一致。这是因为每格式化一次就会产生不同的 Name，Data，Temp 等文件信息，多次格式化会产生不同的 Name，Data，Temp，容易导致 ID 不同，使 Hadoop 不能正常运行。所以**每次执行 `-format` 命令时，就需要将 DataNode 和 NameNode 上原来的 Data，Temp 文件删除**。

    > 建议只执行一次格式化。格式化 NameNode 的命令可以执行多次，但是这样会使所有的现有文件系统数据受损。只有在 Hadoop 集群关闭和你想进行格式化的情况下，才能执行格式化。但是在其他大多数情况下，格式化操作会快速，不可恢复地删除 HDFS 上的所有数据。

    ```
    [root@izbp11ddoyj3i3tqpvtim9z local]# jps
    30884 Jps
    9769 SecondaryNameNode
    9678 NameNode
    10159 ResourceManager
    ```

- **Slave**

    ```
    [root@izbp11ddoyj3i3tqpvtimaz ~]# jps
    3462 Jps
    13994 DataNode
    14556 NodeManager
    ```

##### Hadoop：检查是否成功运行

- Web UI 检查是否正常启动
    1. ` master:50070 `  NameNode 和 DataNode 节点是否成功
    2. ` master:8088 `  Yarn 服务是否正常

    ![50070](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/installation-of-distributed-hadoop-spark/50070.png)
    ![8088](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/installation-of-distributed-hadoop-spark/8088.png)

- 跑 PI 实例检查集群是否成功

    ```
    cd /usr/local/hadoop-2.7.6/
    bin/hadoop jar ./share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.6.jar pi 10 10
    ```

    ```
    [root@izbp11ddoyj3i3tqpvtim9z hadoop-2.7.6]# bin/hadoop jar ./share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.6.jar pi 10 10
    Number of Maps  = 10
    Samples per Map = 10
    Wrote input for Map #0
    Wrote input for Map #1
    Wrote input for Map #2
    Wrote input for Map #3
    Wrote input for Map #4
    Wrote input for Map #5
    Wrote input for Map #6
    Wrote input for Map #7
    Wrote input for Map #8
    Wrote input for Map #9
    Starting Job
    18/09/01 15:57:32 INFO client.RMProxy: Connecting to ResourceManager at master/192.168.1.77:8032
    18/09/01 15:57:32 INFO input.FileInputFormat: Total input paths to process : 10
    18/09/01 15:57:33 INFO mapreduce.JobSubmitter: number of splits:10
    18/09/01 15:57:33 INFO mapreduce.JobSubmitter: Submitting tokens for job: job_1534836561794_0003
    18/09/01 15:57:33 INFO impl.YarnClientImpl: Submitted application application_1534836561794_0003
    18/09/01 15:57:33 INFO mapreduce.Job: The url to track the job: http://master:8088/proxy/application_1534836561794_0003/
    18/09/01 15:57:33 INFO mapreduce.Job: Running job: job_1534836561794_0003
    18/09/01 15:57:40 INFO mapreduce.Job: Job job_1534836561794_0003 running in uber mode : false
    18/09/01 15:57:40 INFO mapreduce.Job:  map 0% reduce 0%
    18/09/01 15:58:00 INFO mapreduce.Job:  map 40% reduce 0%
    18/09/01 15:58:01 INFO mapreduce.Job:  map 60% reduce 0%
    18/09/01 15:58:13 INFO mapreduce.Job:  map 70% reduce 0%
    18/09/01 15:58:14 INFO mapreduce.Job:  map 90% reduce 0%
    18/09/01 15:58:15 INFO mapreduce.Job:  map 100% reduce 0%
    18/09/01 15:58:16 INFO mapreduce.Job:  map 100% reduce 100%
    18/09/01 15:58:17 INFO mapreduce.Job: Job job_1534836561794_0003 completed successfully
    18/09/01 15:58:17 INFO mapreduce.Job: Counters: 49
    	File System Counters
    		FILE: Number of bytes read=226
    		FILE: Number of bytes written=1354397
    		FILE: Number of read operations=0
    		FILE: Number of large read operations=0
    		FILE: Number of write operations=0
    		HDFS: Number of bytes read=2610
    		HDFS: Number of bytes written=215
    		HDFS: Number of read operations=43
    		HDFS: Number of large read operations=0
    		HDFS: Number of write operations=3
    	Job Counters
    		Launched map tasks=10
    		Launched reduce tasks=1
    		Data-local map tasks=10
    		Total time spent by all maps in occupied slots (ms)=158717
    		Total time spent by all reduces in occupied slots (ms)=13606
    		Total time spent by all map tasks (ms)=158717
    		Total time spent by all reduce tasks (ms)=13606
    		Total vcore-milliseconds taken by all map tasks=158717
    		Total vcore-milliseconds taken by all reduce tasks=13606
    		Total megabyte-milliseconds taken by all map tasks=162526208
    		Total megabyte-milliseconds taken by all reduce tasks=13932544
    	Map-Reduce Framework
    		Map input records=10
    		Map output records=20
    		Map output bytes=180
    		Map output materialized bytes=280
    		Input split bytes=1430
    		Combine input records=0
    		Combine output records=0
    		Reduce input groups=2
    		Reduce shuffle bytes=280
    		Reduce input records=20
    		Reduce output records=0
    		Spilled Records=40
    		Shuffled Maps =10
    		Failed Shuffles=0
    		Merged Map outputs=10
    		GC time elapsed (ms)=4039
    		CPU time spent (ms)=6420
    		Physical memory (bytes) snapshot=2867822592
    		Virtual memory (bytes) snapshot=23364702208
    		Total committed heap usage (bytes)=2161639424
    	Shuffle Errors
    		BAD_ID=0
    		CONNECTION=0
    		IO_ERROR=0
    		WRONG_LENGTH=0
    		WRONG_MAP=0
    		WRONG_REDUCE=0
    	File Input Format Counters
    		Bytes Read=1180
    	File Output Format Counters
    		Bytes Written=97
    Job Finished in 45.255 seconds
    Estimated value of Pi is 3.20000000000000000000
    ```

- 停止 Hadoop 集群

    ```
    /usr/local/hadoop-2.7.6/sbin/stop-all.sh
    ```

##### Spark：安装 Scala

- Master
    - Scala 2.10.6， [下载地址](http://downloads.lightbend.com/scala/2.10.6/scala-2.10.6.tgz)

    1. 下载解压
        ```
        wget http://downloads.lightbend.com/scala/2.10.6/scala-2.10.6.tgz
        tar -zxvf scala-2.10.6.tgz
        mv scala-2.10.6 /usr/local
        ```

    2. scala 环境变量

        ```
        vim /etc/profile.d/scala.sh
        ```
        ```
        export SCALA_HOME=/usr/local/scala-2.10.6
        export PATH=$PATH:$SCALA_HOME/bin
        ```
        ```
        source /etc/profile.d/scala.sh
        ```
        ```
        [root@izbp11ddoyj3i3tqpvtim9z ~]# scala -version
        Scala code runner version 2.10.6 -- Copyright 2002-2013, LAMP/EPFL
        ```

    3. 同步到 Slave

        ```
        rsync -av /usr/local/scala-2.10.6/ slave:/usr/local/
        scp /etc/profile.d/scala.sh slave:/etc/profile.d/
        ```

- **Slave**
    ```
    source /etc/profile.d/scala.sh
    ```
    ```
    [root@izbp11ddoyj3i3tqpvtimaz ~]# scala -version
    Scala code runner version 2.10.6 -- Copyright 2002-2013, LAMP/EPFL
    ```


##### Spark：安装

- **Master**

    - Spark 1.5.2， [下载地址](http://archive.apache.org/dist/spark/spark-1.5.2/spark-1.5.2-bin-hadoop2.6.tgz)

    1. 下载解压

        ```
        wget http://archive.apache.org/dist/spark/spark-1.5.2/spark-1.5.2-bin-hadoop2.6.tgz
        tar -zxvf spark-1.5.2-bin-hadoop2.6.tgz
        mv spark-1.5.2-bin-hadoop2.6 /usr/local/
        ```
    2. Spark 环境变量

        ```
        vim /etc/profile.d/spark.sh
        ```
        ```
        export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
        export HDFS_CONF_DIR=$HADOOP_HOME/etc/hadoop
        export YARN_CONF_DIR==$HADOOP_HOME/etc/hadoop
        export SPARK_HOME=/usr/local/spark-1.5.2-bin-hadoop2.6
        export PATH=$PATH:$SPARK_HOME/bin
        ```
        ```
        source /etc/profile.d/spark.sh
        ```

    3. 同步到 Slave

        ```
        rsync -av /usr/local/spark-1.5.2-bin-hadoop2.6/ slave:/usr/local/
        scp /etc/profile.d/spark.sh slave:/etc/profile.d/
        ```
- **Slave**
    ```
    source /etc/profile.d/spark.sh
    ```

##### Spark：配置

- **Master**
    - conf/slaves

        ```
        cp /usr/local/spark-1.5.2-bin-hadoop2.6/conf/slaves.template /usr/local/spark-1.5.2-bin-hadoop2.6/conf/slaves
        vim /usr/local/spark-1.5.2-bin-hadoop2.6/conf/slaves
        ```

        ```
        # A Spark Worker will be started on each of the machines listed below.
        # localhost
        master
        slave
        ```
    - conf/spark-env.sh

        ```
        vim /usr/local/spark-1.5.2-bin-hadoop2.6/conf/spark-env.sh
        ```
        ```
        export JAVA_HOME=/usr/local/jdk1.8.0_181
        export SCALA_HOME=/usr/local/scala-2.10.6
        export HADOOP_HOME=/usr/local/hadoop-2.7.6
        export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
        # If not SPARK_PID_DIR, YARN_PID_DIR, HADOOP_PID_DIR , It will cause exception about "no org.apache.spark.deploy.master.Master to stop"
        export SPARK_PID_DIR=/usr/local/spark-1.5.2-bin-hadoop2.6/app/pids
        export YARN_PID_DIR=/usr/local/spark-1.5.2-bin-hadoop2.6/app/pids
        export HADOOP_PID_DIR==/usr/local/spark-1.5.2-bin-hadoop2.6/app/pids
        export SPARK_MASTER_IP=192.168.1.77
        export SPARK_MASTER_HOST=192.168.1.77
        export SPARK_MASTER_PORT=7077
        export SPARK_LOCAL_IP=192.168.1.77
        export SPARK_WORKER_CORE=2
        export SPARK_WORKER_MEMORY=6g

        export PYSPARK_PYTHON=/usr/bin/python
        ```

##### Spark：运行
- **Master**

    - 启动集群

        ```
        cd /usr/local/spark-1.5.2-bin-hadoop2.6/sbin
        ```
        ```
        ./start-all.sh
        ```
        ```
    [root@izbp11ddoyj3i3tqpvtim9z sbin]# ./start-all.sh
    starting org.apache.spark.deploy.master.Master, logging to /usr/local/spark-1.5.2-bin-hadoop2.6/sbin/../logs/spark-root-org.apache.spark.deploy.master.Master-1-izbp11ddoyj3i3tqpvtim9z.out
    slave: starting org.apache.spark.deploy.worker.Worker, logging to /usr/local/spark-1.5.2-bin-hadoop2.6/sbin/../logs/spark-root-org.apache.spark.deploy.worker.Worker-1-izbp11ddoyj3i3tqpvtimaz.out
    master: starting org.apache.spark.deploy.worker.Worker, logging to /usr/local/spark-1.5.2-bin-hadoop2.6/sbin/../logs/spark-root-org.apache.spark.deploy.worker.Worker-1-izbp11ddoyj3i3tqpvtim9z.out
        ```

    - 停止集群
        ```
[root@izbp11ddoyj3i3tqpvtim9z sbin]# ./stop-all.sh
slave: stopping org.apache.spark.deploy.worker.Worker
master: stopping org.apache.spark.deploy.worker.Worker
stopping org.apache.spark.deploy.master.Master
        ```

##### Spark：检查是否成功运行
- Spark Console 界面

![Spark Console](
https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/installation-of-distributed-hadoop-spark/spark%20console.png)

能看到两个 Worker State 为 ALIVE 时，说明你的分布式集群已经搭建成功了，接下来 submit demo 来测试一下。

- Submit examples

    ```
[root@izbp11ddoyj3i3tqpvtim9z spark-1.5.2-bin-hadoop2.6]# ./bin/spark-submit --class org.apache.spark.examples.SparkPi --master yarn-cluster lib/spark-examples*.jar 10
18/09/04 20:19:13 WARN util.NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
18/09/04 20:19:13 INFO client.RMProxy: Connecting to ResourceManager at master/192.168.1.77:8032
18/09/04 20:19:13 INFO yarn.Client: Requesting a new application from cluster with 1 NodeManagers
18/09/04 20:19:13 INFO yarn.Client: Verifying our application has not requested more than the maximum memory capability of the cluster (8192 MB per container)
18/09/04 20:19:13 INFO yarn.Client: Will allocate AM container, with 1408 MB memory including 384 MB overhead
18/09/04 20:19:13 INFO yarn.Client: Setting up container launch context for our AM
18/09/04 20:19:13 INFO yarn.Client: Setting up the launch environment for our AM container
18/09/04 20:19:13 INFO yarn.Client: Preparing resources for our AM container
18/09/04 20:19:14 INFO yarn.Client: Uploading resource file:/usr/local/spark-1.5.2-bin-hadoop2.6/lib/spark-assembly-1.5.2-hadoop2.6.0.jar -> hdfs://master:9000/user/root/.sparkStaging/application_1534836561794_0004/spark-assembly-1.5.2-hadoop2.6.0.jar
18/09/04 20:19:15 INFO yarn.Client: Uploading resource file:/usr/local/spark-1.5.2-bin-hadoop2.6/lib/spark-examples-1.5.2-hadoop2.6.0.jar -> hdfs://master:9000/user/root/.sparkStaging/application_1534836561794_0004/spark-examples-1.5.2-hadoop2.6.0.jar
18/09/04 20:19:15 INFO yarn.Client: Uploading resource file:/tmp/spark-368edc00-f27b-42b0-87fa-0fba1b79f8b1/__spark_conf__2041701267374277539.zip -> hdfs://master:9000/user/root/.sparkStaging/application_1534836561794_0004/__spark_conf__2041701267374277539.zip
18/09/04 20:19:16 INFO spark.SecurityManager: Changing view acls to: root
18/09/04 20:19:16 INFO spark.SecurityManager: Changing modify acls to: root
18/09/04 20:19:16 INFO spark.SecurityManager: SecurityManager: authentication disabled; ui acls disabled; users with view permissions: Set(root); users with modify permissions: Set(root)
18/09/04 20:19:16 INFO yarn.Client: Submitting application 4 to ResourceManager
18/09/04 20:19:16 INFO impl.YarnClientImpl: Submitted application application_1534836561794_0004
18/09/04 20:19:17 INFO yarn.Client: Application report for application_1534836561794_0004 (state: ACCEPTED)
18/09/04 20:19:17 INFO yarn.Client:
	 client token: N/A
	 diagnostics: N/A
	 ApplicationMaster host: N/A
	 ApplicationMaster RPC port: -1
	 queue: default
	 start time: 1536063556641
	 final status: UNDEFINED
	 tracking URL: http://master:8088/proxy/application_1534836561794_0004/
	 user: root
18/09/04 20:19:18 INFO yarn.Client: Application report for application_1534836561794_0004 (state: ACCEPTED)
18/09/04 20:19:19 INFO yarn.Client: Application report for application_1534836561794_0004 (state: ACCEPTED)
18/09/04 20:19:20 INFO yarn.Client: Application report for application_1534836561794_0004 (state: ACCEPTED)
18/09/04 20:19:21 INFO yarn.Client: Application report for application_1534836561794_0004 (state: ACCEPTED)
18/09/04 20:19:22 INFO yarn.Client: Application report for application_1534836561794_0004 (state: RUNNING)
18/09/04 20:19:22 INFO yarn.Client:
	 client token: N/A
	 diagnostics: N/A
	 ApplicationMaster host: 192.168.1.78
	 ApplicationMaster RPC port: 0
	 queue: default
	 start time: 1536063556641
	 final status: UNDEFINED
	 tracking URL: http://master:8088/proxy/application_1534836561794_0004/
	 user: root
18/09/04 20:19:23 INFO yarn.Client: Application report for application_1534836561794_0004 (state: RUNNING)
18/09/04 20:19:24 INFO yarn.Client: Application report for application_1534836561794_0004 (state: RUNNING)
18/09/04 20:19:25 INFO yarn.Client: Application report for application_1534836561794_0004 (state: RUNNING)
18/09/04 20:19:26 INFO yarn.Client: Application report for application_1534836561794_0004 (state: RUNNING)
18/09/04 20:19:27 INFO yarn.Client: Application report for application_1534836561794_0004 (state: RUNNING)
18/09/04 20:19:28 INFO yarn.Client: Application report for application_1534836561794_0004 (state: RUNNING)
18/09/04 20:19:29 INFO yarn.Client: Application report for application_1534836561794_0004 (state: RUNNING)
18/09/04 20:19:30 INFO yarn.Client: Application report for application_1534836561794_0004 (state: RUNNING)
18/09/04 20:19:31 INFO yarn.Client: Application report for application_1534836561794_0004 (state: RUNNING)
18/09/04 20:19:32 INFO yarn.Client: Application report for application_1534836561794_0004 (state: RUNNING)
18/09/04 20:19:33 INFO yarn.Client: Application report for application_1534836561794_0004 (state: RUNNING)
18/09/04 20:19:34 INFO yarn.Client: Application report for application_1534836561794_0004 (state: FINISHED)
18/09/04 20:19:34 INFO yarn.Client:
	 client token: N/A
	 diagnostics: N/A
	 ApplicationMaster host: 192.168.1.78
	 ApplicationMaster RPC port: 0
	 queue: default
	 start time: 1536063556641
	 final status: SUCCEEDED
	 tracking URL: http://master:8088/proxy/application_1534836561794_0004/
	 user: root
18/09/04 20:19:34 INFO util.ShutdownHookManager: Shutdown hook called
18/09/04 20:19:34 INFO util.ShutdownHookManager: Deleting directory /tmp/spark-368edc00-f27b-42b0-87fa-0fba1b79f8b1
    ```

##### Spark：安装问题汇总

1. **pyspark 配置问题**

    Spark PYSPARK_PYTHON=/path/to/python2.7 (可在环境变量中设置，也可在spark-env.sh中设置）
2. **Exception: Randomness of hash of string should be disabled via PYTHONHASHSEED**

    需要配置 SPARKHOME ./conf文件夹下的 spark-defaults.conf，将spark.executorEnv.PYTHONHASHSEED 0 #具体值可以自己设置加入到上面的配置文件中
3. **java.lang.NoClassDefFoundError: org/apache/spark/Logging**

    Spark 版本过高 2.5 降到 1.5 ，从 Spark 1.5 版本之后都会出现此错误
org.apache.spark.Logging is available in Spark version 1.5.2 or lower version.
4. **spark1.5 root@localhost's password:localhost:permission denied,please try again**

    > 引用 https://www.cnblogs.com/hmy-blog/p/6500909.html

    编辑配置文件，允许以 root 用户通过 ssh 登录：sudo vi /etc/ssh/sshd_config
    找到：PermitRootLogin prohibit-password禁用
    添加：PermitRootLogin yes

5. **Error: Cannot find configuration directory: /etc/hadoop**

    > 引用：https://blog.csdn.net/haozhao_blog/article/details/50767009

6. **Spark 无法获得 Slave 节点的 Worker 信息**
    spark-env.sh 中关于 Master Worker 的值一律写 IP 地址，而不是域名
    比如 SPARK_MASTER_IP 和 SPARK_MASTER_HOST 都要写成 IP 地址

7. **集群启动一段时间后，无法停止**
    原因参见 [Spark集群无法停止的原因分析和解决](https://www.linuxidc.com/Linux/2015-08/120938.htm)

    如果已发生：每个节点 `ps -aux | grep spark` 之后，手动 kill 进程

    在 spark-env.sh 中，添加如下配置：
    ```
    export SPARK_PID_DIR=/usr/local/spark-1.5.2-bin-hadoop2.6/app/pids
    export YARN_PID_DIR=/usr/local/spark-1.5.2-bin-hadoop2.6/app/pids
    export HADOOP_PID_DIR==/usr/local/spark-1.5.2-bin-hadoop2.6/app/pids
    ```