resource "aws_lb" "vmcm_alb" {
  name               = "vmcm-alb"
  load_balancer_type = "application"
  subnets            = aws_subnet.public_subnets[*].id
  security_groups    = [aws_security_group.alb_sg.id]
  tags = {
    Name = "vmcm-alb"
  }
}

resource "aws_lb_target_group" "vmcm_tg" {
  name     = "vmcm-tg"
  port     = 30007
  protocol = "HTTP"
  vpc_id   = aws_vpc.vmcm_vpc.id

  health_check {
    path                = "/health"
    port                = "30007"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 15
    timeout             = 5
  }

  tags = {
    Name = "vmcm-tg"
  }
}

resource "aws_lb_target_group_attachment" "vmcm_tg_attachment" {
  count            = var.k8s_node_count
  target_group_arn = aws_lb_target_group.vmcm_tg.arn
  target_id        = aws_instance.k8s_nodes[count.index].id
  port             = 30007
}

resource "aws_lb_listener" "vmcm_listener" {
  load_balancer_arn = aws_lb.vmcm_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vmcm_tg.arn
  }
}
