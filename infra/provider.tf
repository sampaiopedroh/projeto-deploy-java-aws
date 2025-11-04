# Este bloco principal "terraform" é usado para configurar o comportamento do próprio Terraform,
# como as versões necessárias de provedores (providers) e a configuração do backend.
terraform {
  # O bloco "required_providers" declara quais provedores este projeto Terraform necessita para funcionar.
  # É uma boa prática para garantir que todos que executarem este código usem as mesmas versões de provedores.
  required_providers {
    # Aqui, declaramos que precisamos do provedor "aws".
    aws = {
      # "source" especifica a localização oficial do provedor no Registro do Terraform.
      # "hashicorp/aws" é o identificador do provedor oficial da AWS mantido pela HashiCorp.
      source  = "hashicorp/aws"
      # "version" define uma restrição de versão para o provedor. Isso evita que atualizações
      # automáticas com mudanças radicais (breaking changes) quebrem seu código.
      # "~> 5.0" significa "qualquer versão 5.x que seja 5.0 ou superior", como 5.1, 5.2, mas não a 6.0.
      version = "~> 5.0"
    }
  }
}

# Este bloco "provider" configura um provedor específico que foi declarado acima.
# Neste caso, estamos configurando o provedor "aws".
provider "aws" {
  # O argumento "region" é a configuração mais importante. Ele diz ao provedor da AWS
  # em qual região geográfica todos os recursos (como instâncias EC2, Security Groups, etc.)
  # devem ser criados por padrão.
  # "us-east-1" corresponde à região Leste dos EUA (N. Virgínia).
  region = "us-east-1"
}