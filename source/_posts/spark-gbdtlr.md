---
title: Spark 机器学习之 GBDT + LR 实现逻辑
date: 2019-09-11 16:25:50
---

##### Introduction

网上很多 Spark 实现 LR 的教程（包括基于 ML 和 MLLib），但是比较少 GBDT + LR 的教程。

GBDT + LR 全称 Gradient Boosting Decision Tree + Logistic Regression，在业界效果一直算比较不错，可以天然的发现一些人工不容易发现的重要特征和组合特征。所以这篇文章记录一下开发的主要逻辑。

![GBDTLR](https://timeline229-image.oss-cn-hangzhou.aliyuncs.com/spark-gbdtlr/GBDTLR.png)

<!--more-->

但 GBDT 属于非线性模型，所以性能方面，比线性模型要差上不少，实测！！！

下面的代码，可能有这样那样的方法丢失，如果都贴上来，那就太多了，主要是想记录一下整体的逻辑，如果要看全部的代码，可以联系我上传。

首先介绍下我的开发环境

```
<scala.version>2.11.12</scala.version>
<spark.version>2.3.3</spark.version>
<hadoop.version>2.7.6</hadoop.version>
<maxcompute.version>1.7.0</maxcompute.version>
```

数据都存在阿里云的 MaxCompute，不知道是啥的，就可以理解为阿里云在 Hive 上的封装。

##### DataCenter

首先最重要的是数据的 load 和 save，在 spark 2.3.x 的环境下，可以很方便的 load 外部数据

```
/**
    * ODPS 读分区表数据
    * @param table
    * @param project
    * @param ds
    * @param sc
    * @return
    */
  def odpsReadPartition(table: String, project: String, ds: String, sc: SparkSession): DataFrameReader = {
    sc.read.format("org.apache.spark.aliyun.odps.datasource")
      .option("odpsUrl", urls.head)
      .option("tunnelUrl", urls(1))
      .option("table", table)
      .option("project", project)
      .option("partitionSpec", ds)
      .option("accessKeyId", accessKeyId)
      .option("accessKeySecret", accessKeySecret)
  }
```

对于 save 操作也是一样的

```
/**
    * ODPS 写分区表数据
    * @param table
    * @param project
    * @param dataSet
    * @param model
    * @param ds
    */
  def odpsWritePartition(table: String, project: String, dataSet: Dataset[Row], model: String, ds: String) = {
    /** model: append or overwrite **/

    dataSet.write.format("org.apache.spark.aliyun.odps.datasource")
      .option("odpsUrl", urls.head)
      .option("tunnelUrl", urls(1))
      .option("table", table)
      .option("project", project)
      .option("accessKeyId", accessKeyId)
      .option("accessKeySecret", accessKeySecret)
      .option("partitionSpec", ds)
      .option("allowCreateNewPartition", "true")
      .mode(model)
      .save()
  }
```

##### FeatureEngineer

特征工程阶段，比较常见的方法有分桶，归一化，Onehot 等等... 在 GBDT 阶段，由于不需要很多的特征，所以我把分桶的特征处理就去掉了

其中 FeatureColumn 内，配置了需要分桶，Indexer，OneHot 的字段名及具体值，整体的代码可以当伪码来看。

```

/**
* userGbtFeatureFit 用户字段转特征 
*
* @param dataset
* @return PipelineModel
*/
def userGbtFeatureFit(dataset: Dataset[Row]) = {

    val bucketColumn = FeatureColumn.userBucketColumn
    val bucketColumnName: ArrayBuffer[String] = new ArrayBuffer[String]()

    for (item <- bucketColumn) {
      bucketColumnName.append(item._1)
    }

    val assemblerBucket = new VectorAssembler()
      .setInputCols(dataset.columns.filter(columnName => bucketColumnName.contains(columnName)))
      .setOutputCol("assemblerBucketUser")
    val minMaxScaler = new MinMaxScaler()
      .setInputCol("assemblerBucketUser")
      .setOutputCol("scalerVectorUser")

    val indexers = FeatureColumn.userIndexerColumn.toArray.map { inColumn =>
      new StringIndexer()
        .setInputCol(inColumn)
        .setOutputCol(s"${inColumn}_idx")
        .setHandleInvalid("keep")
    }

    val oneHotColumn = FeatureColumn.userOneHotColumn

    val oneHotEncoderEstimator = new OneHotEncoderEstimator()
      .setInputCols(oneHotColumn.toArray
        ++ FeatureColumn.userIndexerColumn.map(x => x + "_idx")
      )
      .setOutputCols(oneHotColumn.toArray.map(x => x + "_oneHotVec")
        ++ FeatureColumn.userIndexerColumn.map(x => x + "_oneHotVec"))
      .setHandleInvalid("keep")
      .setDropLast(false)

    val assemblerVector = new VectorAssembler()
      .setInputCols(oneHotEncoderEstimator.getOutputCols.filter(x => x.endsWith("_oneHotVec")) ++ Array("scalerVectorUser"))
      .setOutputCol("ufeatures")

    val pipeline = new Pipeline().setStages(Array(assemblerBucket, minMaxScaler) ++ indexers ++ Array(oneHotEncoderEstimator, assemblerVector))
    pipeline.fit(dataset)

  }

```

##### Gradient Boosting Decision Tree

GBDT 阶段，我们的目的是生成中间特征，而不是最终的结果。

所以将数据给到自定义的 getGBDTFeaturesModel 方法中，输出一个 GradientBoostedTreesModel，之后再将原始特征数据转换成 GBDT 特征数据

```
/**
* getGBDTFeaturesModel 获得 GBDT 模型
*
* @param dataset
* @return GradientBoostedTreesModel
*/
def getGBDTFeaturesModel(dataset: Dataset[_]) = {

    val categoricalFeatures: Map[Int, Int] =
      getCategoricalFeatures(dataset.schema($(featuresCol)))

    // GBT only supports 2 classes now.
    val oldDataset: RDD[OldLabeledPoint] =
      dataset.select(col($(labelCol)), col($(featuresCol))).rdd.map {
        case Row(label: Long, features: Vector) =>
          require(label == 0 || label == 1, s"GBTClassifier was given" +
            s" dataset with invalid label $label.  Labels must be in {0,1}; note that" +
            s" GBTClassifier currently only supports binary classification.")
          OldLabeledPoint(label, new OldDenseVector(features.toArray))
      }

    val strategy = getOldStrategy(categoricalFeatures)
    val boostingStrategy = new OldBoostingStrategy(strategy, getOldLossType,
      getGBTMaxIter, getStepSize)

    // train a gradient boosted tree model using boostingStrategy.
    val gbtModel = GradientBoostedTrees.train(oldDataset, boostingStrategy)
    gbtModel

  }
```

将原始特征 和 gbtModel 给到 getGBTFeatures 方法中，就可以得到由 gbtModel 生成的特征，对此我们可以写一个 UDF 来对每行数据做转换，性能的瓶颈，我猜也是在这里了

```

val addFeatureUDF = udf { features: Vector =>
    val gbtFeatures = getGBTFeatures(gbtModel, features)
    Vectors.dense(features.toArray ++ gbtFeatures.toArray)
}

```

##### Logistic Regression

拿到 GBDT Features 之后，我们就可以把转换后的特征放到 LR 里做训练，接下来的流程，就和普通的 LR 流程一样了

```

val logisticRegression = new LogisticRegression()
    .setRegParam($(regParam))
    .setElasticNetParam($(elasticNetParam))
    .setMaxIter($(LRMaxIter))
    .setTol($(tol))
    .setLabelCol($(labelCol))
    .setFitIntercept($(fitIntercept))
    .setFamily($(family))
    .setStandardization($(standardization))
    .setPredictionCol($(predictionCol))
    .setProbabilityCol($(probabilityCol))
    .setRawPredictionCol($(rawPredictionCol))
    .setAggregationDepth($(aggregationDepth))
    .setFeaturesCol($(gbtGeneratedFeaturesCol))
        
lrModel = logisticRegression.fit(datasetWithGBDTFeatures)

```

##### evaluation

对混合模型的评估，本质上就是对最终生成 LR 模型的评估，我们可以通过验证集拿到这个模型的准确率，召回率，AUC，ROC 等数据

```

val testingEvaluate = gbtlrModel.evaluate(testingData)
val auc = gbtlrModel.lrModel.binarySummary.areaUnderROC

println("model accuracy: " + testingEvaluate.binaryLogisticRegressionSummary.accuracy)
println("model recallByLabel: " + testingEvaluate.binaryLogisticRegressionSummary.recallByLabel.mkString(","))
println("model precisionByLabel: " + testingEvaluate.binaryLogisticRegressionSummary.precisionByLabel.mkString(","))
println("gbtlrModel.binarySummary.areaUnderROC: " + auc)

```

##### persistence

在评估模型之后，我们要把模型持久化，这样才能在预测的时候用到，存放模型的方式都大同小异，我会存在本地的 hdfs 中，注意除了算法模型的保存，特征模型也需要保存

```

val modelPath = "hdfs://master:9000/spark_model/" + appName + "/" + modelId
gbtlrModel.save(modelPath)

userFeaturesModel.save(modelPath + "/userFeatures")
itemFeaturesModel.save(modelPath + "/itemFeatures")

```

##### summary

其实这篇文章，真的很好写，因为代码都是写好的，只是讲了大概的逻辑，在 Spark 上开发 ML 算法，如果有现成的包，固然很方便，但是 Spark 支持的算法太少了，而且公司给的资源也不够多，这一套其实还有很大的优化空间，（比如之前说的由于该模型是非线性模型，做预测相比线性模型，会变得巨慢无比），这个等优化之后再来做记录。