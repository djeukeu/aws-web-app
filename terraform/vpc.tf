resource "aws_vpc" "vpc" {
  cidr_block           = "172.32.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = local.common_tags
}

data "aws_availability_zones" "az_available" {
  state                  = "available"
  all_availability_zones = true
}

resource "aws_subnet" "public_subnet" {
  for_each = toset(data.aws_availability_zones.az_available.names)

  vpc_id            = aws_vpc.vpc.id
  availability_zone = each.value
  cidr_block = cidrsubnet(
    aws_vpc.vpc.cidr_block,
    8,
    index(data.aws_availability_zones.az_available.names, each.value)
  )
  map_public_ip_on_launch = true

  tags = local.common_tags

}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = local.common_tags
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = local.common_tags

}

resource "aws_route_table_association" "public_subnet_route_association" {
  for_each       = aws_subnet.public_subnet
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_route_table.id

}

resource "aws_lb_target_group" "ecs_alb_tg" {
  name        = "${var.app_name}-alb-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id
  target_type = "ip"

  health_check {
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = local.common_tags
}


resource "aws_security_group" "ecs_service_sg" {
  name        = "${var.app_name}-ecs-sg"
  description = "Allow inbound traffic for alb and all outbound traffic"
  vpc_id      = aws_vpc.vpc.id


  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb-sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_security_group" "alb-sg" {
  name        = "${var.app_name}-alb-sg"
  description = "Allow inbound HTTP traffic and all outbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags

}


resource "aws_lb" "ecs-alb" {
  name               = "${var.app_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb-sg.id]
  subnets            = values(aws_subnet.public_subnet)[*].id

  # access_logs {
  #   bucket  = aws_s3_bucket.lb_logs.id
  #   prefix  = "test-lb"
  #   enabled = true
  # }

  tags = local.common_tags
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.ecs-alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_alb_tg.arn
  }
  tags = local.common_tags
}
