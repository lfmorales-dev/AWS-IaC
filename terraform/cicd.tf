resource "aws_codeconnections_connection" "github" {
  count         = var.codeconnection_arn == "" ? 1 : 0
  name          = substr("${local.name}-github", 0, 32)
  provider_type = "GitHub"
}

locals {
  connection_arn = var.codeconnection_arn != "" ? var.codeconnection_arn : aws_codeconnections_connection.github[0].arn
}

resource "aws_s3_bucket" "artifacts" {
  bucket        = "${local.name}-artifacts-${local.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket                  = aws_s3_bucket.artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_codebuild_project" "app" {
  name          = "${local.name}-build"
  description   = "Construir la imagen Docker y publicar en ECR"
  service_role  = aws_iam_role.codebuild.arn
  build_timeout = 20

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true # obligatorio para poder ejecutar docker build

    environment_variable {
      name  = "REPOSITORY_URI"
      value = aws_ecr_repository.app.repository_url
    }
    environment_variable {
      name  = "CONTAINER_NAME"
      value = var.container_name
    }
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = local.account_id
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }

  logs_config {
    cloudwatch_logs {
      status = "DISABLED"
    }
    s3_logs {
      status = "DISABLED"
    }
  }
}

resource "aws_codepipeline" "app" {
  name          = "${local.name}-pipeline"
  role_arn      = aws_iam_role.codepipeline.arn
  pipeline_type = "V2"

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }

  trigger {
    provider_type = "CodeStarSourceConnection"
    git_configuration {
      source_action_name = "GitHub"
      push {
        branches {
          includes = [var.github_branch]
        }
      }
    }
  }

  stage {
    name = "Source"
    action {
      name             = "GitHub"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      namespace        = "SourceVariables"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn        = local.connection_arn
        FullRepositoryId     = var.github_repo
        BranchName           = var.github_branch
        DetectChanges        = "true"
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "DockerBuild"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.app.name
        EnvironmentVariables = jsonencode([{
          name  = "COMMIT_ID"
          value = "#{SourceVariables.CommitId}"
          type  = "PLAINTEXT"
        }])
      }
    }
  }

  stage {
    name = "Approval"
    action {
      name     = "AprobacionManual"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"

      configuration = {
        CustomData = "Revisa la imagen publicada en ECR y aprueba para desplegar en ECS."
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "DeployECS"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ClusterName       = aws_ecs_cluster.main.name
        ServiceName       = aws_ecs_service.app.name
        FileName          = "imagedefinitions.json"
        DeploymentTimeout = "15"
      }
    }
  }
}
