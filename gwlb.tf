
resource "aws_lb" "gwlb" {
  name               = "glb"
  load_balancer_type = "gateway"
  subnets            = [ aws_subnet.glbet_subnet.id ] 
  tags = {
    Name = "glb"
  }
}

data "aws_caller_identity" "current" {}

resource "aws_vpc_endpoint_service" "glbes" {
  acceptance_required        = false
  allowed_principals         = [data.aws_caller_identity.current.arn]
  gateway_load_balancer_arns = [aws_lb.gwlb.arn]
  tags = {
    Name = "glbes-endpoint-service"
  }
}

resource "aws_vpc_endpoint" "glbe" {
  service_name      = aws_vpc_endpoint_service.glbes.service_name
  subnet_ids        = [aws_subnet.glbe_subnet.id]
  vpc_endpoint_type = aws_vpc_endpoint_service.glbes.service_type
  vpc_id            = aws_vpc.main.id
  tags = {
    Name = "glbe-endpoint"
  }
}


resource "aws_lb_target_group" "gwlb_tg" {
  name        = "gwlb-target-group"
  port        = 6081
  protocol    = "GENEVE"
  vpc_id      = aws_vpc.glbet.id
  target_type = "ip"

  health_check {
    port     = 80
    protocol = "TCP"
  }
  tags = {
    Name = "glbe-tg"
  }
}

resource "aws_lb_listener" "example" {
  load_balancer_arn = aws_lb.gwlb.id

  default_action {
    target_group_arn = aws_lb_target_group.gwlb_tg.id
    type             = "forward"
  }
    tags = {
    Name = "glbet-listener"
  }
}

resource "aws_lb_target_group_attachment" "instance_attach" {
  target_group_arn = aws_lb_target_group.gwlb_tg.id
  target_id        = aws_instance.fw-ec2.private_ip
}