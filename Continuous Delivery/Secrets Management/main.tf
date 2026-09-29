# resource "aws_vpc" "main" {
#   cidr_block = "10.1.0.0/16"
#     tags = {
#         Name = "main-vpc"
#     }   
# }    

# resource "aws_subnet" "main" {
#   vpc_id                  = aws_vpc.main.id
#   cidr_block              = "10.1.1.0/24"
#   map_public_ip_on_launch = true

#   tags = {
#     Name = "main-subnet"
#   }
# }

# resource "aws_internet_gateway" "main" {
#   vpc_id = aws_vpc.main.id

#   tags = {
#     Name = "main-igw"
#   }
# }

# resource "aws_route_table" "main" {
#   vpc_id = aws_vpc.main.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.main.id
#   }

#   tags = {
#     Name = "main-rt"
#   }
# }

# resource "aws_route_table_association" "main" {
#   subnet_id      = aws_subnet.main.id
#   route_table_id = aws_route_table.main.id
# }

# resource "aws_security_group" "web_ssh" {
#   name        = "allow-ssh-http"
#   description = "Allow SSH and HTTP inbound"
#   vpc_id      = aws_vpc.main.id

#   ingress {
#     description = "SSH"
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     description = "HTTP"
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "allow-ssh-http"
#   }
# }

# resource "aws_key_pair" "demo" {
#   # ssh-keygen -y -f Demo1.pem > Demo1.pem.pub
#   key_name   = "Demo1"
#   public_key = file("Demo1.pem.pub")
# }

# # data "aws_ami" "ubuntu" {
# #   most_recent = true
# #   owners      = ["099720109477"] # Canonical

# #   filter {
# #     name   = "name"
# #     values = ["ubuntu/images/hvm-ssd/ubuntu-resolute-26.04-amd64-server-*"]
# #   }
# # }

# resource "aws_instance" "demo" {
#   ami                    = "ami-0b6d9d3d33ba97d99"
#   instance_type          = "t3.micro"
#   subnet_id              = aws_subnet.main.id
#   key_name               = aws_key_pair.demo.key_name
#   vpc_security_group_ids = [aws_security_group.web_ssh.id]

#   user_data = <<-EOF
#               #!/bin/bash
#               apt update -y
#               apt install nginx -y
#               echo "Hello World" > /var/www/html/index.html
#               systemctl start nginx
#               systemctl enable nginx
#               EOF

#   tags = {
#     Name = "demo-instance"
#   }
# }

# output "public_ip" {
#   description = "Public IP of the EC2 instance"
#   value       = aws_instance.demo.public_ip
# }

resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "db_secret" {
  name        = "demo/rds/postgres"
  description = "RDS PostgreSQL credentials created using Terraform"
}

resource "aws_secretsmanager_secret_version" "db_secret_value" {
  secret_id = aws_secretsmanager_secret.db_secret.id

  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    engine   = "postgres"
    dbname   = var.db_name
  })
}

resource "aws_security_group" "rds_sg" {
  name        = "demo-postgres-rds-sg"
  description = "Allow PostgreSQL access"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "postgres_db" {
  identifier             = "demo-postgres-db"
  allocated_storage      = 20
  db_name                = var.db_name
  engine                 = "postgres"
  engine_version         = "16"
  instance_class         = "db.t3.micro"
  username               = var.db_username
  password               = random_password.db_password.result
  publicly_accessible    = true
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
} 