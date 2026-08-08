# abc-electronics-gcp-data-warehouse
A Cloud Based Data Warehouse using Google Cloud Platform

An end-to-end cloud data warehouse developed for **ABC Consumer Electronics**, a fictional multi-channel consumer electronics retailer which is implemented for the MSc Data Warehousing and Big Data Coursework Porject. The project implements a **Medallion Architecture** using **Google Cloud Platform (GCP)**, with data moving through four layers:
**Landing → Bronze → Silver → Gold**

The project covers the complete data warehouse pipeline, starting from relational data exported from **Microsoft SQL Server**, followed by cloud-based data processing using **PySpark**, business reporting using **Apache Hive**, and data manipulation using **Apache Pig**.

## Architecture
                    SQL Server
                        │
                        │ CSV Export
                        ▼
              ┌─────────────────────┐
              │     Landing Layer   │
              │   Cloud Storage     │
              │      Raw CSV        │
              └──────────┬──────────┘
                         │
                         │ PySpark
                         ▼
              ┌─────────────────────┐
              │     Bronze Layer    │
              │     Raw Parquet     │
              └──────────┬──────────┘
                         │
                         │ PySpark
                         │ Cleaning + Validation
                         ▼
              ┌─────────────────────┐
              │     Silver Layer    │
              │ Cleaned & Validated │
              │       Parquet       │
              └──────────┬──────────┘
                         │
                         │ PySpark
                         │ Aggregation
                         ▼
              ┌─────────────────────┐
              │      Gold Layer     │
              │ Business-ready Data │
              │       Parquet       │
              └──────────┬──────────┘
                         │
                  ┌──────┴──────┐
                  ▼             ▼
             Apache Hive   Apache Pig
             Query Layer   Data Analysis

## Google Cloud Architecture
The solution uses Google Cloud Storage as the persistent storage layer and Google Cloud Dataproc for distributed data processing. 

Google Cloud Platform
│
├── Cloud Storage
│   └── abc-consumer-electronics-dw
│       ├── landing/
│       ├── bronze/
│       ├── silver/
│       └── gold/
│
└── Dataproc Cluster
    ├── Apache Spark
    ├── Apache Hive
    ├── Apache Pig
    └── Hadoop

## Repository Structure

├── data/
│   ├── landing/       Raw CSV files uploaded from SQL Server
│   ├── bronze/        Raw data converted to Parquet
│   ├── silver/        Cleaned and validated Parquet data
│   └── gold/          Business-ready analytical tables
│
├── scripts/            PySpark ETL scripts
│   ├── landing_to_bronze.py
│   ├── bronze_to_silver.py
│   └── silver_to_gold.py
│
├── hive/               Hive external table definitions and queries
├── pig/                Apache Pig scripts and execution logs
├── docs/               Project documentation and design details
└── screenshots/        Pipeline execution and query result screenshots
