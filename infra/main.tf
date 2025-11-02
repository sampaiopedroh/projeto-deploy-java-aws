variable "ssh_public_key" {
  description = "A chave pública SSH para acessar a instância EC2"
  type        = string
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# 1. Cria a nossa rede privada (Virtual Private Cloud)
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main-vpc"
  }
}

# 2. Cria a porta de saída da nossa rede para a internet
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-igw"
  }
}

# 3. Cria a "rua" dentro da nossa rede onde a máquina vai morar
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true # Importante: Garante que nossa EC2 receba um IP público
  availability_zone       = "us-east-1a" # Pode ser trocado para us-east-1b, etc.
  tags = {
    Name = "main-public-subnet"
  }
}

# 4. Cria a "placa de trânsito" que diz: "para ir para a internet (0.0.0.0/0), use a porta de saída (gateway)"
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# 5. Associa a nossa "rua" (subnet) com a nossa "placa de trânsito" (route table)
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_key_pair" "deploy_key" {
  key_name   = "deploy-key-pair"
  public_key = var.ssh_public_key
}

# 6. Atualiza o Security Group para dizer em qual VPC ele deve ser criado
resource "aws_security_group" "app_sg" {
  name        = "app-security-group"
  description = "Permite acesso HTTP na porta 8080 e SSH na porta 22"
  vpc_id      = aws_vpc.main.id # <-- MUDANÇA IMPORTANTE

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
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
    Name = "app-sg"
  }
}

# 7. Atualiza a Instância EC2 para dizer em qual "rua" (subnet) ela deve ser criada
resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.deploy_key.key_name
  subnet_id              = aws_subnet.main.id # <-- MUDANÇA IMPORTANTE
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y java-17-amazon-corretto
              EOF

  tags = {
    Name = "Servidor-App-Java"
  }
}