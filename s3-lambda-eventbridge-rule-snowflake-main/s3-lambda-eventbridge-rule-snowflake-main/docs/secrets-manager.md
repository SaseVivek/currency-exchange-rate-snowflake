# AWS Secrets Manager Configuration

The Lambda function reads Snowflake credentials from AWS Secrets Manager at
runtime. The provider class
([`src/snowflake_provider.py`](../src/snowflake_provider.py)) expects the
secret to be a JSON object with a top-level key matching
`aws_db_creds_secret_value` (default: `fusion_snowflake`).

## Secret name

```
db/currency-exchange-rate
```

> The secret ID is hard-coded in
> [`src/lambda_function.py`](../src/lambda_function.py) inside
> `connect_to_snowflake()`. Update it there if you use a different name.

## Secret value (template)

Replace every `<placeholder>` before saving. **Do not commit real values.**

```json
{
  "fusion_snowflake": {
    "host":         "https://<account_locator>.snowflakecomputing.com/",
    "username":     "<snowflake_user>",
    "password":     "<snowflake_password>",
    "account_name": "<account_locator>",
    "db":           "CURRENCY_DB",
    "app_id":       "<openexchangerates_app_id>"
  }
}
```

## IAM permission required

The Lambda execution role needs `secretsmanager:GetSecretValue` on the secret
ARN, e.g.:

```json
{
  "Effect": "Allow",
  "Action": "secretsmanager:GetSecretValue",
  "Resource": "arn:aws:secretsmanager:us-east-1:<account-id>:secret:db/currency-exchange-rate-*"
}
```
