# IAM Roles & Permissions

The Lambda function needs a single execution role with permissions to:

1. Write logs to CloudWatch.
2. Read the Snowflake credentials secret.
3. Put objects into the raw-data S3 bucket.

The EventBridge rule needs permission to invoke the Lambda function.

## Lambda execution role — minimum policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CloudWatchLogs",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Sid": "S3Write",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::<your-bucket-name>/exchange_rates/*"
    },
    {
      "Sid": "SecretsRead",
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "arn:aws:secretsmanager:<region>:<account-id>:secret:db/currency-exchange-rate-*"
    }
  ]
}
```

## EventBridge → Lambda

When you create the rule from the AWS Console with a Lambda target, AWS will
add a `lambda:InvokeFunction` resource policy to the function automatically.

If you provision via IaC, add it explicitly:

```json
{
  "Effect": "Allow",
  "Principal": { "Service": "events.amazonaws.com" },
  "Action": "lambda:InvokeFunction",
  "Resource": "arn:aws:lambda:<region>:<account-id>:function:fn-currency-exchange-rate-qh",
  "Condition": {
    "ArnLike": {
      "AWS:SourceArn": "arn:aws:events:<region>:<account-id>:rule/rule-currency-exchange-rate-qh"
    }
  }
}
```

> Avoid AWS-managed broad policies (`AmazonS3FullAccess`, `AWSLambda_FullAccess`)
> in production. Scope down to the specific bucket and secret as shown above.
