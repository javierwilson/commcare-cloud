# This module will build out a bastion instance using the G2 custom image.
# NOTE: This image needs to be shared from the G2 account.

resource aws_instance "server" {
  ami                    = "${var.bastion_image}"
  instance_type          = "${var.bastion_instance_type}"
  subnet_id              = "${var.instance_subnet}"
  key_name               = "g2-access"
  vpc_security_group_ids = ["${var.g2-access-sg}","${aws_security_group.bastion-server-sg.id}"]
  source_dest_check      = false
  root_block_device {
    volume_size           = 20
    volume_type           = "gp2"
    delete_on_termination = true
  }
  tags {
    Name        = "${var.company}-bastion"
    Environment = "${var.company}"
    Service     = "bastion"
  }
  user_data = <<-EOF
    #!/bin/bash
    hostnamectl set-hostname "${var.company}-bastion"
    yum update -y
    reboot
    EOF
}

######## Target Group ########
#resource "aws_lb_target_group" "bastion_tg" {
#  name     = "tf-bastion-tg"
#  port     = 8080
#  protocol = "HTTP"
#  vpc_id   = "${var.vpc_id}"
#  health_check {
#    path     = "/login"
#    timeout  = 2
#    interval = 5
#  }
#}

# Define how the target group connects to the ALB and the bastion instance
#resource "aws_lb_target_group_attachment" "bastion_attach" {
  #target_group_arn = "${aws_lb_target_group.bastion_tg.arn}"
  #target_id        = "${aws_instance.bastion_host.id}"
  #port             = 8080
#}
#
# Define the security group for inbound traffic to the bastion server.
resource "aws_security_group" "bastion-server-sg" {
  name        = "bastion-sg"
  description = "Allow traffic to access bastion server"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
#    security_groups = ["${var.openvpn-access-sg}"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

# If DNS hosting in Route 53
# # Setup DNS entry for bastion server
# resource "aws_route53_record" "bastion_record" {
#   zone_id = "${var.dns_zone_id}"
#   name    = "bastion-ec2.${var.dns_domain}"
#   type    = "A"
#   ttl     = "3600"
#   records = ["${aws_instance.bastion_host.private_ip}"]
# }
