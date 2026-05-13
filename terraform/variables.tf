variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix used for all resource names"
  type        = string
  default     = "jira-automation"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# ── Jira ──────────────────────────────────────────────────────────────────────

variable "jira_secret_name" {
  description = "Secrets Manager secret name containing {jira_url, jira_email, jira_api_token}"
  type        = string
}

variable "jira_project_key" {
  description = "Jira project key where tickets will be created (e.g. OPS, INFRA)"
  type        = string
}

variable "jira_issue_type" {
  description = "Jira issue type for created tickets"
  type        = string
  default     = "Bug"
}

# ── EventBridge ───────────────────────────────────────────────────────────────

variable "eventbridge_schedule_expression" {
  description = "Schedule expression used when no event_pattern is set (e.g. 'rate(1 hour)', 'cron(0 9 * * ? *)')"
  type        = string
  default     = "rate(1 day)"
}

variable "eventbridge_event_pattern" {
  description = "JSON event pattern for reactive triggers. When set, schedule_expression is ignored."
  type        = string
  default     = ""
  # Example — trigger on CloudWatch Alarm state change:
  # {"source":["aws.cloudwatch"],"detail-type":["CloudWatch Alarm State Change"],"detail":{"state":{"value":["ALARM"]}}}
}

# ── Lambda ────────────────────────────────────────────────────────────────────

variable "lambda_timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 30
}

variable "lambda_memory_size" {
  description = "Lambda memory allocation in MB"
  type        = number
  default     = 128
}
