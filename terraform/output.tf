output "ecr_repo_name" {
  value       = aws_ecr_repository.ecr_repo.name
}

# output "alb_dn_name" {
#   value = {
#     name = aws_lb.ecs_alb.dns_name
#   }
# }
