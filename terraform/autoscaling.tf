# resource "aws_appautoscaling_target" "ecs_service" {
#   max_capacity       = 5
#   min_capacity       = var.desired_count
#   resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.ecs_service.name}"
#   scalable_dimension = "ecs:service:DesiredCount"
#   service_namespace  = "ecs"

#   tags = local.common_tags
# }

# resource "aws_appautoscaling_policy" "ecs_cpu_asg_target" {
#   name               = "${var.app_name}-cpu-target-tracking"
#   policy_type        = "TargetTrackingScaling"
#   resource_id        = aws_appautoscaling_target.ecs_service.resource_id
#   scalable_dimension = aws_appautoscaling_target.ecs_service.scalable_dimension
#   service_namespace  = aws_appautoscaling_target.ecs_service.service_namespace


#   target_tracking_scaling_policy_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "ECSServiceAverageCPUUtilization"
#     }
#     target_value       = 60
#     scale_in_cooldown  = 300
#     scale_out_cooldown = 60
#   }
# }

# resource "aws_appautoscaling_policy" "ecs_memory_asg_target" {
#   name               = "${var.app_name}-memory-target-tracking"
#   policy_type        = "TargetTrackingScaling"
#   resource_id        = aws_appautoscaling_target.ecs_service.resource_id
#   scalable_dimension = aws_appautoscaling_target.ecs_service.scalable_dimension
#   service_namespace  = aws_appautoscaling_target.ecs_service.service_namespace

#   target_tracking_scaling_policy_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "ECSServiceAverageMemoryUtilization"
#     }
#     target_value       = 70
#     scale_in_cooldown  = 300
#     scale_out_cooldown = 60
#   }
# }
