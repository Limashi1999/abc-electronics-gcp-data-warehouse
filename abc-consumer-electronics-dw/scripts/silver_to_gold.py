from pyspark.sql import SparkSession
from pyspark.sql.functions import (
    col, sum as _sum, avg, to_date, weekofyear, year, month, row_number, lit, greatest
)
from pyspark.sql.window import Window

spark = SparkSession.builder.appName("Gold").getOrCreate()
BUCKET = "gs://abc-consumer-electronics-dw"

dim_date = spark.read.parquet(f"{BUCKET}/data/silver/Dim_Date").withColumn("full_date_parsed", to_date(col("full_date")))
dim_product = spark.read.parquet(f"{BUCKET}/data/silver/Dim_Product")
dim_supplier = spark.read.parquet(f"{BUCKET}/data/silver/Dim_Supplier")
fact_po_sent = spark.read.parquet(f"{BUCKET}/data/silver/Fact_PO_Sent")
fact_po_received = spark.read.parquet(f"{BUCKET}/data/silver/Fact_PO_Received")
fact_stock_level = spark.read.parquet(f"{BUCKET}/data/silver/Fact_Stock_Level")

stock_dates = fact_stock_level.join(dim_date, "date_key")
STOCK_MAX_DATE = stock_dates.agg({"full_date_parsed": "max"}).collect()[0][0]
STOCK_CUTOFF_30D = spark.sql(f"SELECT date_sub('{STOCK_MAX_DATE}', 30)").collect()[0][0]

sent_dates = fact_po_sent.join(dim_date, fact_po_sent.sent_date_key == dim_date.date_key).select("full_date_parsed")
received_dates = fact_po_received.join(dim_date, fact_po_received.received_date_key == dim_date.date_key).select("full_date_parsed")
PO_MAX_DATE = sent_dates.unionByName(received_dates).agg({"full_date_parsed": "max"}).collect()[0][0]
PO_CUTOFF_28D = spark.sql(f"SELECT date_sub('{PO_MAX_DATE}', 28)").collect()[0][0]

print(f"Stock max date: {STOCK_MAX_DATE}, cutoff: {STOCK_CUTOFF_30D}")
print(f"PO max date: {PO_MAX_DATE}, cutoff: {PO_CUTOFF_28D}")

# Report 1: Daily stock levels, last month
report1 = (
    stock_dates.join(dim_product, "product_sku")
    .filter(col("full_date_parsed") >= STOCK_CUTOFF_30D)
    .select("date_key", "full_date_parsed", "product_sku", "product_name",
            "stock_level", "cost_price", "retail_price")
)
report1.write.mode("overwrite").parquet(f"{BUCKET}/data/gold/gold_daily_stock_levels")
print(f"[Report 1] gold_daily_stock_levels rows: {report1.count()}")

# Report 2: Products at/below minimum stock (weekly)
MIN_STOCK_THRESHOLD = 5

latest_stock = (
    stock_dates
    .withColumn("rn", row_number().over(Window.partitionBy("product_sku").orderBy(col("full_date_parsed").desc())))
    .filter(col("rn") == 1).drop("rn")
)
report2 = (
    latest_stock.join(dim_product, "product_sku")
    .filter(col("stock_level") <= MIN_STOCK_THRESHOLD)
    .withColumn("week_of_year", weekofyear(col("full_date_parsed")))
    .select("product_sku", "product_name", "product_brand", "product_type",
            "stock_level", "full_date_parsed", "week_of_year")
)
report2.write.mode("overwrite").parquet(f"{BUCKET}/data/gold/gold_minimum_stock_products")
print(f"[Report 2] gold_minimum_stock_products rows: {report2.count()}")

# Report 3: Stock levels by brand / type / supplier
product_supplier = (
    fact_po_received
    .withColumn("rn", row_number().over(Window.partitionBy("product_sku").orderBy(col("received_date_key").desc())))
    .filter(col("rn") == 1)
    .select("product_sku", "supplier_key")
)
stock_enriched = (
    fact_stock_level.join(dim_product, "product_sku")
    .join(product_supplier, "product_sku", "left")
    .join(dim_supplier, "supplier_key", "left")
)
report3 = (
    stock_enriched.groupBy("product_brand", "product_type", "supplier_name")
    .agg(_sum("stock_level").alias("total_stock_level"), avg("stock_level").alias("avg_stock_level"))
)
report3.write.mode("overwrite").parquet(f"{BUCKET}/data/gold/gold_stock_by_brand_type_supplier")
print(f"[Report 3] gold_stock_by_brand_type_supplier rows: {report3.count()}")

# Report 4: Daily & weekly sent/received orders, last 4 weeks
sent = (
    fact_po_sent.join(dim_date, fact_po_sent.sent_date_key == dim_date.date_key)
    .select(col("full_date_parsed").alias("activity_date"), col("ordered_qty").alias("qty"))
    .withColumn("activity_type", lit("SENT"))
)
received = (
    fact_po_received.join(dim_date, fact_po_received.received_date_key == dim_date.date_key)
    .select(col("full_date_parsed").alias("activity_date"), col("received_qty").alias("qty"))
    .withColumn("activity_type", lit("RECEIVED"))
)
combined = sent.unionByName(received).filter(col("activity_date") >= PO_CUTOFF_28D)

report4_daily = combined.groupBy("activity_date", "activity_type").agg(_sum("qty").alias("total_qty"))
report4_weekly = (
    combined.withColumn("week_of_year", weekofyear(col("activity_date")))
    .groupBy("week_of_year", "activity_type").agg(_sum("qty").alias("total_qty"))
)
report4_daily.write.mode("overwrite").parquet(f"{BUCKET}/data/gold/gold_po_sent_received_daily_last4weeks")
report4_weekly.write.mode("overwrite").parquet(f"{BUCKET}/data/gold/gold_po_sent_received_weekly_last4weeks")
print(f"[Report 4] daily rows: {report4_daily.count()}, weekly rows: {report4_weekly.count()}")

# Report 5: Received orders by supplier and month
received_enriched = (
    fact_po_received
    .join(dim_date, fact_po_received.received_date_key == dim_date.date_key)
    .join(dim_supplier, "supplier_key")
    .join(dim_product, "product_sku")
)
report5 = (
    received_enriched
    .withColumn("year", year(col("full_date_parsed")))
    .withColumn("month", month(col("full_date_parsed")))
    .groupBy("supplier_key", "supplier_name", "year", "month")
    .agg(
        _sum("received_qty").alias("total_received_qty"),
        _sum(col("received_qty") * col("product_retail_price")).alias("total_received_value")
    )
)
report5.write.mode("overwrite").parquet(f"{BUCKET}/data/gold/gold_received_orders_by_supplier_month")
print(f"[Report 5] gold_received_orders_by_supplier_month rows: {report5.count()}")

print("Gold layer complete – all 5 report tables written.")