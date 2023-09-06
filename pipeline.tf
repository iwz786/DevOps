# Define the AWS CodeDeploy application
resource "aws_codedeploy_application" "lambda_app" {
  name     = "my-lambda-app"  # Change to your desired application name
  compute_platform = "Lambda"
}

# Define the AWS CodeDeploy deployment group
resource "aws_codedeploy_deployment_group" "lambda_deployment_group" {
  app_name = aws_codedeploy_application.lambda_app.name
  deployment_group_name = "my-lambda-deployment-group"  # Change to your desired deployment group name

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

resource "aws_codepipeline_webhook" "lambda_webhook" {
  name               = "my-github-webhook"
  authentication     = "GITHUB_HMAC"
  target_action      = "Source"
  target_pipeline    = aws_codepipeline.lambda_pipeline.name
  target_pipeline_action = "Source"
  
  authentication_configuration {
    secret_token = var.github_webhook_secret  # Define the GitHub webhook secret as a variable
  }
  
  filter {
    json_path    = "$.ref"
    match_equals = "refs/heads/main"  # Adjust to your desired branch
  }
  
  register_with_third_party {
    webhook_url = aws_codepipeline.lambda_pipeline.webhook_url
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
        FunctionName = aws_lambda_function.hello_lambda.function_name
        Alias = "live"
      }
    }
  }
}
