resource "aws_ecr_repository" "ecr_repo" {
  name                 = "${var.app_name}-repo"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.common_tags

}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.app_name}-cluster"

  tags = local.common_tags
}

resource "aws_ecs_cluster_capacity_providers" "ecs_capacity_providers" {
  cluster_name = aws_ecs_cluster.ecs_cluster.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }

}

resource "aws_ecs_task_definition" "ecs_service_task_def" {
  family                   = var.app_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = var.app_name
      image     = var.container_image
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    },
  ])

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  tags = local.common_tags
}

resource "aws_ecs_service" "ecs_service" {
  name                               = "${var.app_name}-service"
  cluster                            = aws_ecs_cluster.ecs_cluster.arn
  task_definition                    = aws_ecs_task_definition.ecs_service_task_def.arn
  desired_count                      = 2
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

  # alarms {
  #   enable   = true
  #   rollback = true
  #   alarm_names = [
  #     aws_cloudwatch_metric_alarm.example.alarm_name
  #   ]
  # }

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

  tags = local.common_tags
}

# resource "aws_cloudwatch_log_group" "example" {
#   name = "/ecs/example/service-connect"
# }
