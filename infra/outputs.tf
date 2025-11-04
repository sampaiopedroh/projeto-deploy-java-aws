# O bloco "output" define um valor de saída que o Terraform exibirá no console
# após a conclusão de um `terraform apply`. Outputs são extremamente úteis para
# expor informações importantes sobre a infraestrutura criada, como endereços IP,
# nomes de DNS ou IDs de recursos.

# Neste caso, estamos criando um output chamado "instance_public_ip".
output "instance_public_ip" {
  # "description" é um texto explicativo que descreve o que este output representa.
  # É uma boa prática para documentar o propósito do valor de saída.
  description = "O IP público da instância EC2 criada"

  # "value" é a expressão cujo resultado será o valor do output.
  # Aqui, estamos acessando um atributo do recurso "aws_instance" que definimos no `main.tf`.
  # - `aws_instance.app_server`: Refere-se ao recurso da nossa instância EC2.
  # - `.public_ip`: É o atributo específico da instância EC2 que contém o seu endereço IP público.
  # O GitHub Actions usará este output para saber o endereço do servidor ao qual
  # ele precisa se conectar para fazer o deploy da aplicação.
  value       = aws_instance.app_server.public_ip
}