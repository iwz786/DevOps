provider "aws" {
  region = "us-east-1"  # Change to your desired AWS region
}

# resource "aws_lambda_function" "hello_lambda" {
#   function_name = "my-hello-lambda"
#   runtime = "python3.8"
#   handler = "hello_lambda.lambda_handler"
#   filename = "lambda-package.zip"
#   source_code_hash = filebase64sha256("lambda-package.zip")

#   role = aws_iam_role.lambda_execution_role.arn

#   depends_on = [aws_iam_role.lambda_execution_role]
# }

# Create an S3 bucket
resource "aws_s3_bucket" "lambda_artifacts" {
  bucket = "my-lambda-artifacts-bucket"  # Replace with your desired bucket name
  acl    = "private"  # Adjust the ACL (Access Control List) as needed
}

output "codepipeline_webhook_url" {
  value = aws_codepipeline_webhook.lambda_webhook.url
}

