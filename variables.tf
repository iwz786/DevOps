# Define variables
variable "github_token" {
  description = "GitHub personal access token"
  # default     = lookup(env, "GITHUB_TOKEN", null)
}

variable "github_owner" {
  description = "GitHub personal access token"
  # default     = lookup(env, "GITHUB_OWNER", null)
}

variable "github_repository" {
  description = "GitHub repository URL (e.g., https://github.com/yourusername/yourrepository)"
  # default     = lookup(env, "GITHUB_REPOSITORY", null)
}

variable "github_webhook_secret" {
  description = "GitHub webhook secret"
  # default     = lookup(env, "GITHUB_WEBHOOK_SECRET", null)
}


# Read IAM role names from environment variables
variable "lambda_execution_role_name" {
  description = "Name of the Lambda execution role"
  default     = "LAMBDA_EXECUTION_ROLE_NAME"
}

variable "codepipeline_role_name" {
  description = "Name of the CodePipeline IAM role"
  default     = "CODEPIPELINE_ROLE_NAME"
}

variable "codebuild_role_name" {
  description = "Name of the CodeBuild IAM role"
  default     = "CODEBUILD_ROLE_NAME"
}
