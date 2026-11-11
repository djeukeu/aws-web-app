resource "aws_appautoscaling_target" "ecs_asg_target" {
  max_capacity       = 5
  min_capacity       = var.desired_count
  resource_id        = "service/${aws_ecs_service.ecs_service.cluster}/${aws_ecs_service.ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

}

resource "aws_appautoscaling_policy" "ecs_cpu_asg_policy" {
  name               = "${var.app_name}-cpu-target-tracking"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_asg_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_asg_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_asg_target.service_namespace


  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 75
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_policy" "ecs_memory_asg_policy" {
  name               = "${var.app_name}-memory-target-tracking"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_asg_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_asg_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_asg_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = 85
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

