resource "aws_iam_role" "ecs_task_execution" {
  name = "${local.name}-ecs-task-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "codebuild" {
  name = "${local.name}-codebuild"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "codebuild.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "codebuild" {
  name = "${local.name}-codebuild-policy"
  role = aws_iam_role.codebuild.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "Artefactos"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:GetObjectVersion", "s3:PutObject", "s3:GetBucketLocation"]
        Resource = [aws_s3_bucket.artifacts.arn, "${aws_s3_bucket.artifacts.arn}/*"]
      },
      {
        Sid      = "EcrLogin"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Sid    = "EcrPush"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability", "ecr:CompleteLayerUpload", "ecr:InitiateLayerUpload",
          "ecr:PutImage", "ecr:UploadLayerPart", "ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer"
        ]
        Resource = aws_ecr_repository.app.arn
      }
    ]
  })
}


resource "aws_iam_role" "codepipeline" {
  name = "${local.name}-codepipeline"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "codepipeline.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "codepipeline" {
  name = "${local.name}-codepipeline-policy"
  role = aws_iam_role.codepipeline.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Artefactos"
        Effect = "Allow"
        Action = [
          "s3:GetObject", "s3:GetObjectVersion", "s3:PutObject",
          "s3:GetBucketVersioning", "s3:GetBucketLocation", "s3:ListBucket"
        ]
        Resource = [aws_s3_bucket.artifacts.arn, "${aws_s3_bucket.artifacts.arn}/*"]
      },
      {
        Sid      = "GitHubConnection"
        Effect   = "Allow"
        Action   = ["codeconnections:UseConnection", "codestar-connections:UseConnection"]
        Resource = local.connection_arn
      },
      {
        Sid      = "CodeBuild"
        Effect   = "Allow"
        Action   = ["codebuild:StartBuild", "codebuild:BatchGetBuilds"]
        Resource = aws_codebuild_project.app.arn
      },
      {
        Sid    = "DeployEcs"
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices", "ecs:DescribeTaskDefinition", "ecs:DescribeTasks",
          "ecs:ListTasks", "ecs:RegisterTaskDefinition", "ecs:UpdateService", "ecs:TagResource"
        ]
        Resource = "*"
      },
      {
        Sid      = "PasarRolATareas"
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = aws_iam_role.ecs_task_execution.arn
        Condition = {
          StringEqualsIfExists = { "iam:PassedToService" = "ecs-tasks.amazonaws.com" }
        }
      }
    ]
  })
}
