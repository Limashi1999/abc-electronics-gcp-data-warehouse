
-- Dim_Date
dim_date = LOAD 'gs://abc-consumer-electronics-dw/data/landing/Dim_Date.csv' USING PigStorage(',')
    AS (date_key:chararray, full_date:chararray, date_name:chararray, 
        day_of_week:chararray, day_name_of_week:chararray, day_of_year:chararray, 
        week_of_year:chararray, month_name:chararray, month_of_year:chararray, 
        calendar_quarter:chararray, calendar_year:chararray);

dim_date = FILTER dim_date BY date_key != 'date_key';
dim_date = FOREACH dim_date GENERATE 
    (int)date_key AS date_key, 
    full_date, 
    (int)week_of_year AS week_of_year, 
    (int)month_of_year AS month_of_year, 
    (int)calendar_year AS calendar_year;

-- Dim_Product
dim_product = LOAD 'gs://abc-consumer-electronics-dw/data/landing/Dim_Product.csv' USING PigStorage(',')
    AS (product_sku:chararray, product_name:chararray, product_description:chararray, 
        product_cost_price:chararray, product_retail_price:chararray, product_condition:chararray, 
        product_type:chararray, product_brand:chararray, product_tags:chararray, 
        date_created_at:chararray, date_discontinued_at:chararray, is_active:chararray);

dim_product = FILTER dim_product BY product_sku != 'product_sku';
dim_product = FOREACH dim_product GENERATE 
    product_sku, 
    product_name, 
    product_brand, 
    product_type, 
    (double)product_retail_price AS product_retail_price;

-- Dim_Supplier
dim_supplier = LOAD 'gs://abc-consumer-electronics-dw/data/landing/Dim_Supplier.csv' USING PigStorage(',')
    AS (supplier_key:chararray, supplier_name:chararray, supplier_description:chararray, 
        supplier_phone:chararray, supplier_email:chararray, supplier_fax:chararray, 
        first_line_address:chararray, supplier_postcode:chararray, supplier_city:chararray, 
        supplier_state:chararray, supplier_country_id:chararray);

dim_supplier = FILTER dim_supplier BY supplier_key != 'supplier_key';
dim_supplier = FOREACH dim_supplier GENERATE 
    (int)supplier_key AS supplier_key, 
    supplier_name;

-- Fact_Stock_Level
fact_stock = LOAD 'gs://abc-consumer-electronics-dw/data/landing/Fact_Stock_Level.csv' USING PigStorage(',')
    AS (stock_level_key:chararray, stock_level:chararray, cost_price:chararray, 
        retail_price:chararray, date_key:chararray, product_sku:chararray);

fact_stock = FILTER fact_stock BY stock_level_key != 'stock_level_key';
fact_stock = FOREACH fact_stock GENERATE 
    (int)stock_level_key AS stock_level_key, 
    (int)stock_level AS stock_level, 
    (int)date_key AS date_key, 
    product_sku;

-- Fact_PO_Sent
fact_po_sent = LOAD 'gs://abc-consumer-electronics-dw/data/landing/Fact_PO_Sent.csv' USING PigStorage(',')
    AS (po_sent_key:chararray, purchase_order_code:chararray, ordered_qty:chararray, 
        sent_date_key:chararray, product_sku:chararray, supplier_key:chararray);

fact_po_sent = FILTER fact_po_sent BY po_sent_key != 'po_sent_key';
fact_po_sent = FOREACH fact_po_sent GENERATE 
    (int)ordered_qty AS qty, 
    (int)sent_date_key AS date_key, 
    product_sku, 
    (int)supplier_key AS supplier_key;

-- Fact_PO_Received
fact_po_received = LOAD 'gs://abc-consumer-electronics-dw/data/landing/Fact_PO_Received.csv' USING PigStorage(',')
    AS (po_received_key:chararray, purchase_order_code:chararray, destination_outlet:chararray, 
        ordered_qty:chararray, received_qty:chararray, sent_date_key:chararray, 
        received_date_key:chararray, product_sku:chararray, supplier_key:chararray);

