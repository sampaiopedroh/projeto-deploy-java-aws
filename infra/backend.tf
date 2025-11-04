# O bloco "terraform" é usado para configurar o comportamento do próprio Terraform,
# como as versões de provedores e, neste caso, a configuração do "backend".
terraform {
  # Este bloco "backend" configura a localização onde o Terraform armazenará seu arquivo de estado.
  # O arquivo de estado (terraform.tfstate) é o "cérebro" do Terraform; ele mapeia os recursos do seu
  # código para os recursos reais criados na nuvem.
  # Em vez de armazenar este arquivo crítico localmente (o que o faria ser perdido após cada
  # execução do GitHub Actions), estamos instruindo o Terraform a salvá-lo de forma remota e persistente.
  # "s3" especifica que usaremos um bucket do AWS S3 como nosso backend. Esta é a prática
  # padrão e recomendada para qualquer projeto profissional, seja individual ou em equipe.
  backend "s3" {
    # "bucket" especifica o nome do bucket S3 que irá armazenar o arquivo de estado.
    # Este nome de bucket deve ser GLOBALMENTE único em toda a AWS.
    # IMPORTANTE: Você deve criar este bucket na sua conta AWS antes de executar o `terraform init`.
    # Substitua "meu-projeto-aula-terraform-state" pelo nome exato do seu bucket.
    bucket         = "meu-projeto-aula-terraform-state"

    # "key" é o caminho completo, incluindo o nome do arquivo, para o arquivo de estado dentro do bucket.
    # Pense nisso como o caminho de um arquivo em um sistema de pastas. Aqui, o arquivo
    # `terraform.tfstate` será salvo dentro de uma "pasta" chamada "aula-java".
    key            = "aula-java/terraform.tfstate"

    # "region" especifica a região da AWS onde o seu bucket S3 foi criado.
    # O Terraform precisa saber disso para poder se conectar ao bucket e ler/escrever o arquivo de estado.
    # Esta região deve corresponder à região do seu bucket.
    region         = "us-east-1"

    # "encrypt" é uma configuração de segurança CRÍTICA.
    # Quando definido como "true", ele garante que o arquivo de estado, que pode conter
    # informações sensíveis sobre sua infraestrutura, seja criptografado no lado do servidor
    # quando armazenado no S3. Isso deve ser sempre ativado.
    encrypt        = true
  }
}