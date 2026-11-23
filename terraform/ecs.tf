resource "aws_ecs_cluster" "main" {
  name = "${local.name}-cluster"
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${local.name}-task"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([{
    name      = var.container_name
    image     = "${aws_ecr_repository.app.repository_url}:latest"
    essential = true
    portMappings = [{
      containerPort = var.container_port
      hostPort      = 0
      protocol      = "tcp"
    }]

    logConfiguration = {
      logDriver = "json-file"
      options = {
        max-size = "10m"
        max-file = "3"
      }
    }
  }])
}

resource "aws_ecs_service" "app" {
  name            = "${local.name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count

  launch_type = "EC2"

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }
  ordered_placement_strategy {
    type  = "spread"
    field = "instanceId"
  }

  health_check_grace_period_seconds = 60

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  depends_on = [
    aws_lb_listener.http,
    aws_autoscaling_group.ecs,
    aws_iam_role_policy_attachment.ecs_task_execution,
    terraform_data.initial_image,
  ]
}
