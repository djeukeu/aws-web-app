data "aws_caller_identity" "current" {}

resource "aws_ecr_repository" "ecr_repo" {
  # checkov:skip=CKV_AWS_136:The repository uses ECR-managed encryption; a customer-managed KMS key is not configured.
  name                 = "${var.app_name}-repo"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.app_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enhanced"
  }
}

resource "aws_ecs_task_definition" "ecs_service_task_def" {
  family                   = "${var.app_name}-task-def"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name                   = var.app_name
      image                  = var.container_image
      cpu                    = 256
      memory                 = 512
      essential              = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_log_group.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    },
  ])

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

}

resource "aws_ecs_service" "ecs_service" {
  # checkov:skip=CKV_AWS_333:This deployment uses public subnets without a NAT gateway, so tasks require public IPs for outbound access.
  name                               = "${var.app_name}-service"
  cluster                            = aws_ecs_cluster.ecs_cluster.arn
  task_definition                    = aws_ecs_task_definition.ecs_service_task_def.arn
  desired_count                      = var.desired_count
  availability_zone_rebalancing      = "ENABLED"
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  force_delete                       = true
  launch_type                        = "FARGATE"

  network_configuration {
    subnets          = values(aws_subnet.public_subnet)[*].id
    security_groups  = [aws_security_group.ecs_service_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_alb_tg.arn
    container_name   = var.app_name
    container_port   = 80
  }

  sigint_rollback       = true
  wait_for_steady_state = true

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  depends_on = [aws_lb_listener.alb_listener]
}
