
# 💱 Currency Exchange Rate ETL Pipeline | AWS Lambda + Snowflake

An end-to-end, serverless data engineering pipeline that automatically extracts real-time currency exchange rates from the **Open Exchange Rates API**, stores immutable raw JSON data in **Amazon S3**, and transforms and loads the data into **Snowflake** for reliable, analytics-ready consumption.

The pipeline uses AWS EventBridge for scheduled execution, AWS Lambda for ETL orchestration, AWS Secrets Manager for credential management, and Snowflake stored procedures for data transformation and incremental loading.

## 📌 Project Overview

Financial applications, international businesses, and analytics platforms rely on accurate exchange rate data for currency conversion, reporting, and financial analysis. This project automates the collection and processing of exchange rates through a serverless ETL architecture, minimizing manual intervention and separating raw data storage from analytical data processing.

**Key capabilities**
- Automated, schedule-based data ingestion.
- API integration using Python and AWS Lambda.
- Durable raw-data storage in Amazon S3.
- Secure credential retrieval through AWS Secrets Manager.
- Multi-layer data processing: RAW → STG → curated.
- Snowflake `MERGE` operations to maintain curated exchange rate records.
- Execution monitoring through Amazon CloudWatch and Snowflake query history.

## 🏗️ System Architecture

```text
                  ┌──────────────────────┐
                  │   Amazon EventBridge │
                  │    Scheduled Trigger │
                  └──────────┬───────────┘
                             │
                             ▼
                  ┌──────────────────────┐
                  │     AWS Lambda       │
                  │   Python ETL Logic   │
                  └──────────┬───────────┘
                             │
                  ┌──────────┴───────────┐
                  ▼                      ▼
       ┌──────────────────┐   ┌──────────────────┐
       │ Open Exchange     │   │ AWS Secrets      │
       │ Rates API         │   │ Manager          │
       └────────┬─────────┘   └────────┬─────────┘
                │                      │
                ▼                      ▼
       ┌──────────────────┐   ┌──────────────────┐
       │ Amazon S3        │   │ Snowflake        │
       │ Raw JSON Storage │   │ Connector Access │
       └──────────────────┘   └────────┬─────────┘
                                       │
                                       ▼
                         ┌────────────────────────┐
                         │ EXCHANGE_RATES_RAW     │
                         └───────────┬────────────┘
                                     ▼
                         ┌────────────────────────┐
                         │ EXCHANGE_RATES_STG     │
                         │ Flatten JSON Rates     │
                         └───────────┬────────────┘
                                     ▼
                         ┌────────────────────────┐
                         │ EXCHANGE_RATES         │
                         │ Curated Analytics Data │
                         └────────────────────────┘
```

**Architecture principle:** Amazon S3 preserves the source payload, while Snowflake manages structured data processing and the curated analytical layer.

