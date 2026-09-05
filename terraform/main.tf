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
