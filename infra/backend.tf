terraform {
  backend "s3" {
    bucket         = "meu-projeto-aula-terraform-state" # <-- SUBSTITUA AQUI
    key            = "aula-java/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}