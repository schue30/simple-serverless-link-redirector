resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${var.lambda_name}"
  retention_in_days = var.log_storage_retention
}

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "cloudwatch_logging" {
  role = aws_iam_role.lambda_role.id
  name = "Logging-to-CloudWatch"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Effect = "Allow"
        Resource = formatlist("%s:log-stream:*", [aws_cloudwatch_log_group.lambda_log_group.arn])
      }
    ]
  })
}

resource "aws_iam_role" "lambda_role" {
  name               = "Lambda-${var.lambda_name}-Role"
  description        = "Lambda-${var.lambda_name}-Role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

data "archive_file" "lambda_source" {
  type        = "zip"
  source_file = "${path.module}/source/function.py"
  output_path = "${path.module}/.tmp/lambda-function-source.zip"
}

resource "aws_lambda_function" "link_redirector" {
  function_name    = var.lambda_name
  handler          = "function.lambda_handler"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda_role.arn
  filename         = data.archive_file.lambda_source.output_path
  source_code_hash = data.archive_file.lambda_source.output_base64sha256
}

resource "aws_apigatewayv2_api" "link_redirector" {
  name          = "apigw-${var.lambda_name}"
  protocol_type = "HTTP"
  description   = "API Gateway for Lambda function ${var.lambda_name}"

  cors_configuration {
    allow_credentials = false
    allow_headers = []
    allow_methods = [
      "GET"
    ]
    allow_origins = [
      "*",
    ]
    expose_headers = []
    max_age = 0
  }
}


resource "aws_apigatewayv2_stage" "default" {
  api_id = aws_apigatewayv2_api.link_redirector.id

  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_rate_limit  = 10
    throttling_burst_limit = 10
  }
}

resource "aws_apigatewayv2_integration" "link_redirector" {
  api_id = aws_apigatewayv2_api.link_redirector.id

  integration_uri  = aws_lambda_function.link_redirector.invoke_arn
  integration_type = "AWS_PROXY"
}

resource "aws_apigatewayv2_route" "any" {
  api_id    = aws_apigatewayv2_api.link_redirector.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.link_redirector.id}"
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.link_redirector.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.link_redirector.execution_arn}/*/*"
}

resource "aws_cloudwatch_dashboard" "dashboard" {
  dashboard_name = "${var.lambda_name}-Stats"
  dashboard_body = jsonencode({
    widgets : [
      {
        type : "log",
        x : 0,
        y : 0,
        width : 24,
        height : 6,
        properties : {
          query : "SOURCE '${aws_cloudwatch_log_group.lambda_log_group.name}' | fields campaign\n| stats count() as number_of_clicks by campaign",
          region : var.region,
          stacked : false,
          view : "table"
        }
      },
      {
        type : "log",
        x : 0,
        y : 6,
        width : 24,
        height : 6,
        properties : {
          query : "SOURCE '${aws_cloudwatch_log_group.lambda_log_group.name}' | fields @timestamp, campaign\n| stats count() as number_of_clicks, min(@timestamp) as oldest_click, max(@timestamp) as recent_click by campaign, campaign\n| sort recent_time desc",
          region : var.region,
          stacked : false,
          view : "table"
        }
      }
    ]
  })
}

