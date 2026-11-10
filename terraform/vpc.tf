resource "aws_vpc" "vpc" {
  # checkov:skip=CKV2_AWS_12:Workloads use dedicated security groups; the VPC default security group is not attached.
  # checkov:skip=CKV2_AWS_11:VPC flow logging is not configured in this deployment.
  cidr_block           = "172.32.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

data "aws_availability_zones" "az_available" {
  # checkov:skip=CKV_AWS_394:Select all currently available AZs dynamically to distribute subnets across the region.
  state                  = "available"
  all_availability_zones = true
}

resource "aws_subnet" "public_subnet" {
  # checkov:skip=CKV_AWS_130:These subnets are intentionally public and host the internet-facing load balancer.
  for_each = toset(data.aws_availability_zones.az_available.names)

  vpc_id            = aws_vpc.vpc.id
  availability_zone = each.value
  cidr_block = cidrsubnet(
    aws_vpc.vpc.cidr_block,
    4,
    index(data.aws_availability_zones.az_available.names, each.value)
  )
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_rtb_association" {
  for_each       = aws_subnet.public_subnet
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_security_group" "ecs_service_sg" {
  # checkov:skip=CKV_AWS_382:Tasks require unrestricted outbound access because no NAT or VPC endpoints are configured.
  name        = "${var.app_name}-ecs-sg"
  description = "Allow inbound traffic from the ALB and unrestricted outbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
    description     = "Allow inbound traffic from the ALB on port 80"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow unrestricted outbound traffic"
  }
}


resource "aws_security_group" "alb_sg" {
  # checkov:skip=CKV_AWS_260:The public application currently accepts HTTP on port 80; HTTPS is not configured.
  # checkov:skip=CKV_AWS_382:The public load balancer requires outbound access to its targets and health checks.
  name        = "${var.app_name}-alb-sg"
  description = "Allow inbound traffic from the internet and unrestricted outbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow inbound traffic from the internet on port 80"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow unrestricted outbound traffic"
  }
}

resource "aws_lb_target_group" "ecs_alb_tg" {
  # checkov:skip=CKV_AWS_378:Targets currently serve HTTP on port 80; TLS is not configured between the load balancer and tasks.
  name        = "${var.app_name}-alb-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id
  target_type = "ip"

  health_check {
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 30
    interval            = 60
    matcher             = "200"
  }

}

resource "aws_lb" "ecs_alb" {
  # checkov:skip=CKV_AWS_150:Deletion protection is disabled to allow this deployment's load balancer to be replaced or removed.
  # checkov:skip=CKV_AWS_131:ALB HTTP header dropping is not configured in this deployment.
  # checkov:skip=CKV2_AWS_20:HTTPS redirect is not configured because this deployment has no HTTPS listener.
  # checkov:skip=CKV2_AWS_28:WAF is not included in this deployment.
  name               = "${var.app_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = values(aws_subnet.public_subnet)[*].id

  access_logs {
    bucket  = aws_s3_bucket.s3.id
    prefix  = "alb-access-logs"
    enabled = true
  }

  connection_logs {
    bucket  = aws_s3_bucket.s3.id
    prefix  = "alb-connection-logs"
    enabled = true
  }

  health_check_logs {
    bucket  = aws_s3_bucket.s3.id
    prefix  = "alb-healthcheck-logs"
    enabled = true
  }

  depends_on = [aws_s3_bucket_policy.s3_policy]
}

resource "aws_lb_listener" "alb_listener" {
  # checkov:skip=CKV_AWS_2:The application currently uses HTTP on port 80; HTTPS is not configured.
  # checkov:skip=CKV_AWS_103:TLS policy does not apply because this listener uses HTTP rather than HTTPS.
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_alb_tg.arn
  }

}