fact_po_received = FILTER fact_po_received BY po_received_key != 'po_received_key';
fact_po_received = FOREACH fact_po_received GENERATE 
    (int)received_qty AS qty, 
    (int)received_date_key AS date_key, 
    product_sku, 
    (int)supplier_key AS supplier_key;


-- Report 1: Daily stock levels of all products for the last month
stock_joined = JOIN fact_stock BY product_sku, dim_product BY product_sku;

report1 = FOREACH stock_joined GENERATE 
    fact_stock::date_key AS date_key, 
    fact_stock::product_sku AS product_sku, 
    dim_product::product_name AS product_name, 
    fact_stock::stock_level AS stock_level;

report1_sorted = ORDER report1 BY date_key;
DUMP report1_sorted;

-- Report 2: Weekly report of all products with minimum stock levels

low_stock = FILTER fact_stock BY stock_level <= 5;

low_stock_joined = JOIN low_stock BY product_sku, dim_product BY product_sku;
low_stock_dated = JOIN low_stock_joined BY low_stock::date_key, dim_date BY date_key;

report2 = FOREACH low_stock_dated GENERATE 
    dim_product::product_name AS product_name, 
    dim_product::product_brand AS product_brand, 
    low_stock::stock_level AS stock_level, 
    dim_date::week_of_year AS week_of_year;

DUMP report2;

-- Report 3: Analysing stock levels by brand / product type / supplier

stock_full = JOIN fact_stock BY product_sku, dim_product BY product_sku;
stock_supplier = JOIN stock_full BY fact_stock::product_sku, fact_po_received BY product_sku;

grouped_bts = GROUP stock_supplier BY (dim_product::product_brand, dim_product::product_type);

report3 = FOREACH grouped_bts GENERATE 
    FLATTEN(group) AS (product_brand, product_type), 
    SUM(stock_supplier.fact_stock::stock_level) AS total_stock;

report3_sorted = ORDER report3 BY total_stock DESC;
DUMP report3_sorted;


-- Report 4: Daily and weekly sent/received stock orders, last 4 weeks

sent_labeled = FOREACH fact_po_sent GENERATE date_key, qty, 'SENT' AS activity_type;
received_labeled = FOREACH fact_po_received GENERATE date_key, qty, 'RECEIVED' AS activity_type;

combined = UNION sent_labeled, received_labeled;

-- Daily
grouped_daily = GROUP combined BY (date_key, activity_type);

report4_daily = FOREACH grouped_daily GENERATE 
    FLATTEN(group) AS (date_key, activity_type), 
    SUM(combined.qty) AS total_qty;

DUMP report4_daily;

-- Weekly
combined_dated = JOIN combined BY date_key, dim_date BY date_key;

grouped_weekly = GROUP combined_dated BY (dim_date::week_of_year, combined::activity_type);

report4_weekly = FOREACH grouped_weekly GENERATE 
    FLATTEN(group) AS (week_of_year, activity_type), 
    SUM(combined_dated.combined::qty) AS total_qty;

DUMP report4_weekly;


-- Report 5: Analysing received stock orders by supplier and by month

po_dated = JOIN fact_po_received BY date_key, dim_date BY date_key;
po_supplier_dated = JOIN po_dated BY fact_po_received::supplier_key, dim_supplier BY supplier_key;

grouped_supplier_month = GROUP po_supplier_dated BY 
    (dim_supplier::supplier_name, dim_date::calendar_year, dim_date::month_of_year);

report5 = FOREACH grouped_supplier_month GENERATE 
    FLATTEN(group) AS (supplier_name, year, month), 
    SUM(po_supplier_dated.fact_po_received::qty) AS total_received_qty;

report5_sorted = ORDER report5 BY total_received_qty DESC;
DUMP report5_sorted;