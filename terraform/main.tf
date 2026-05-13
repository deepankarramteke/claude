terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  name_prefix       = "${var.project_name}-${var.environment}"
  lambda_zip_path   = "${path.module}/../dist/lambda.zip"
  use_event_pattern = var.eventbridge_event_pattern != ""
}

# ── EventBridge ────────────────────────────────────────────────────────────────

resource "aws_cloudwatch_event_rule" "jira_trigger" {
  name        = "${local.name_prefix}-trigger"
  description = "Triggers Jira ticket creation Lambda"

  event_pattern       = local.use_event_pattern ? var.eventbridge_event_pattern : null
  schedule_expression = local.use_event_pattern ? null : var.eventbridge_schedule_expression

  tags = local.common_tags
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.jira_trigger.name
  target_id = "JiraLambdaTarget"
  arn       = aws_lambda_function.jira_creator.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.jira_creator.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.jira_trigger.arn
}

# ── Lambda ─────────────────────────────────────────────────────────────────────

resource "aws_lambda_function" "jira_creator" {
  function_name    = "${local.name_prefix}-jira-creator"
  filename         = local.lambda_zip_path
  source_code_hash = filebase64sha256(local.lambda_zip_path)
  handler          = "lambda_function.handler"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda_exec.arn
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size

  environment {
    variables = {
      JIRA_SECRET_NAME = var.jira_secret_name
      JIRA_PROJECT_KEY = var.jira_project_key
      JIRA_ISSUE_TYPE  = var.jira_issue_type
    }
  }

  tags = local.common_tags

  depends_on = [aws_cloudwatch_log_group.lambda_logs]
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${local.name_prefix}-jira-creator"
  retention_in_days = 30
  tags              = local.common_tags
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
