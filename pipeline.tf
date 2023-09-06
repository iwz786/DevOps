# Define the AWS CodeDeploy application
resource "aws_codedeploy_app" "lambda_app" {
  name     = "lambda-app"  # Replace with your desired application name
  compute_platform = "Lambda"
}

# Define the AWS CodeDeploy deployment group
resource "aws_codedeploy_deployment_group" "lambda_deployment_group" {
  app_name = aws_codedeploy_app.lambda_app.name
  deployment_group_name = "my-lambda-deployment-group"  # Change to your desired deployment group name
  service_role_arn      = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"

  auto_rollback_configuration {
    enabled = false
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  blue_green_deployment_config {
    terminate_blue_instances_on_deployment_success {
      action = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }

    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    green_fleet_provisioning_option {
      action = "DISCOVER_EXISTING"
    }
  }

  load_balancer_info {
    elb_info {
      name = "my-load-balancer-name"  # Change to your load balancer name if needed
    }
  }

  trigger_configuration {
    trigger_events = ["DeploymentStart", "DeploymentSuccess"]
    trigger_name   = "my-trigger-name"  # Change to your desired trigger name
    trigger_target_arn = "arn:aws:sns:us-east-1:123456789012:my-sns-topic"  # Change to your SNS topic ARN
  }
}

resource "aws_codebuild_project" "lambda_build" {
  name       = "my-lambda-build-project"
  description = "Build project for Lambda function"
  source {
    type            = "NO_SOURCE"
    buildspec       = "buildspec.yml"
  }
  
  artifacts {
    type = "CODEPIPELINE"  # Use "CODEPIPELINE" for CodePipeline-based deployments
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:5.0"
    image_pull_credentials_type = "CODEBUILD"
    type            = "LINUX_CONTAINER"
  }
  
  # Specify the service_role here
  service_role = aws_iam_role.codebuild_role.arn
}

resource "aws_codepipeline_webhook" "lambda_webhook" {
  name               = "my-github-webhook"
  authentication     = "GITHUB_HMAC"
  target_action      = "Source"
  target_pipeline    = aws_codepipeline.lambda_pipeline.name
  
  authentication_configuration {
    secret_token = var.github_webhook_secret  # Define the GitHub webhook secret as a variable
  }
  
  filter {
    json_path    = "$.ref"
    match_equals = "refs/heads/main"  # Adjust to your desired branch
  }
  
}


# Define the AWS CodePipeline
resource "aws_codepipeline" "lambda_pipeline" {
  name = "lambda-pipeline"

  artifact_store {
    location = aws_s3_bucket.lambda_artifacts.bucket
    type     = "S3"
  }

  role_arn = aws_iam_role.codepipeline_role.arn

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        OAuthToken = var.github_token
        Owner      = var.github_owner
        Repo       = var.github_repository
        Branch     = "main"  # Adjust to your desired branch
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      configuration = {
        ProjectName = aws_codebuild_project.lambda_build.name
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name             = "Deploy"
      category         = "Deploy"
      owner            = "AWS"
      provider         = "Lambda"
      version          = "1"
      input_artifacts  = ["build_output"]
      configuration = {
        FunctionName = "my-hello-lambda"
        Alias = "live"
      }
    }
  }
}
