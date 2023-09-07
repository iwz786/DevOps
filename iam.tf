# Define the Lambda function
resource "aws_iam_role" "lambda_execution_role" {
  name = var.lambda_execution_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}


# Define IAM roles
resource "aws_iam_role" "codepipeline_role" {
  name = var.codepipeline_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "codepipeline.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role" "codebuild_role" {
  name = var.codebuild_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "codebuild.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy_attachment" "codepipeline_attachment" {
  name       = aws_iam_role.codepipeline_role.name  # Replace with the correct IAM role name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess"
  roles      = [aws_iam_role.codepipeline_role.name]
}

resource "aws_iam_policy_attachment" "codebuild_attachment" {
  name       = aws_iam_role.codebuild_role.name  # Replace with the correct IAM role name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess"
  roles      = [aws_iam_role.codebuild_role.name]
}

# Define the IAM role for AWS CodeDeploy
resource "aws_iam_role" "codedeploy_role" {
  name = "codedeploy-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      }
    ]
  })
}

# Attach an IAM policy to the CodeDeploy role (adjust the policy ARN as needed)
resource "aws_iam_policy_attachment" "codedeploy_attachment" {
  name       = aws_iam_role.codedeploy_role.name  # Replace with the correct IAM role name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"  # Attach a suitable CodeDeploy policy
  roles      = [aws_iam_role.codedeploy_role.name]
}

