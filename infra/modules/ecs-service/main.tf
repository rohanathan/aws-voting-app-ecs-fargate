resource "aws_security_group" "ecs" {
  name   = "${var.name}-sg"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "from_alb" {
  count                    = var.attach_to_alb ? 1 : 0
  type                     = "ingress"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs.id
  source_security_group_id = var.alb_sg_id
}

resource "aws_lb_target_group" "tg" {
  count       = var.attach_to_alb ? 1 : 0
  name        = "${var.name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check {
    path = var.health_check_path
    port = var.container_port
  }
}

resource "aws_lb_listener_rule" "rule" {
  count        = var.attach_to_alb ? 1 : 0
  listener_arn = var.listener_arn
  priority     = var.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg[0].arn
  }
  condition {
    path_pattern { values = var.path_patterns }
  }
}

resource "aws_ecs_task_definition" "td" {
  family                   = var.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn
  container_definitions = jsonencode([{
    name         = "app"
    image        = var.image
    essential    = true
    portMappings = [{ containerPort = var.container_port, hostPort = var.container_port, protocol = "tcp" }]
    environment  = [ for k,v in var.environment : { name = k, value = v } ]
    logConfiguration = {
      logDriver = "awslogs",
      options = {
        awslogs-group         = var.log_group
        awslogs-region        = var.region
        awslogs-stream-prefix = var.name
      }
    }
  }])
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}

resource "aws_ecs_service" "svc" {
  name            = "${var.name}-svc"
  cluster         = var.cluster_arn
  task_definition = aws_ecs_task_definition.td.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [ aws_security_group.ecs.id ]
    assign_public_ip = var.assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = var.attach_to_alb ? [1] : []
    content {
      target_group_arn = aws_lb_target_group.tg[0].arn
      container_name   = "app"
      container_port   = var.container_port
    }
  }

}

resource "aws_appautoscaling_target" "this" {
  count              = var.enable_autoscaling ? 1 : 0
  max_capacity       = var.max_count
  min_capacity       = var.min_count
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.svc.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  count       = var.enable_autoscaling ? 1 : 0
  name        = "${var.name}-cpu-target"
  policy_type = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this[0].resource_id
  scalable_dimension = aws_appautoscaling_target.this[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.this[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.cpu_target
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}
