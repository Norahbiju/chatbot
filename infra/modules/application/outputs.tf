output "api_gateway_invoke_url" {
  value = aws_apigatewayv2_api.chat.api_endpoint
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.frontend.domain_name
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.frontend.id
}

output "frontend_bucket_name" {
  value = aws_s3_bucket.frontend.bucket
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.conversation.name
}

output "query_lambda_name" {
  value = aws_lambda_function.query.function_name
}

output "api_id" {
  value = aws_apigatewayv2_api.chat.id
}

output "budget_name" {
  value = aws_budgets_budget.monthly.name
}
