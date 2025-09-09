locals { trust = jsonencode({
  Version="2012-10-17",
  Statement=[{Effect="Allow", Principal={Service="ecs-tasks.amazonaws.com"}, Action="sts:AssumeRole"}]
})}

resource "aws_iam_role" "exec" {
  name               = "${var.name}-exec"
  assume_role_policy = local.trust
}
resource "aws_iam_role_policy_attachment" "exec_attach" {
  role       = aws_iam_role.exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task" {
  name               = "${var.name}-task"
  assume_role_policy = local.trust
}

resource "aws_iam_role_policy" "task_inline" {
  count  = var.policy_json == null ? 0 : 1
  name   = "${var.name}-inline"
  role   = aws_iam_role.task.id
  policy = var.policy_json
}
