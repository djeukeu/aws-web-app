output "ecr_repo_name" {
  value = {
    name = aws_ecr_repository.ecr_repo.name
  }
}
