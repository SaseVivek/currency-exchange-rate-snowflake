# Lambda Layers

This folder is **gitignored** — the zips here are build outputs, not source.

The Lambda runtime needs `snowflake-connector-python` (and its native deps) and
`requests`, which together exceed the inline Lambda code size limit. They must
be packaged as a Lambda Layer.

## Build the layer locally

The connector ships native wheels — build the layer in an environment that
matches the Lambda runtime (Linux x86_64, Python 3.9+). The simplest way is to
use Docker:

```bash
mkdir -p python
docker run --rm -v "$PWD":/var/task public.ecr.aws/sam/build-python3.9 \
  pip install -r ../requirements.txt -t python/

zip -r snowflake-layer.zip python/
```

## Publish the layer

```bash
aws lambda publish-layer-version \
  --layer-name snowflake-connector \
  --compatible-runtimes python3.9 python3.10 python3.11 \
  --zip-file fileb://snowflake-layer.zip
```

Attach the published version ARN to the Lambda function.
