# ==============================================================================
# VARIÁVEIS DE ENTRADA (INPUTS)
# ==============================================================================

# O bloco "variable" define uma variável de entrada que pode ser passada para o Terraform
# no momento da execução. Isso torna nosso código reutilizável e evita colocar
# valores sensíveis ou que mudam com frequência diretamente no código.
variable "ssh_public_key" {
  # "description" é um texto de ajuda que explica o propósito da variável.
  description = "A chave pública SSH para acessar a instância EC2"
  # "type" define o tipo de dado esperado para a variável (string, number, bool, etc.).
  type        = string
}

# ==============================================================================
# FONTES DE DADOS (DATA SOURCES)
# ==============================================================================

# O bloco "data" é usado para buscar informações de uma fonte externa (neste caso, a API da AWS).
# Ele não cria recursos, apenas lê dados existentes para que possamos usá-los em nosso código.
data "aws_ami" "amazon_linux_2" {
  # "most_recent = true" instrui o Terraform a encontrar a AMI mais recente que corresponda aos filtros.
  # Isso garante que sempre usemos a imagem mais atualizada e segura sem precisar atualizar o código.
  most_recent = true
  # "owners" filtra as AMIs pelo ID da conta da AWS que as publicou. "amazon" é o alias para as AMIs oficiais.
  owners      = ["amazon"]

  # O bloco "filter" nos permite especificar critérios para a busca da AMI.
  filter {
    # Filtra pelo campo "name" da AMI.
    name   = "name"
    # O padrão "amzn2-ami-hvm-*-x86_64-gp2" corresponde ao nome padrão das AMIs Amazon Linux 2.
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# ==============================================================================
# RECURSOS DE REDE (NETWORKING)
# ==============================================================================

# O bloco "resource" é a principal construção do Terraform. Ele define um objeto de infraestrutura
# que o Terraform irá criar, gerenciar e destruir.

# Este recurso cria uma Virtual Private Cloud (VPC), que é a sua rede privada e isolada na AWS.
# É o contêiner fundamental para todos os outros recursos de rede e computação.
resource "aws_vpc" "main" {
  # "cidr_block" define o intervalo de endereços IP principal para a VPC.
  cidr_block = "10.0.0.0/16"
  # "tags" são metadados (chave-valor) que ajudam a identificar e organizar os recursos na AWS.
  tags = {
    Name = "main-vpc"
  }
}

# Cria um Internet Gateway (IGW), que funciona como a "porta de entrada e saída" da sua VPC para a internet.
# Sem um IGW, os recursos dentro da VPC não podem se comunicar com o mundo exterior.
resource "aws_internet_gateway" "gw" {
  # "vpc_id" associa o Internet Gateway à nossa VPC principal. A sintaxe `aws_vpc.main.id`
  # cria uma dependência explícita, dizendo ao Terraform para criar a VPC antes do IGW.
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-igw"
  }
}

# Cria uma Subnet (sub-rede), que é uma subdivisão da nossa VPC.
# É dentro das subnets que lançamos recursos como as instâncias EC2.
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  # O CIDR block da subnet deve ser um subconjunto do CIDR block da VPC.
  cidr_block              = "10.0.1.0/24"
  # "map_public_ip_on_launch = true" é crucial. Isso garante que qualquer instância EC2
  # lançada nesta subnet receba automaticamente um endereço IP público, tornando-a acessível pela internet.
  map_public_ip_on_launch = true
  # Define em qual Zona de Disponibilidade (data center físico) a subnet será criada.
  availability_zone       = "us-east-1a"
  tags = {
    Name = "main-public-subnet"
  }
}

# Cria uma Route Table (tabela de rotas), que funciona como um "GPS" ou "roteador virtual".
# Ela define as regras de tráfego para determinar para onde o tráfego de rede da subnet deve ir.
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  # O bloco "route" define uma regra específica de roteamento.
  route {
    # "0.0.0.0/0" é um endereço especial que significa "qualquer tráfego destinado à internet".
    cidr_block = "0.0.0.0/0"
    # Esta linha diz: "envie todo o tráfego destinado à internet para o nosso Internet Gateway".
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Associa a nossa tabela de rotas pública à nossa subnet.
# É este recurso que efetivamente aplica as regras de roteamento à subnet.
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.public_rt.id
}

# ==============================================================================
# RECURSOS DE SEGURANÇA E COMPUTAÇÃO (SECURITY & COMPUTE)
# ==============================================================================

# Cria um Key Pair na AWS. Este recurso não gera uma chave; em vez disso, ele registra a
# chave pública que fornecemos, permitindo que a AWS a associe a instâncias EC2
# para autenticação segura via SSH.
resource "aws_key_pair" "deploy_key" {
  # "key_name" é o nome que a chave terá dentro da AWS.
  key_name   = "deploy-key-pair"
  # "public_key" recebe o conteúdo da chave pública passada pela variável `ssh_public_key`.
  public_key = var.ssh_public_key
}

# Cria um Security Group, que atua como um firewall virtual para nossa instância EC2.
# Ele controla o tráfego de entrada (ingress) e saída (egress).
resource "aws_security_group" "app_sg" {
  name        = "app-security-group"
  description = "Permite acesso HTTP na porta 8080 e SSH na porta 22"
  vpc_id      = aws_vpc.main.id

  # Bloco "ingress" define uma regra para tráfego de ENTRADA.
  # Esta regra permite o acesso via SSH (porta 22) para que o GitHub Actions possa se conectar.
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Permite a conexão de qualquer endereço IP.
  }

  # Esta regra permite o acesso à nossa aplicação Java na porta 8080.
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Permite que qualquer pessoa acesse a aplicação.
  }

  # Bloco "egress" define uma regra para tráfego de SAÍDA.
  # Esta regra permite que a instância EC2 se conecte a qualquer lugar na internet (ex: para baixar atualizações).
  egress {
    from_port   = 0             # Todas as portas
    to_port     = 0
    protocol    = "-1"          # Todos os protocolos
    cidr_blocks = ["0.0.0.0/0"] # Para todos os destinos
  }

  tags = {
    Name = "app-sg"
  }
}

# Finalmente, este recurso cria a instância EC2 (o nosso servidor virtual).
# Ele une todos os recursos de rede e segurança que criamos anteriormente.
resource "aws_instance" "app_server" {
  # "ami" especifica o ID da Amazon Machine Image a ser usada. Pegamos dinamicamente do nosso `data` block.
  ami                    = data.aws_ami.amazon_linux_2.id
  # "instance_type" define o "tamanho" da máquina. "t2.micro" está incluído na Camada Gratuita da AWS.
  instance_type          = "t2.micro"
  # Associa o nosso Key Pair à instância, permitindo o acesso SSH com a chave privada correspondente.
  key_name               = aws_key_pair.deploy_key.key_name
  # Coloca a instância dentro da nossa subnet pública.
  subnet_id              = aws_subnet.main.id
  # Anexa o nosso Security Group (firewall) à instância.
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  # "user_data" é um script de inicialização que é executado apenas na primeira vez que a instância é criada.
  # É perfeito para instalar dependências essenciais.
  user_data = <<-EOF
              #!/bin/bash
              # Atualiza todos os pacotes do sistema.
              yum update -y
              # Instala o Java 17 (Amazon Corretto, uma distribuição do OpenJDK).
              yum install -y java-17-amazon-corretto
              EOF

  tags = {
    Name = "Servidor-App-Java"
  }
}