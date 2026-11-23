data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
}

resource "aws_iam_role" "ecs_instance" {
  name = "${local.name}-ecs-instance"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_instance" {
  role       = aws_iam_role.ecs_instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs_instance_ssm" {
  role       = aws_iam_role.ecs_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ecs_instance" {
  name = "${local.name}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance.name
}

resource "aws_security_group" "ecs_instances" {
  name        = "${local.name}-ecs-instances-sg"
  description = "Instancias EC2 del cluster ECS: puertos dinamicos solo desde el ALB"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description     = "Puertos dinamicos de los contenedores"
    from_port       = 32768
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Salida a internet (ECS y ECR)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name}-ecs-instances-sg" }
}

resource "aws_launch_template" "ecs" {
  name_prefix   = "${local.name}-lt-"
  image_id      = data.aws_ssm_parameter.ecs_ami.value
  instance_type = var.instance_type

  iam_instance_profile {
    arn = aws_iam_instance_profile.ecs_instance.arn
  }

  # IP pública para que las instancias lleguen a ECS y ECR (la VPC no tiene NAT Gateway)
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ecs_instances.id]
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  # replace() quita los \r (CRLF de Windows): con "#!/bin/bash\r" el script no se ejecutaria
  user_data = base64encode(replace(<<-EOF
    #!/bin/bash
    echo "ECS_CLUSTER=${aws_ecs_cluster.main.name}" >> /etc/ecs/ecs.config
    echo "ECS_ENABLE_CONTAINER_METADATA=true" >> /etc/ecs/ecs.config
  EOF
  , "\r", ""))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name     = "${local.name}-ecs-instance"
      Proyecto = var.project_name
    }
  }
}

resource "aws_autoscaling_group" "ecs" {
  name                = "${local.name}-asg"
  vpc_zone_identifier = data.aws_subnets.public.ids # reparte las instancias entre AZs
  min_size            = var.instance_count
  max_size            = var.instance_count
  desired_capacity    = var.instance_count
  health_check_type   = "EC2"
  force_delete        = true # permite terraform destroy aunque haya instancias

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${local.name}-ecs-instance"
    propagate_at_launch = true
  }
}
