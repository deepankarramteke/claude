output "lambda_function_name" {
  description = "Name of the deployed Lambda function"
  value       = aws_lambda_function.jira_creator.function_name
}

output "lambda_function_arn" {
  description = "ARN of the deployed Lambda function"
  value       = aws_lambda_function.jira_creator.arn
}

output "eventbridge_rule_arn" {
  description = "ARN of the EventBridge rule"
  value       = aws_cloudwatch_event_rule.jira_trigger.arn
}

output "eventbridge_rule_name" {
  description = "Name of the EventBridge rule"
  value       = aws_cloudwatch_event_rule.jira_trigger.name
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for Lambda logs"
  value       = aws_cloudwatch_log_group.lambda_logs.name
}

output "lambda_iam_role_arn" {
  description = "ARN of the Lambda execution IAM role"
  value       = aws_iam_role.lambda_exec.arn
}
