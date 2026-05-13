# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Project Does

Automated Jira ticket creation pipeline:
- **AWS EventBridge rule** fires on a schedule or matching event pattern
- **AWS Lambda (Python 3.12)** receives the event and calls the Jira REST API v3
- **AWS Secrets Manager** holds Jira credentials (`jira_url`, `jira_email`, `jira_api_token`)
- **Terraform** manages all infrastructure

## Commands

```bash
make build        # Package Lambda (pip install + zip → dist/lambda.zip)
make plan         # terraform init + plan (runs build first)
make deploy       # terraform init + apply (runs build first)
make destroy      # terraform destroy
make clean        # remove dist/
make invoke-test  # manually invoke Lambda via AWS CLI
```

## Required Setup Before First Deploy

1. Create the Secrets Manager secret:
   ```bash
   aws secretsmanager create-secret --name prod/jira/credentials \
     --secret-string '{"jira_url":"https://your-domain.atlassian.net","jira_email":"you@example.com","jira_api_token":"<token>"}'
   ```

2. Copy and fill in variables:
   ```bash
   cp terraform/terraform.tfvars.example terraform/terraform.tfvars
   # edit terraform/terraform.tfvars
   ```

3. Deploy:
   ```bash
   make deploy
   ```

## Key Files

| Path | Purpose |
|------|---------|
| `src/lambda_function.py` | Lambda handler — reads secret, calls Jira API |
| `src/requirements.txt` | Python deps (`requests`) |
| `terraform/main.tf` | EventBridge rule + target, Lambda function, CloudWatch logs |
| `terraform/iam.tf` | Lambda execution role; least-privilege secret access |
| `terraform/variables.tf` | All configurable inputs with descriptions |
| `scripts/build.sh` | Packages Lambda into `dist/lambda.zip` |

## EventBridge Trigger Modes

Set exactly one in `terraform.tfvars`:

- **Schedule** (default): `eventbridge_schedule_expression = "rate(1 day)"`
- **Event pattern** (reactive): set `eventbridge_event_pattern` to a JSON pattern string; the schedule variable is ignored when this is non-empty.

## Architecture Notes

- `locals.use_event_pattern` in `main.tf` drives whether the EventBridge rule uses `event_pattern` or `schedule_expression` — only one can be set on the AWS resource at a time.
- The Lambda IAM policy is scoped to `secretsmanager:GetSecretValue` on the specific secret ARN only.
- `dist/` is git-ignored; always run `make build` before `terraform plan/apply`.
