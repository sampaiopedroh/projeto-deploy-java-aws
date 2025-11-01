# Projeto de Deploy Automatizado: Java + AWS com Terraform e GitHub Actions

Este é um projeto de estudo completo que demonstra a criação de um pipeline de CI/CD (Integração e Entrega Contínua) para implantar uma aplicação Java (Spring Boot) em uma instância EC2 na AWS. Toda a infraestrutura é gerenciada como código usando Terraform e o processo é totalmente automatizado pelo GitHub Actions.

## ✨ Funcionalidades Principais

-   **Infraestrutura como Código (IaC):** A infraestrutura na AWS (instância EC2, Security Group) é provisionada e gerenciada pelo Terraform.
-   **Automação de CI/CD:** O pipeline é acionado a cada `push` na branch `main`.
-   **Build & Test:** A aplicação Java é compilada e empacotada automaticamente.
-   **Deploy Contínuo:** O artefato `.jar` da aplicação é copiado para a instância EC2 e a aplicação é reiniciada a cada novo deploy.
-   **Banco de Dados Efêmero:** A aplicação utiliza um banco de dados SQLite que é recriado e populado com dados iniciais a cada inicialização, perfeito para ambientes de teste e desenvolvimento.
-   **Custo Zero:** O projeto utiliza exclusivamente os serviços da camada gratuita (Free Tier) da AWS.

---

## 🛠️ Tecnologias Utilizadas

-   **Linguagem:** Java 17
-   **Framework:** Spring Boot 3
-   **Banco de Dados:** SQLite
-   **Build:** Maven
-   **Cloud:** Amazon Web Services (AWS)
    -   EC2 (Elastic Compute Cloud)
    -   IAM (Identity and Access Management)
-   **Infraestrutura como Código:** Terraform
-   **CI/CD:** GitHub Actions

---

## 🚀 Como Funciona o Pipeline

1.  **Gatilho (Push):** Um desenvolvedor envia um novo commit para a branch `main`.
2.  **Build (GitHub Actions):** O GitHub Actions inicia um job que:
    -   Faz o checkout do código.
    -   Configura o ambiente Java.
    -   Compila o código e gera o arquivo `.jar` executável.
3.  **Infraestrutura (GitHub Actions + Terraform):**
    -   O job se autentica na AWS usando credenciais seguras.
    -   O Terraform é inicializado e executa um `apply` para criar ou garantir que a infraestrutura (EC2 e Security Group) esteja no estado desejado.
4.  **Deploy (GitHub Actions):**
    -   O arquivo `.jar` é copiado via SCP para a instância EC2.
    -   Um comando SSH é executado na instância para parar a versão antiga da aplicação (se houver) e iniciar a nova.
5.  **Pronto!** A nova versão da aplicação está no ar, com o banco de dados recriado e populado.

---

## ⚙️ Configuração Prévia

Antes de rodar este projeto, você precisará de:

1.  **Conta na AWS:** [aws.amazon.com](https://aws.amazon.com/)
2.  **Conta no GitHub:** [github.com](https://github.com/)
3.  **Um par de chaves SSH:** Gere um com o comando `ssh-keygen -t rsa -b 4096 -f deploy_key`. Isso criará dois arquivos: `deploy_key` (chave privada) e `deploy_key.pub` (chave pública).

### Configurando os Segredos no GitHub

No seu repositório do GitHub, vá para `Settings > Secrets and variables > Actions` e crie os seguintes segredos:

-   `AWS_ACCESS_KEY_ID`: O ID da chave de acesso do seu usuário IAM.
-   `AWS_SECRET_ACCESS_KEY`: A chave de acesso secreta do seu usuário IAM.
-   `SSH_PRIVATE_KEY`: O conteúdo completo do seu arquivo de chave privada (`deploy_key`).
-   `SSH_PUBLIC_KEY`: O conteúdo completo do seu arquivo de chave pública (`deploy_key.pub`).

---

## ▶️ Como Executar

Com os segredos configurados, o processo é simples:

1.  Clone este repositório.
2.  Faça qualquer alteração no código-fonte da aplicação (por exemplo, em `src/main/resources/data.sql`).
3.  Execute os comandos:
    ```bash
    git add .
    git commit -m "Minha primeira alteração"
    git push origin main
    ```
4.  Vá para a aba "Actions" no seu repositório do GitHub e acompanhe a execução do workflow em tempo real!

Após a conclusão, o IP público da instância EC2 será exibido nos logs do passo "Get EC2 Public IP". Você pode acessar a API em `http://<IP_DA_EC2>:8080/alunos`.