[View Architecture Diagram](https://github.com/DaniyalAneeq/s3-lambda-eventbridge-rule-snowflake/blob/main/docs/architecture.jpg)

## 🛠️ Technology Stack

| Technology | Role in the Pipeline |
|---|---|
| Python | API extraction and ETL orchestration |
| AWS Lambda | Serverless execution of the pipeline |
| Amazon EventBridge | Scheduled pipeline triggering |
| Amazon S3 | Raw JSON data storage |
| AWS Secrets Manager | Secure storage of API and database credentials |
| Snowflake | Data warehousing and transformation |
| Snowflake Connector for Python | Python-to-Snowflake connectivity |
| SQL & Stored Procedures | JSON flattening, staging, and curated loading |
| Amazon CloudWatch | Execution logs and operational monitoring |
| Open Exchange Rates API | External exchange rate data source |

## 🔄 ETL Workflow

### 1. Extract — API Ingestion

Amazon EventBridge invokes the Lambda function according to a configured schedule.

The Lambda function sends an HTTP GET request to the Open Exchange Rates API, using USD as the base currency in the configured request.

The API response contains exchange rate information in JSON format, including the base currency, timestamp, and target-currency rates.

### 2. Load — Raw Data Storage

The original API response is written to Amazon S3 without flattening the payload.

Example S3 object structure:

```text
s3://<bucket-name>/
└── exchange_rates/
    └── 2026/
        └── 10/
            └── 31/
                └── exchange-rates-12.json
```

The year, month, and day hierarchy organizes raw data by ingestion date, while the filename includes the hour.

This structure supports organized storage and makes historical payloads easier to locate.

### 3. Transform — Snowflake Processing

The Lambda function invokes the Snowflake stored procedure:

`CURRENCY.SP_EXCHANGE_RATE_LOADING(p_json_data, p_datetime)`

The stored procedure processes the incoming payload through three logical layers.

**RAW layer — `EXCHANGE_RATES_RAW`**
- Stores the incoming JSON payload and its associated timestamp.
- Serves as the initial Snowflake landing table.
- Supports inspection of the source data.

**STG layer — `EXCHANGE_RATES_STG`**
- Flattens the JSON `rates` object into individual currency records.
- Converts the semi-structured API response into relational rows.
- Prepares data for curated loading.

**Curated layer — `EXCHANGE_RATES`**
- Uses a SQL `MERGE` operation to insert or update matching records.
- Matches records using `(timestamp_utc, base_currency, target_currency)`.
- Provides structured exchange rate data for downstream analytics.

### 4. Monitor — Execution and Data Validation

Amazon CloudWatch provides Lambda logs, execution duration, invocation metrics, and error metrics.

Snowflake query history can be used to inspect stored procedure executions and investigate data loading issues.

## 🗂️ Repository Structure

```text
s3-lambda-eventbridge-rule-snowflake/
│
├── docs/
│   ├── architecture.jpg
│   ├── conventions.md
│   ├── iam-roles.md
│   └── secrets-manager.md
│
├── layers/
│   └── README.md
│
├── sql/
│   └── snowflake_setup.sql
│
├── src/
│   ├── lambda_function.py
│   └── snowflake_provider.py
│
├── .env.example
├── .gitignore
├── requirements.txt
├── LICENSE
└── README.md
```

| File or Directory | Description |
|---|---|
| `src/lambda_function.py` | Lambda entry point and ETL orchestration |
| `src/snowflake_provider.py` | Snowflake connection and Secrets Manager integration |
| `sql/snowflake_setup.sql` | Database objects, tables, and stored procedure definitions |
| `docs/architecture.jpg` | Pipeline architecture diagram |
| `docs/iam-roles.md` | IAM permissions and role configuration |
| `docs/secrets-manager.md` | Secret naming and expected JSON structure |
| `layers/README.md` | Instructions for building the Snowflake connector layer |
| `.env.example` | Environment variable template |
| `requirements.txt` | Python dependency definitions |

## ⚙️ Prerequisites

Before deploying the pipeline, prepare the following:

- An AWS account with permissions to configure Lambda, EventBridge, S3, IAM, and Secrets Manager.
- A Snowflake account with permissions to create the required database objects.
- An Open Exchange Rates API key.
- Python 3.9 or a compatible runtime supported by the deployment configuration.
- AWS CLI credentials configured through an appropriate credential provider.
- A compatible Snowflake Connector for Python Lambda layer.

## 🚀 Deployment Guide

### Step 1: Configure Snowflake

Execute [`sql/snowflake_setup.sql`](https://github.com/DaniyalAneeq/s3-lambda-eventbridge-rule-snowflake/blob/main/sql/snowflake_setup.sql).

The setup script defines:

- Database: `CURRENCY_DB`
- Schema: `CURRENCY`
- Raw table: `EXCHANGE_RATES_RAW`
- Staging table: `EXCHANGE_RATES_STG`
- Curated table: `EXCHANGE_RATES`
- Stored procedure: `SP_EXCHANGE_RATE_LOADING`

### Step 2: Configure AWS Secrets Manager

Create the secret `db/currency-exchange-rate` following the structure documented in [`docs/secrets-manager.md`](https://github.com/DaniyalAneeq/s3-lambda-eventbridge-rule-snowflake/blob/main/docs/secrets-manager.md).

Ensure that the Lambda execution role has permission to retrieve only the required secret.

### Step 3: Create the S3 Bucket

Create an S3 bucket for raw exchange rate payloads.

The example configuration uses `s3-currency-exchange-rate-qh`. Update the environment configuration if a different bucket name is selected.

### Step 4: Build the Lambda Layer

Follow [`layers/README.md`](https://github.com/DaniyalAneeq/s3-lambda-eventbridge-rule-snowflake/blob/main/layers/README.md) to package the Snowflake Connector for Python and its compatible dependencies.

Publish the layer and attach it to the Lambda function.

### Step 5: Deploy the Lambda Function

Create the function `fn-currency-exchange-rate-qh` and configure:

- Runtime compatible with the project's Python dependencies.
- Handler: `lambda_function.lambda_handler`
- Source files from the `src/` directory.
- Snowflake connector layer.
- Required environment variables from `.env.example`.
- Execution role with the permissions specified in `docs/iam-roles.md`.

### Step 6: Configure EventBridge

Create the rule `rule-currency-exchange-rate-qh` and configure it to invoke the Lambda function.

Example hourly schedule:

```text
rate(1 hour)
```

Alternatively, use a cron expression:

```text
cron(0 * * * ? *)
```

The actual schedule and execution timezone should be selected according to the pipeline's operational requirements.

### Step 7: Validate the Pipeline

After deployment, verify that:

1. EventBridge successfully invokes the Lambda function.
2. The API request returns a valid exchange rate payload.
3. The raw JSON object appears in the expected S3 location.
4. Snowflake receives and processes the payload.
5. The RAW and STG tables contain the expected data.
6. The curated table contains the corresponding exchange rate records.
7. CloudWatch logs and Snowflake query history show the expected execution status.

## 🔐 Security Best Practices

- Store API keys and database credentials in AWS Secrets Manager.
- Never commit real credentials, `.env` files, private keys, or secret material.
- Use IAM policies that restrict access to the required S3 bucket and secret ARN.
- Apply least-privilege permissions to the Snowflake execution role.
- Avoid using `ACCOUNTADMIN` for routine pipeline execution.
- Encrypt data at rest and in transit using appropriate service configurations.
- Review CloudWatch logs to ensure credentials and sensitive values are not exposed.
- Restrict access to the S3 bucket and Snowflake objects according to organizational requirements.

## 📊 Monitoring and Troubleshooting

| Area | What to Check |
|---|---|
| EventBridge | Rule state, schedule, and Lambda invocation target |
| Lambda | Execution errors, duration, timeouts, and memory usage |
| API | Authentication, request failures, rate limits, and response structure |
| S3 | Bucket permissions, object path, and successful writes |
| Secrets Manager | Secret name, JSON structure, and IAM access |
| Snowflake | Connector connectivity, SQL errors, procedure execution, and merge behavior |
| Data quality | Missing rates, duplicate business keys, timestamps, and unexpected nulls |

**Troubleshooting approach:** Start with the Lambda execution logs, identify the failed pipeline stage, and then inspect the relevant AWS service or Snowflake query history.

## 💡 Key Data Engineering Concepts Demonstrated

- **Serverless architecture:** Executes scheduled data ingestion without managing dedicated servers.
- **ETL orchestration:** Coordinates extraction, raw storage, transformation, and curated loading.
- **Data lake fundamentals:** Preserves original API payloads in Amazon S3.
- **Data warehousing:** Uses Snowflake to organize raw, staging, and curated data.
- **Semi-structured data processing:** Converts JSON exchange rate objects into relational records.
- **Incremental data loading:** Uses `MERGE` to maintain curated records based on a composite key.
- **Cloud security:** Separates credentials from application code.
- **Observability:** Uses AWS and Snowflake execution records for troubleshooting.

## 🔮 Potential Future Enhancements

The following are proposed improvements, not claims about existing implementation:

- Add automated retries with exponential backoff for transient API and Snowflake failures.
- Introduce idempotency controls and duplicate-run protection.
- Add schema validation and data quality checks before curated loading.
- Implement dead-letter handling and failure notifications.
- Add automated deployment using AWS SAM, Terraform, or CI/CD workflows.
- Introduce historical backfills and configurable base currencies.
- Build Power BI or Tableau dashboards to analyze exchange rate movements.
- Add automated tests for API handling, transformation logic, and Snowflake loading.

## 📜 License

vivek sase
---

**Project Focus:** Serverless ETL | AWS Cloud Services | Python | SQL | Snowflake | Data Engineering
