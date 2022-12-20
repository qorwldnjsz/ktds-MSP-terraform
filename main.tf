provider "aws" {
  region = "ap-northeast-2"
}
# Configure the AWS Provider
resource "aws_vpc" "my-vpc" {
  cidr_block = "10.0.0.0/16"
}
# Create Web Public Subnet
resource "aws_subnet" "web-subnet-1" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true
}
resource "aws_subnet" "web-subnet-2" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = true
}
# Create Application Public Subnet
resource "aws_subnet" "application-subnet-1" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = "10.0.11.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = false
}
# Create Database Private Subnet
resource "aws_subnet" "database-subnet-1" {
  vpc_id            = aws_vpc.my-vpc.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = "ap-northeast-2a"
}

# aws_key_pair resource 설정
resource "aws_key_pair" "terraform-key-pair" {
# 등록할 key pair의 name
key_name   = "terraform-key-pair"  
# public_key = "{.pub 파일 내용}"
public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDwihq9hjhxN6Kt8mbKm5to/Rp0rf86+CzRuEZXK4LVuC9J/ZHjKrY4HjJN0KbtFvBQJqwQLWbgem7JPn7j+TEiGfRACciqs5reH+zA23ODTJ0aqV18QJnnTmI2T/vipHS7+DECY0ySxZF5X43/wl5qO6W1tfS3I1W2kXB/EK6OEUtAH1RoUswsnYOPCE8+WCol/+YxEsDPaNqlS3oU7/0qeyvW58uj+9K9LHQShpn6D4OW7JfQpWN2bbxvExzelxChYeDVBn4lO/RCU2p/TkTHnnC7ngrufBvHK/l6blKjQqhitz9jrZHhTjMTBaUq4nXpa220u5uisrQjFUyn/ZmF4zMLY5JOJ2Nv9nMWjQbcL21kwXBBDpfAHBCR/D1X1kVRTeO3WIiAqCu4CSUPgD3IsDlpeGwD7sEXClQ1r01M2zJCdNKV71RSv47MITdFdr6ind4K8kTiJ20p/nxHiX/PrPJmVUNGxZ0hplBIivGE8jM8xRAunTnw1tf/E7xf1wU= baekjiwon@Jiwonui-MacBookPro.local"

tags = {
	description = "terraform key pair import"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my-vpc.id
  tags = {
    User = "Terraform"
    Name = "Demo IGW"
  }
}

# Create Web layber route table
resource "aws_route_table" "web-rt" {
  vpc_id = aws_vpc.my-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    User = "Terraform"
    Name = "WebRT"
  }
}

# Create Web Subnet association with Web route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.web-subnet-1.id
  route_table_id = aws_route_table.web-rt.id
}
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.web-subnet-2.id
  route_table_id = aws_route_table.web-rt.id
}

#Create EC2 Instance
resource "aws_instance" "web-1" {
  ami                    = "ami-0f2c95e9fe3f8f80e"
  instance_type          = "t2.micro"
  availability_zone      = "ap-northeast-2a"
  vpc_security_group_ids = [aws_security_group.webserver-sg.id]
  subnet_id              = aws_subnet.web-subnet-1.id
  key_name   = "terraform-key-pair"  
  tags = {
    User = "Terraform"
    Name = "Web Server"
  }
}
resource "aws_instance" "web-2" {
  ami                    = "ami-0f2c95e9fe3f8f80e"
  instance_type          = "t2.micro"
  availability_zone      = "ap-northeast-2c"
  vpc_security_group_ids = [aws_security_group.webserver-sg.id]
  subnet_id              = aws_subnet.web-subnet-2.id
  key_name   = "terraform-key-pair"  
  tags = {
    User = "Terraform"
    Name = "Web Server"
  }
}
resource "aws_instance" "was-1" {
  ami                    = "ami-0f2c95e9fe3f8f80e"
  instance_type          = "t2.micro"
  availability_zone      = "ap-northeast-2a"
  vpc_security_group_ids = [aws_security_group.wasserver-sg.id]
  subnet_id              = aws_subnet.application-subnet-1.id
  key_name   = "terraform-key-pair"  
  tags = {
    User = "Terraform"
    Name = "WAS Server"
  }
}
resource "aws_instance" "db-1" {
  ami                    = "ami-0f2c95e9fe3f8f80e"
  instance_type          = "t2.micro"
  availability_zone      = "ap-northeast-2a"
  vpc_security_group_ids = [aws_security_group.database-sg.id]
  subnet_id              = aws_subnet.database-subnet-1.id
  key_name   = "terraform-key-pair"  
  tags = {
    User = "Terraform"
    Name = "DB Server"
  }
}
# Create Web Security Group
resource "aws_security_group" "web-sg" {
  name        = "Web-SG"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.my-vpc.id
  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    User = "Terraform"
    Name = "Web-SG"
  }
}
# Create Web Security Group
resource "aws_security_group" "webserver-sg" {
  name        = "Webserver-SG"
  description = "Allow inbound traffic from ALB"
  vpc_id      = aws_vpc.my-vpc.id
  ingress {
    description     = "Allow traffic from web layer"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web-sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    User = "Terraform"
    Name = "Webserver-SG"
  }
}
# Create Application Security Group
resource "aws_security_group" "wasserver-sg" {
  name        = "Wasserver-SG"
  description = "Allow inbound traffic from web server"
  vpc_id      = aws_vpc.my-vpc.id
  ingress {
    description     = "Allow traffic from web server"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.webserver-sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    User = "Terraform"
    Name = "Wasserver-SG"
  }
}
# Create Database Security Group
resource "aws_security_group" "database-sg" {
  name        = "Database-SG"
  description = "Allow inbound traffic from application layer"
  vpc_id      = aws_vpc.my-vpc.id
  ingress {
    description     = "Allow traffic from application layer"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.webserver-sg.id]
  }
  egress {
    from_port   = 32768
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    User = "Terraform"
    Name = "Database-SG"
  }
}

# Create Bastion server Security Group
resource "aws_security_group" "bastion-sg" {
  name        = "Bastion-SG"
  description = "Allow inbound traffic from Baston server layer"
  vpc_id      = aws_vpc.my-vpc.id
  ingress {
    description     = "Allow traffic from application layer"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.webserver-sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    User = "Terraform"
    Name = "Bastion-SG"
  }
}
resource "aws_lb" "external-elb" {
  name               = "External-LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web-sg.id]
  subnets            = [aws_subnet.web-subnet-1.id, aws_subnet.web-subnet-2.id]
}
resource "aws_lb_target_group" "external-elb" {
  name     = "ALB-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my-vpc.id
}
resource "aws_lb_target_group_attachment" "external-elb1" {
  target_group_arn = aws_lb_target_group.external-elb.arn
  target_id        = aws_instance.web-1.id
  port             = 80
  depends_on = [
    aws_instance.web-1,
  ]
}
resource "aws_lb_target_group_attachment" "external-elb2" {
  target_group_arn = aws_lb_target_group.external-elb.arn
  target_id        = aws_instance.web-2.id
  port             = 80
  depends_on = [
    aws_instance.web-2,
  ]
}
resource "aws_lb_listener" "external-elb" {
  load_balancer_arn = aws_lb.external-elb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.external-elb.arn
  }
}
output "lb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.external-elb.dns_name
}
