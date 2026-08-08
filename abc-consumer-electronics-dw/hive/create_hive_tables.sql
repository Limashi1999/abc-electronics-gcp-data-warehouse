CREATE DATABASE IF NOT EXISTS dw_lab;

USE dw_lab;

CREATE EXTERNAL TABLE IF NOT EXISTS gold_daily_stock_levels (
  date_key INT, full_date_parsed DATE, product_sku STRING, product_name STRING,
  stock_level INT, cost_price DOUBLE, retail_price DOUBLE
)
STORED AS PARQUET
LOCATION 'gs://abc-consumer-electronics-dw/data/gold/gold_daily_stock_levels';

CREATE EXTERNAL TABLE IF NOT EXISTS gold_minimum_stock_products (
  product_sku STRING, product_name STRING, product_brand STRING, product_type STRING,
  stock_level INT, full_date_parsed DATE, week_of_year INT
)
STORED AS PARQUET
LOCATION 'gs://abc-consumer-electronics-dw/data/gold/gold_minimum_stock_products';

CREATE EXTERNAL TABLE IF NOT EXISTS gold_stock_by_brand_type_supplier (
  product_brand STRING, product_type STRING, supplier_name STRING,
  total_stock_level BIGINT, avg_stock_level DOUBLE
)
STORED AS PARQUET
LOCATION 'gs://abc-consumer-electronics-dw/data/gold/gold_stock_by_brand_type_supplier';

CREATE EXTERNAL TABLE IF NOT EXISTS gold_po_sent_received_daily_last4weeks (
  activity_date DATE, activity_type STRING, total_qty BIGINT
)
STORED AS PARQUET
LOCATION 'gs://abc-consumer-electronics-dw/data/gold/gold_po_sent_received_daily_last4weeks';

CREATE EXTERNAL TABLE IF NOT EXISTS gold_po_sent_received_weekly_last4weeks (
  week_of_year INT, activity_type STRING, total_qty BIGINT
)
STORED AS PARQUET
LOCATION 'gs://abc-consumer-electronics-dw/data/gold/gold_po_sent_received_weekly_last4weeks';

CREATE EXTERNAL TABLE IF NOT EXISTS gold_received_orders_by_supplier_month (
  supplier_key INT, supplier_name STRING, year INT, month INT,
  total_received_qty BIGINT, total_received_value BIGINT
)
STORED AS PARQUET
LOCATION 'gs://abc-consumer-electronics-dw/data/gold/gold_received_orders_by_supplier_month';

SELECT COUNT(*) FROM gold_daily_stock_levels;