---
title: 基于 Spark ML + Jieba + Jaccard 计算文本相似度
date: 2020-09-14 16:01:39
tags:
---

##### 背景需求

最近在做短视频的相似视频推荐，初期不涉及语义分析及图像检测，所有单纯使用视频标题作为文本，来度量视频库中的相似视频，baseline 选择了使用 Jarccard 相似系数，简单而且效果明显。

整体步骤可以参考下图：

![process](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/sparkml-jieba-jaccard-similarity/process.png)

> 用 Spark 做特征工程时，推荐可以先看下下面的文档
[Extracting, transforming and selecting features - Spark 2.3.1 Documentation](https://spark.apache.org/docs/2.3.1/ml-features.html)

<!--more-->

##### Jaccard 系数

先介绍下 Jarccard 系数，Jarccard 相似系数（Jaccard similarity coefficient ）表示两个集合 A 和 B 的交集元素在 A 和 B 的并集中所占的比例，用符号 J(A, B) 表示：

$$J(A, B) = \frac{ \mid A \bigcap B \mid} {\mid A \bigcup B \mid} $$

Jarccard 相似系数是衡量两个集合的相似度的一种指标

##### Jieba 分词

Spark 中可以使用 Tokenizer 或 RegexTokenizer 来进行分词，两者的区别在于 Tokenizer 默认通过 空格 进行分词；而 RegexTokenizer 则可以通过正则表达式进行自定义匹配。
英文分词相对简单，默认词与词之间就有空格。中文的话，我们可以用 jieba 或相关的开源库进行分词。

```
<dependency>
    <groupId>com.huaban</groupId>
    <artifactId>jieba-analysis</artifactId>
    <version>1.0.2</version>
</dependency>
```

```
import com.huaban.analysis.jieba.{JiebaSegmenter, SegToken}
import com.huaban.analysis.jieba.JiebaSegmenter.SegMode
import org.apache.spark.SparkConf
import org.apache.spark.ml.feature.RegexTokenizer
import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions.udf

val jiebaSegmenter = new JiebaSegmenter()
val jiebaSegmenterCast = spark.sparkContext.broadcast(jiebaSegmenter)

val segment = udf { sentence: String =>
	val localJieba = jiebaSegmenterCast.value
	localJieba.process(sentence.toString, SegMode.INDEX)
    .toArray().map(_.asInstanceOf[SegToken].word)
    .filter(_.length > 1)
    .mkString(",")
}

val sentenceDataFrame = spark.createDataFrame(Seq(
  (0, "泰国5岁小学生每天开摩托艇上学，最高时速可达64公里")
  (1, "泰国200列火车一夜之间齐聚中国，带来满车“珍宝”"),
  (2, "注意现在是这种变质水果的中毒高峰期，危及生命")
)).toDF("id", "sentence")
.withColumn("segment", segment($"sentence"))

val regTokenizer = new RegexTokenizer()
  .setInputCol("segment")
  .setOutputCol("words")
  .setPattern(",")

	val regTokenized = regTokenizer.transform(sentenceDataFrame)
  regTokenized.show(false)
  }
```

```
+---+--------------------------+-------------------------------------+--------------------------------------------------+
|id |sentence                  |segment                              |words                                             |
+---+--------------------------+-------------------------------------+--------------------------------------------------+
|0  |泰国5岁小学生每天开摩托艇上学，最高时速可达64公里|泰国,小学,学生,小学生,摩托,摩托艇,上学,最高,时速,可达,64,公里|[泰国, 小学, 学生, 小学生, 摩托, 摩托艇, 上学, 最高, 时速, 可达, 64, 公里]|
|1  |泰国200列火车一夜之间齐聚中国，带来满车“珍宝” |泰国,200,火车,一夜,之间,一夜之间,齐聚,中国,带来,满车,珍宝  |[泰国, 200, 火车, 一夜, 之间, 一夜之间, 齐聚, 中国, 带来, 满车, 珍宝]   |
|2  |注意现在是这种变质水果的中毒高峰期，危及生命    |注意,现在,这种,变质,水果,中毒,高峰,高峰期,危及,生命       |[注意, 现在, 这种, 变质, 水果, 中毒, 高峰, 高峰期, 危及, 生命]         |
+---+--------------------------+-------------------------------------+--------------------------------------------------+
```

##### 停用词维护

Spark 中自带停用词的词袋 *StopWordsRemover*，但是该模块仅支持英语，发育，德语，意大利语等西方语言，并没有对中文进行维护。所以我们需要自己维护一系列的停用词，用来去除 “的”，“哦”，“好” 等相关常用词，以及去除“！”，“#”等标点符号，减少这些词对最终结果的影响。比如上面的例子，可以维护一个 cn_stoplist，来把一些常用词给过滤掉，那么我们可以改造下上面 segment 这个 UDF。

```
// 去除下面三个词
cn_stopwords = Seq ("注意", "一夜", "公里")

val segment = udf { sentence: String =>
  val localJieba = jiebaSegmenterCast.value
  localJieba.process(sentence.toString, SegMode.INDEX)
    .toArray().map(_.asInstanceOf[SegToken].word)
    .filter(_.length > 1).filter(!cn_stopwords.contains(_))
    .mkString(",")
}
```

那么分词结果就会变成：

```
+---+--------------------------+----------------------------------+----------------------------------------------+
|id |sentence                  |segment                           |words                                         |
+---+--------------------------+----------------------------------+----------------------------------------------+
|0  |泰国5岁小学生每天开摩托艇上学，最高时速可达64公里|泰国,小学,学生,小学生,摩托,摩托艇,上学,最高,时速,可达,64|[泰国, 小学, 学生, 小学生, 摩托, 摩托艇, 上学, 最高, 时速, 可达, 64]|
|1  |泰国200列火车一夜之间齐聚中国，带来满车“珍宝” |泰国,200,火车,之间,一夜之间,齐聚,中国,带来,满车,珍宝  |[泰国, 200, 火车, 之间, 一夜之间, 齐聚, 中国, 带来, 满车, 珍宝]   |
|2  |注意现在是这种变质水果的中毒高峰期，危及生命    |现在,这种,变质,水果,中毒,高峰,高峰期,危及,生命       |[现在, 这种, 变质, 水果, 中毒, 高峰, 高峰期, 危及, 生命]         |
+---+--------------------------+----------------------------------+----------------------------------------------+
```

##### 词频与特征转换

去掉了停用词以及分词之后，我们就可以对这些词进行向量化的操作，Spark 中我们选择 *CountVectorizer*，来对分词后的数据进行向量化并做词频的统计。

```
val cvModel = new CountVectorizer()
  .setInputCol("words")
  .setOutputCol("features")
  .setVocabSize(1000)
  .fit(regTokenized)

cvModel.transform(regTokenized).show(false)
```

拟合后，我们就可以得到如下的结果：

```
+---+--------------------------+----------------------------------+----------------------------------------------+--------------------------------------------------------------------------------+
|id |sentence                  |segment                           |words                                         |features                                                                        |
+---+--------------------------+----------------------------------+----------------------------------------------+--------------------------------------------------------------------------------+
|0  |泰国5岁小学生每天开摩托艇上学，最高时速可达64公里|泰国,小学,学生,小学生,摩托,摩托艇,上学,最高,时速,可达,64|[泰国, 小学, 学生, 小学生, 摩托, 摩托艇, 上学, 最高, 时速, 可达, 64]|(29,[0,1,4,6,9,10,13,16,20,21,22],[1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0])|
|1  |泰国200列火车一夜之间齐聚中国，带来满车“珍宝” |泰国,200,火车,之间,一夜之间,齐聚,中国,带来,满车,珍宝  |[泰国, 200, 火车, 之间, 一夜之间, 齐聚, 中国, 带来, 满车, 珍宝]   |(29,[0,2,3,5,12,15,17,18,25,26],[1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0])      |
|2  |注意现在是这种变质水果的中毒高峰期，危及生命    |现在,这种,变质,水果,中毒,高峰,高峰期,危及,生命       |[现在, 这种, 变质, 水果, 中毒, 高峰, 高峰期, 危及, 生命]         |(29,[7,8,11,14,19,23,24,27,28],[1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0])           |
+---+--------------------------+----------------------------------+----------------------------------------------+--------------------------------------------------------------------------------+
```

##### 计算 Jaccard 系数

Spark 中没有直接计算 Jaccard 的模块，但是别急，我们可以用 MinHashLSH 来近似 Jaccard 系数，查了官方文档，MinHashLSH 是 Jaccard 距离的 LSH 系列，基本思想是：如果两个文本在原有的数据空间是相似的，那么分别经过哈希函数转换以后的它们也具有很高的相似度；相反，如果它们本身是不相似的，那么经过转换后它们应仍不具有相似性。

LSH 算法详情可以参照：[LSH算法 - 知乎](https://zhuanlan.zhihu.com/p/108181478) 这篇文章的解释。

```
val mhModel = new MinHashLSH().setNumHashTables(100).setInputCol("features").setOutputCol("hashValues").fit(vectorizedDF)

val featureDF1 = mhModel.transform(countVectored).cache()
val featureDF2 = mhModel.transform(countVectored).cache()

val simiDistance = mhModel.approxSimilarityJoin(featureDF1, featureDF2, 0.8)
  .filter("distCol != 0")
  .select(col("datasetA.id").alias("acid1"),
    col("datasetA.sentence").alias("title1"),
    col("datasetB.id").alias("acid2"),
    col("datasetB.sentence").alias("title2"),
    col("distCol")
  )

simiDistance.show(false)
```

*approxSimilarityJoin* 方法让两个数据集进行笛卡尔积，使之进行两两比较，后面的 0.8 这个数表示对计算结果的阈值设定，数值越小，过滤出来的数据越“相似”，相对的数量也越少。

```
+-----+--------------------------+-----+--------------------------+-------+
|acid1|title1                    |acid2|title2                    |distCol|
+-----+--------------------------+-----+--------------------------+-------+
|1    |泰国200列火车一夜之间齐聚中国，带来满车“珍宝” |0    |泰国5岁小学生每天开摩托艇上学，最高时速可达64公里|0.95   |
|0    |泰国5岁小学生每天开摩托艇上学，最高时速可达64公里|1    |泰国200列火车一夜之间齐聚中国，带来满车“珍宝” |0.95   |
+-----+--------------------------+-----+--------------------------+-------+
```

至此我们在 Spark ML 包中，利用 Jieba + Jarrcard 系数计算得出了一组文本集中的相似度。

##### Reference

[在Spark上基于Minhash计算jaccard相似度](https://codeleading.com/article/66234289394/)
[Extracting, transforming and selecting features](https://spark.apache.org/docs/3.0.0/ml-features.html#minhash-for-jaccard-distance)
[Locality-Sensitive Hashing, LSH](https://zhuanlan.zhihu.com/p/108181478)