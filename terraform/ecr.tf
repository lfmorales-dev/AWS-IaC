resource "aws_ecr_repository" "app" {
  name                 = "${local.name}-app"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "terraform_data" "initial_image" {
  count            = var.build_initial_image ? 1 : 0
  triggers_replace = [aws_ecr_repository.app.repository_url]

  provisioner "local-exec" {
    command = join(" && ", [
      "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${local.ecr_registry}",
      "docker build --platform linux/amd64 --build-arg APP_VERSION=inicial-terraform -t ${aws_ecr_repository.app.repository_url}:latest ${path.module}/../app",
      "docker push ${aws_ecr_repository.app.repository_url}:latest",
    ])
  }
}
