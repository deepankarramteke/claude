data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name               = "${local.name_prefix}-lambda-exec"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Least-privilege: allow only GetSecretValue on the specific Jira secret
data "aws_secretsmanager_secret" "jira_credentials" {
  name = var.jira_secret_name
}

data "aws_iam_policy_document" "secrets_access" {
  statement {
    sid       = "GetJiraSecret"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [data.aws_secretsmanager_secret.jira_credentials.arn]
  }
}

resource "aws_iam_role_policy" "lambda_secrets_access" {
  name   = "jira-secret-access"
  role   = aws_iam_role.lambda_exec.id
  policy = data.aws_iam_policy_document.secrets_access.json
}
