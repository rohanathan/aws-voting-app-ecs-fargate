output "service_name"  { value = aws_ecs_service.svc.name }
output "target_group"  { value = var.attach_to_alb ? aws_lb_target_group.tg[0].arn : null }
