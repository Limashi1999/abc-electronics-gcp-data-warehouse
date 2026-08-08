from pyspark.sql import SparkSession
from pyspark.sql.functions import col, trim

spark = SparkSession.builder.appName("Silver").getOrCreate()
BUCKET = "gs://abc-consumer-electronics-dw"

def report(name, before, after):
    print(f"{name}] before: {before} rows -> after: {after} rows (removed {before - after})")

# Dim_Date
dim_date_raw = spark.read.parquet(f"{BUCKET}/data/bronze/Dim_Date")
n0 = dim_date_raw.count()
dim_date = dim_date_raw.filter(col("date_key").isNotNull()).dropDuplicates(["date_key"])
report("Dim_Date", n0, dim_date.count())

# Dim_Product
dim_product_raw = spark.read.parquet(f"{BUCKET}/data/bronze/Dim_Product")
n0 = dim_product_raw.count()
dim_product = (
    dim_product_raw
    .filter(col("product_sku").isNotNull())
    .withColumn("product_sku", trim(col("product_sku")))
    .withColumn("product_name", trim(col("product_name")))
    .filter(col("product_cost_price").isNotNull() & (col("product_cost_price") >= 0))
    .filter(col("product_retail_price").isNotNull() & (col("product_retail_price") >= 0))
    .dropDuplicates(["product_sku"])
)
report("Dim_Product", n0, dim_product.count())

# Dim_Supplier
dim_supplier_raw = spark.read.parquet(f"{BUCKET}/data/bronze/Dim_Supplier")
n0 = dim_supplier_raw.count()
dim_supplier = (
    dim_supplier_raw
    .filter(col("supplier_key").isNotNull())
    .withColumn("supplier_name", trim(col("supplier_name")))
    .dropDuplicates(["supplier_key"])
)
report("Dim_Supplier", n0, dim_supplier.count())

# Fact_PO_Sent
fact_po_sent_raw = spark.read.parquet(f"{BUCKET}/data/bronze/Fact_PO_Sent")
n0 = fact_po_sent_raw.count()
fact_po_sent = (
    fact_po_sent_raw
    .filter(
        col("po_sent_key").isNotNull()
        & col("product_sku").isNotNull()
        & col("supplier_key").isNotNull()
        & col("sent_date_key").isNotNull()
        & (col("ordered_qty") >= 0)
    )
    .dropDuplicates(["po_sent_key"])
    .join(dim_product.select("product_sku"), "product_sku", "left_semi")
    .join(dim_supplier.select("supplier_key"), "supplier_key", "left_semi")
    .join(dim_date.select(col("date_key").alias("sent_date_key")), "sent_date_key", "left_semi")
)
report("Fact_PO_Sent", n0, fact_po_sent.count())

# Fact_PO_Received
fact_po_received_raw = spark.read.parquet(f"{BUCKET}/data/bronze/Fact_PO_Received")
n0 = fact_po_received_raw.count()
fact_po_received = (
    fact_po_received_raw
    .filter(
        col("po_received_key").isNotNull()
        & col("product_sku").isNotNull()
        & col("supplier_key").isNotNull()
        & col("sent_date_key").isNotNull()
        & col("received_date_key").isNotNull()
        & (col("ordered_qty") >= 0)
        & (col("received_qty") >= 0)
    )
    .dropDuplicates(["po_received_key"])
    .join(dim_product.select("product_sku"), "product_sku", "left_semi")
    .join(dim_supplier.select("supplier_key"), "supplier_key", "left_semi")
    .join(dim_date.select(col("date_key").alias("sent_date_key")), "sent_date_key", "left_semi")
    .join(dim_date.select(col("date_key").alias("received_date_key")), "received_date_key", "left_semi")
)
report("Fact_PO_Received", n0, fact_po_received.count())

# Fact_Stock_Level
fact_stock_level_raw = spark.read.parquet(f"{BUCKET}/data/bronze/Fact_Stock_Level")
n0 = fact_stock_level_raw.count()
fact_stock_level = (
    fact_stock_level_raw
    .filter(
        col("stock_level_key").isNotNull()
        & col("product_sku").isNotNull()
        & col("date_key").isNotNull()
        & (col("stock_level") >= 0)
        & (col("cost_price") >= 0)
        & (col("retail_price") >= 0)
    )
    .dropDuplicates(["stock_level_key"])
    .join(dim_product.select("product_sku"), "product_sku", "left_semi")
    .join(dim_date.select("date_key"), "date_key", "left_semi")
)
report("Fact_Stock_Level", n0, fact_stock_level.count())

dim_date.write.mode("overwrite").parquet(f"{BUCKET}/data/silver/Dim_Date")
dim_product.write.mode("overwrite").parquet(f"{BUCKET}/data/silver/Dim_Product")
dim_supplier.write.mode("overwrite").parquet(f"{BUCKET}/data/silver/Dim_Supplier")
fact_po_sent.write.mode("overwrite").parquet(f"{BUCKET}/data/silver/Fact_PO_Sent")
fact_po_received.write.mode("overwrite").parquet(f"{BUCKET}/data/silver/Fact_PO_Received")
fact_stock_level.write.mode("overwrite").parquet(f"{BUCKET}/data/silver/Fact_Stock_Level")

print("Silver layer complete.")
