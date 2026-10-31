# Naming Conventions

AWS resources for this pipeline follow a consistent naming scheme so they are
easy to find in the console and in IaC.

| Resource     | Name                                |
| ------------ | ----------------------------------- |
| Lambda       | `fn-currency-exchange-rate-qh`      |
| IAM Role     | `role-currency-exchange-rate`       |
| S3 Bucket    | `s3-currency-exchange-rate-qh`      |
| EventBridge  | `rule-currency-exchange-rate-qh`    |
| Secret       | `db/currency-exchange-rate`         |

## Snowflake

| Object          | Name                              |
| --------------- | --------------------------------- |
| Database        | `CURRENCY_DB`                     |
| Schema          | `CURRENCY`                        |
| Raw table       | `EXCHANGE_RATES_RAW`              |
| Staging table   | `EXCHANGE_RATES_STG`              |
| Curated table   | `EXCHANGE_RATES`                  |
| Stored proc     | `SP_EXCHANGE_RATE_LOADING`        |

## S3 layout

Raw API responses are written under:

```
s3://<bucket>/exchange_rates/{YYYY}/{MM}/{DD}/exchange-rates-{HH}.json
```
