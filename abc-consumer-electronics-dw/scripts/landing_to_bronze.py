from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("Bronze").getOrCreate()

BUCKET = "gs://abc-consumer-electronics-dw"

tables = ["Dim_Date", "Dim_Product", "Dim_Supplier",
          "Fact_PO_Sent", "Fact_PO_Received", "Fact_Stock_Level"]

for table in tables:
    df = spark.read.csv(f"{BUCKET}/data/landing/{table}.csv", header=True, inferSchema=True)
    df.write.mode("overwrite").parquet(f"{BUCKET}/data/bronze/{table}")

print("Bronze layer complete.")