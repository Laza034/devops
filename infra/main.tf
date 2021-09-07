terraform {
  required_providers {
    aws = ">= 3.5"
  }
  
  required_version = ">= 1.0"
}

provider "aws" {
    region = "eu-central-1"
    profile = "default"
}

# DEFINING DATA BLOCKS TO BE USED FOR FETCHING NECESSARY VALUES


data "aws_availability_zones" "all" {}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.default.id
}

# CREATING LAUNCH TEMPLATE FOR ASG AND BOOTSTRAPPING IT TO ENABLE DOCKER APPLICATION ON STARTUP
# OPTING FOR LAUNCH TEMPLATE OVER LAUNCH CONFIGURATION SINCE IT SUPOORTS VERSIONING 
# TEMLATE WILL BE USING SPOT INSTANCES

resource "aws_launch_template" "config" {
  name = "server_template"

  # block_device_mappings {
  #   device_name = "/dev/sda1"
  #   ebs {
  #     volume_size = 8
  #     delete_on_termination = true
  #   }
  # }
  
  # ebs_optimized = true

  image_id = "ami-07df274a488ca9195"

  #  instance_initiated_shutdown_behavior = "terminate"

  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price = 0.5
    }
  }

  instance_type = "t2.micro"

  monitoring {
    enabled = true
  }

  

  vpc_security_group_ids = [aws_security_group.servers.id]

  user_data = filebase64("user_data.sh")
}

# USING AUTOSCALING GROUPS TO PROVADY SCALABILITY AND RESILIANCE OF THE STACK IN CSE OF INCREASED TRAFFIC
# ALL SPAWN INSTANCES WILL BE PART OF SPECIFIED TARGET GROUP

resource "aws_autoscaling_group" "devops" {
  name                 = "autoscaling_devops"
  #availability_zones   = [data.aws_availability_zones.all.names]
  vpc_zone_identifier  = data.aws_subnet_ids.all.ids
  min_size             = 2
  max_size             = 2
  # desired_capacity     = 2
  health_check_type    = "ELB"
  target_group_arns    = [aws_lb_target_group.servers.arn]
  
  launch_template {
    id      = aws_launch_template.config.id
    version = "$Latest"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# APPLICATION LOAD BALANCER CONFIGURED TO FORWARD HTTP TRAFFIC TO TARGET GROUP 

resource "aws_lb" "awsalb" {
  name                       = "my-aws-loadbalancer"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = data.aws_subnet_ids.all.ids
  enable_deletion_protection = false

  tags = {
    Name     = "My AWS ALB Load Balancer"
  }
}


resource "aws_lb_target_group" "servers" {
  name     = "servers"
  port     = 8080
  protocol = "HTTP"
  target_type = "instance"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    interval            = 30
    path                = "/"
    port                = 8080
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    protocol            = "HTTP"
    matcher             = "200,202"
  }
}


resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.awsalb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.servers.arn
      }

    }

  }
}

# SECURITY GROUPS AND RULES. AS BEST PRACTICE SECURITY GROUPS ARE CREATED BEFRO RULES TO AVOID CYCLE ERROR.
# SECURITY GROUPS ALB AND SERVERS ARE CONFIGURED AS AWS BEST PRACTICE TO MUTUAL ALLOW EACH OTHER TRAFFIC.

resource "aws_security_group" "alb"{
    name = "lbsg"
    description = "My alb sec group"
    vpc_id      = data.aws_vpc.default.id

}


resource "aws_security_group_rule" "web-access" {
    type = "ingress"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_group_id = aws_security_group.alb.id
    cidr_blocks      = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ingress-from-servers" {
    type = "ingress"
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    security_group_id = aws_security_group.alb.id
    source_security_group_id = aws_security_group.servers.id
}

resource "aws_security_group_rule" "egress-alb" {
    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    security_group_id = aws_security_group.alb.id
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
}

resource "aws_security_group" "servers"{
    name = "serverssg"
    description = "My asg sec group"
    vpc_id      = data.aws_vpc.default.id

}    

# MANAGEMENT RULE WAS SET FOR TESTING PURPUSES ALTHOUG IT SHOULD BE ACCESIBLE ONLY FROM INSIDE NETWORK EX BASTION.

resource "aws_security_group_rule" "management" {
    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    security_group_id = aws_security_group.servers.id
    cidr_blocks      = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb-traffic" {
    type = "ingress"
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    security_group_id = aws_security_group.servers.id
    source_security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb-traffic80" {
    type = "ingress"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_group_id = aws_security_group.servers.id
    source_security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "egress-servers" {
    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    security_group_id = aws_security_group.servers.id
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
}

# SETTING UP ROUTE53 PUBLIC HOSTED ZONE AND DNS ALIAS A RECORD TO POINT TRAFFIC TO LOAD BALANCER DNS NAME.

resource "aws_route53_zone" "dopestartup" {
  name = "dopestartup.io"
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.dopestartup.zone_id
  name    = "dopestartup.io"
  type    = "A"

  alias {
    name                   = aws_lb.awsalb.dns_name
    zone_id                = aws_lb.awsalb.zone_id
    evaluate_target_health = true
  }
}