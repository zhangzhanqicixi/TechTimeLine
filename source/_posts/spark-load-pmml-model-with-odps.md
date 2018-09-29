---
title: Spark 加载 Max Compute(ODPS) 数据并 load PMML 模型
date: 2018-09-29 21:14:28
tags: 
---

最近公司打算慢慢把机器学习的东西从阿里云 PAI 迁移到 Spark 上来做，第一步先实现 PMML 模型在 Spark 上跑起来，并用 Max Compute 作为数据的输入和输出。

> 注意，Spark 1.* 和 Spark 2.* 依赖的项目很不一样.

Spark 搭建可以看我上一篇博客，[传送门](https://blog.timeline229.com/installation-of-distributed-hadoop-spark/)。

过程挺简单，都有现成的 API 和项目 Demo，先给参考的相关地址：
- [e-map-reduce demo for spark 1.5](https://github.com/aliyun/aliyun-emapreduce-demo/tree/master) (如果你的 spark 是 2.x 的，则将 branch 选择成 master-2* 的，Spark 1.* 和 2.* 是不能通用的)
- [Spark 1.5 或 Spark 1.6 加载 PMML 模型](https://github.com/ma3axaka/jpmml-spark)
- [阿里云 org.apache.spark.aliyun 官方文档](https://static.javadoc.io/com.aliyun.emr/emr-sdk_2.11/1.3.2/index.html#org.apache.spark.aliyun.odps.OdpsOps)

<!--more-->

##### 项目依赖的 pom.xml 文件

```
<?xml version="1.0" ?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
	<modelVersion>4.0.0</modelVersion>

	<parent>
		<groupId>org.jpmml</groupId>
		<artifactId>jpmml-spark</artifactId>
		<version>1.0-SNAPSHOT</version>
	</parent>

	<groupId>org.jpmml</groupId>
	<artifactId>pmml-spark-example</artifactId>

	<properties>
		<spark.version>1.6.3</spark.version>
		<emr.version>1.4.1</emr.version>
		<odps.version>0.24.0-public</odps.version>
	</properties>

	<dependencies>
		<dependency>
			<groupId>org.jpmml</groupId>
			<artifactId>pmml-spark</artifactId>
		</dependency>

		<dependency>
			<groupId>com.databricks</groupId>
			<artifactId>spark-csv_2.10</artifactId>
			<version>1.3.0</version>
			<exclusions>
				<exclusion>
					<groupId>org.scala-lang</groupId>
					<artifactId>scala-library</artifactId>
				</exclusion>
			</exclusions>
		</dependency>

		<dependency>
			<groupId>org.apache.spark</groupId>
			<artifactId>spark-core_2.10</artifactId>
		</dependency>
		<dependency>
			<groupId>org.apache.spark</groupId>
			<artifactId>spark-mllib_2.10</artifactId>
		</dependency>
		<dependency>
			<groupId>org.apache.spark</groupId>
			<artifactId>spark-sql_2.10</artifactId>
		</dependency>


		<!-- 支持 MNS、ONS、LogService、MaxCompute数据源 (Spark 1.x环境)-->

		<dependency>
			<groupId>com.aliyun.emr</groupId>
			<artifactId>emr-maxcompute_2.10</artifactId>
			<version>${emr.version}</version>
		</dependency>
		<dependency>
			<groupId>com.aliyun.odps</groupId>
			<artifactId>odps-sdk-core</artifactId>
			<version>${odps.version}</version>
			<exclusions>
				<exclusion>
					<groupId>org.codehaus.jackson</groupId>
					<artifactId>jackson-mapper-asl</artifactId>
				</exclusion>
				<exclusion>
					<groupId>org.codehaus.jackson</groupId>
					<artifactId>jackson-core-asl</artifactId>
				</exclusion>
			</exclusions>
		</dependency>

		<dependency>
			<groupId>com.aliyun.odps</groupId>
			<artifactId>odps-sdk-commons</artifactId>
			<version>${odps.version}</version>
		</dependency>
	</dependencies>

	<build>
		<plugins>
			<plugin>
				<artifactId>maven-assembly-plugin</artifactId>
				<configuration>
					<descriptorRefs>
						<descriptorRef>jar-with-dependencies</descriptorRef>
					</descriptorRefs>
				</configuration>
			</plugin>


			<plugin>
				<groupId>org.apache.maven.plugins</groupId>
				<artifactId>maven-deploy-plugin</artifactId>
				<version>2.8.2</version>
				<configuration>
					<skip>true</skip>
				</configuration>
			</plugin>
			<plugin>
				<groupId>org.apache.maven.plugins</groupId>
				<artifactId>maven-shade-plugin</artifactId>
				<version>2.4.2</version>
				<executions>
					<execution>
						<phase>package</phase>
						<goals>
							<goal>shade</goal>
						</goals>
						<configuration>
							<createDependencyReducedPom>false</createDependencyReducedPom>
							<finalName>example-${project.version}</finalName>
							<relocations>
								<relocation>
									<pattern>com.google.common</pattern>
									<shadedPattern>com.shaded.google.common</shadedPattern>
								</relocation>
								<relocation>
									<pattern>org.dmg.pmml</pattern>
									<shadedPattern>org.shaded.dmg.pmml</shadedPattern>
								</relocation>
								<relocation>
									<pattern>org.jpmml.agent</pattern>
									<shadedPattern>org.shaded.jpmml.agent</shadedPattern>
								</relocation>
								<relocation>
									<pattern>org.jpmml.model</pattern>
									<shadedPattern>org.shaded.jpmml.model</shadedPattern>
								</relocation>
								<relocation>
									<pattern>org.jpmml.schema</pattern>
									<shadedPattern>org.shaded.jpmml.schema</shadedPattern>
								</relocation>
							</relocations>
						</configuration>
					</execution>
				</executions>
			</plugin>
		</plugins>
	</build>
</project>
```


其中上面的 「parent」节点为 [Spark 1.5 或 Spark 1.6 加载 PMML 模型](https://github.com/ma3axaka/jpmml-spark) 依赖的 JPMML 项目
```
<parent>
	<groupId>org.jpmml</groupId>
	<artifactId>jpmml-spark</artifactId>
	<version>1.0-SNAPSHOT</version>
</parent>
```

##### 核心代码
```
package org.jpmml.spark;

import com.aliyun.odps.TableSchema;
import com.aliyun.odps.data.Record;
import org.apache.spark.SparkConf;
import org.apache.spark.aliyun.odps.OdpsOps;
import org.apache.spark.api.java.JavaRDD;
import org.apache.spark.api.java.JavaSparkContext;
import org.apache.spark.api.java.function.Function3;
import org.apache.spark.ml.Transformer;
import org.apache.spark.sql.*;
import org.jpmml.evaluator.Evaluator;
import scala.runtime.BoxedUnit;

/**
 * Created by IntelliJ IDEA
 *
 * @author ZHANGZHANQI
 * @Date 2018/9/13
 * @Time 16:11
 * @Description GBDT + LR 预测
 */

public class PredictEvaluation {

    public static void main(String... args) throws Exception {

        String odpsUrl = "http://odps-ext.aliyun-inc.com/api";
        String tunnelUrl = "http://dt-ext.odps.aliyun-inc.com";

        String pmmlPath = args[0]; // pmml 模型在 hdfs 中的地址
        String accessId = args[1]; // aliyun access id
        String accessKey = args[2]; // aliyun access key
        String project = args[3]; // max compute project name
        String readTable = args[4]; // max compute table name which you want to read
        String saveTable = args[5]; // mac compute table name which you want to write
        int numPartition = Integer.valueOf(args[6]); // 下载 readTable 表时每个节点的并发数

        Evaluator evaluator = EvaluatorUtil.createEvaluatorWithHDFS(pmmlPath);
        TransformerBuilder modelBuilder = new TransformerBuilder(evaluator)
                .withTargetCols()
                .withOutputCols()
                .exploded(true);

        Transformer transformer = modelBuilder.build();

        SparkConf conf = new SparkConf();

        try (JavaSparkContext sparkContext = new JavaSparkContext(conf)) {
            OdpsOps odpsOps = new OdpsOps(sparkContext.sc(), accessId, accessKey, odpsUrl, tunnelUrl);
            System.out.println("Read odps table...");
            SQLContext sqlContext = new SQLContext(sparkContext);

            // 新建一个数组，长度为 readTable 的字段数量
            int[] columnIndex = new int[419];
            for (int i = 0; i < 419; i++) {
                columnIndex[i] = i;
            }

            DataFrame dataframe = odpsOps.loadOdpsTable(sqlContext, project, readTable, columnIndex, numPartition);
            dataframe = transformer.transform(dataframe);

            // select 需要的字段
            DataFrame dataFrame1 = dataframe.select("uid", "itemid", "isbuy", "p_0", "p_1");
            JavaRDD<Row> data = dataFrame1.javaRDD();
            odpsOps.saveToTableWithJava(project, saveTable, data, new SaveRecord());

        }
    }

    static class SaveRecord implements Function3<Row, Record, TableSchema, BoxedUnit> {
        @Override
        public BoxedUnit call(Row data, Record record, TableSchema schema) throws Exception {
            for (int i = 0; i < schema.getColumns().size(); i++) {
                record.setString(i, data.get(i).toString());
            }
            return null;
        }
    }
}

```


##### 启动命令

```
spark-submit --master spark://master:7077 --class org.jpmml.spark.PredictEvaluation example-1.0-SNAPSHOT.jar hdfs://master:9000/pmml/xlab_m_GBDT_LR_1_1531625_v0.pmml accessId accessKey projectName readTableName saveTableName 50
```

##### 后续问题
整个流程是跑通了，但是运行时间是个大问题，现在公司给了两台 2U8G 的机器，predict 模型的时候，在 user item 特征量为 20 万时，整个跑完需要 12 分钟，但是我们现在的特征量大概是 8 亿条。显然这样是根本跑不动的，后续可能要考虑下怎么样加机器，每个机器多少并发较为合理。