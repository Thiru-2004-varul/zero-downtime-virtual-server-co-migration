resource "aws_lb" "vmcm_alb" {
  name               = "vmcm-alb"
  load_balancer_type = "application"
  subnets            = aws_subnet.public_subnets[*].id
  security_groups    = [aws_security_group.alb_sg.id]
}
