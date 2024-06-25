# Create a VPC
resource "aws_vpc" "terraform-vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create subnets
resource "aws_subnet" "terraform-subnet1" {
  vpc_id     = aws_vpc.terraform-vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone =  "us-east-1a"
  map_public_ip_on_launch = "true"
}

resource "aws_subnet" "terraform-subnet2" {
  vpc_id     = aws_vpc.terraform-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = "true"
}

# Create an Internet Gateway
resource "aws_internet_gateway" "terraform-igw" {
  vpc_id = aws_vpc.terraform-vpc.id
}


# Create a Route Table
resource "aws_route_table" "terraform-rt" {
  vpc_id = aws_vpc.terraform-vpc.id

  route{
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform-igw.id
  }
}

# Associate Route Table with Subnets
resource "aws_route_table_association" "terraform-rt-ass1" {
  subnet_id      = aws_subnet.terraform-subnet1.id
  route_table_id = aws_route_table.terraform-rt.id
}

resource "aws_route_table_association" "terraform-rt-ass2" {
  subnet_id      = aws_subnet.terraform-subnet2.id
  route_table_id = aws_route_table.terraform-rt.id
}

# Create a Security Group
resource "aws_security_group" "tf-security-group" {
  name        = "allow_tls"
  vpc_id      = aws_vpc.terraform-vpc.id
}

# Ingress rules for the Security Group
resource "aws_security_group_rule" "ingress_http" {
  type            = "ingress"
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]
  security_group_id = aws_security_group.tf-security-group.id
}

resource "aws_security_group_rule" "ingress_ssh" {
  type            = "ingress"
  from_port       = 22
  to_port         = 22
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]
  security_group_id = aws_security_group.tf-security-group.id
}

# Egress rule for the Security Group
resource "aws_security_group_rule" "egress_all" {
  type            = "egress"
  from_port       = 0
  to_port         = 0
  protocol        = "-1"
  cidr_blocks     = ["0.0.0.0/0"]
  security_group_id = aws_security_group.tf-security-group.id
}

# create s3 bucket
resource "aws_s3_bucket" "rak_tf" {
  bucket = "rakesh-anumula-tf"
}
  
# Launch  EC2 instances
resource "aws_instance" "instance1" {
  ami           = "ami-04b70fa74e45c3917"
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.tf-security-group.id]
  subnet_id = aws_subnet.terraform-subnet1.id
  user_data              = base64encode(file("userdata1.sh"))
}

resource "aws_instance" "instance2" {
  ami           = "ami-04b70fa74e45c3917"
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.tf-security-group.id]
  subnet_id = aws_subnet.terraform-subnet2.id
  user_data              = base64encode(file("userdata2.sh"))
}

# create load balancer
resource "aws_lb" "myloadbalancer" {
  name               = "tf-loadbalancerb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.tf-security-group.id]
  subnets            = [aws_subnet.terraform-subnet1.id, aws_subnet.terraform-subnet2.id]
}

#create target group for load balancer
resource "aws_lb_target_group" "tg" {
  name     = "tf-targetgroup"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.terraform-vpc.id

  health_check {
    path = "/"
    port = "traffic-port"
  }
}

# attach instances to target group
resource "aws_lb_target_group_attachment" "attach1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.instance1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "attach2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.instance2.id
  port             = 80
}

# create listeners for target groups
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.myloadbalancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.tg.arn
    type             = "forward"
  }
}

output "loadbalancerdns" {
  value = aws_lb.myloadbalancer.dns_name
}

