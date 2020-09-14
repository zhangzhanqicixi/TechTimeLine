---
title: macOS 安装启动生产消费 Apache Kafka
date: 2020-09-14 15:23:20
tags:
---

开发测试过程中在本机安装了 Kafka Server，记录一下启动步骤和生产消费的代码。

##### 安装配置

- Mac OS 环境并安装 Homebrew
- 安装 Zookeeper 和 Kafka
```
brew install zookeeper
brew install kafka
```

> brew 指定 install 版本，请参考：[Homebrew 指定版本安装](https://blog.timeline229.com/homebrew-set-software-elder-version/)

<!--more-->

- 修改 Kafka 配置文件
```
vim /usr/local/etc/kafka/server.properties
```
找到 `#listeners=PLAINTEXT://:9092`
打开注释并修改为 `listeners=PLAINTEXT://localhost:9092`

##### 启动 Zookeeper
```
/usr/local/etc/kafka/zookeeper.properties
```

##### 启动 Kafka Server
```
kafka-server-start /usr/local/etc/kafka/server.properties
```

> 1. 这里 Zookeeper 和 Kafka 都是前台临时启动
> 2. 停止服务也请以先 Kafka Server 后 Zookeeper 的顺序关闭

##### 创建 Kafka Topic
```
kafka-topics --create --zookeeper localhost:2181 --replication-factor 1 --partitions 1 --topic topic_test_r1p1
```

> Kafka Topic 命名规则参考：[Kafka Topic 命名技巧](https://developer.aliyun.com/article/365588)

##### 启动指定 Topic Producer 
```
kafka-console-producer --broker-list localhost:9092 --topic topic_test_r1p1
```

##### Consumer 端测试
 
```
➜  ~ kafka-console-producer --broker-list localhost:9092 --topic topic_test_r1p1
>test123 
>测试数据
```

- Kafka Tools
下载 kafka tools 客户端工具可查看生产的数据。

![kafka-tools](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/macos-kafka-tutorial/Screen%20Shot%202020-09-14%20at%203.15.33%20PM.png)

- Flink 消费 Kafka

pom.xml 依赖
```
<properties>
    <flink.version>1.9.0</flink.version>
    <scala.binary.version>2.11</scala.binary.version>
    <scala.version>2.11.4</scala.version>
</properties>


<dependencies>

    <dependency>
        <groupId>org.scala-lang</groupId>
        <artifactId>scala-library</artifactId>
        <version>${scala.version}</version>
    </dependency>

    <dependency>
        <groupId>org.apache.flink</groupId>
        <artifactId>flink-streaming-java_${scala.binary.version}</artifactId>
        <version>${flink.version}</version>
    </dependency>

    <dependency>
        <groupId>org.apache.flink</groupId>
        <artifactId>flink-streaming-scala_${scala.binary.version}</artifactId>
        <version>${flink.version}</version>
    </dependency>

    <dependency>
        <groupId>org.apache.flink</groupId>
        <artifactId>flink-clients_${scala.binary.version}</artifactId>
        <version>${flink.version}</version>
    </dependency>

    <dependency>
        <groupId>org.apache.flink</groupId>
        <artifactId>flink-connector-kafka-0.10_${scala.binary.version}</artifactId>
        <version>${flink.version}</version>
    </dependency>

    <dependency>
        <groupId>com.alibaba</groupId>
        <artifactId>fastjson</artifactId>
        <version>1.2.70</version>
    </dependency>

</dependencies>
```

Flink 代码
```
package test.demo

import java.util.Properties

import org.apache.flink.api.common.serialization.SimpleStringSchema
import org.apache.flink.streaming.api.scala.{StreamExecutionEnvironment, _}
import org.apache.flink.streaming.connectors.kafka.FlinkKafkaConsumer010

object Kafka2FlinkDemo {

  def main(args: Array[String]): Unit = {
    val env = StreamExecutionEnvironment.getExecutionEnvironment

    val properties = new Properties()
    properties.setProperty("bootstrap.servers", "localhost:9092")
    properties.setProperty("group.id", "1")
    properties.setProperty("enable.auto.commit", "true")
    properties.setProperty("auto.commit.interval.ms", "6000")

    val topics = "topic_test_r1p1"

    val kafkaConsumer = new FlinkKafkaConsumer010(
      topics, new SimpleStringSchema(), properties
    ).setStartFromLatest()

    env
      .addSource(kafkaConsumer)
      .map(r => {
        try {
          println(r)
        } catch {
          case e1: Exception => println(e1.getMessage)
        }
      })

    env.execute("kafkaConsumer Print")

  }
}

```

在控制台看到消费内容，即表示已成功消费。