![DataDialogue Logo](https://raw.githubusercontent.com/canivel/datadialogue-sample/main/images/logo.png)

# DataDialogue.ai Samples: Bridging Generative AI with AWS Data Catalog (Glue)

Welcome to DataDialogue! This package allows you to deploy a Data Catalog in AWS Glue that interfaces with the OpenAI API through a Langchain Lambda function. The purpose is to execute SQL queries against your data catalog using an Athena-based connection. Additionally, an API Gateway is deployed that uses AWS Cognito for authentication.

## Getting Started

Follow the instructions below to get your DataDialogue environment up and running.

---

### Prerequisites

1. Docker installed on your machine
2. AWS Account
3. Terraform installed
4. OpenAI GPT-4 API Key

---

## Step-by-Step Installation Guide

### Step 1: Build and Push Docker Image

Replace `<account_id>` with your AWS account ID and choose your desired AWS region.

```bash
docker build -t aws-python3.11-sqllangchain:local -f Dockerfile.python3.11 .

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account_id>.dkr.ecr.us-east-1.amazonaws.com

aws ecr create-repository --repository-name hello-world --image-scanning-configuration scanOnPush=true --image-tag-mutability MUTABLE

docker tag aws-python3.11-sqllangchain:local <account_id>.dkr.ecr.us-east-1.amazonaws.com/aws-python3.11-sqllangchain:latest

docker push <account_id>.dkr.ecr.us-east-1.amazonaws.com/aws-python3.11-sqllangchain:latest
```

### Step 2: Update Terraform Variables

Open `tf-poc/modules/api_setup/variables.tf` and update the `image_uri` for the container.

### Step 3: Run Terraform Commands

```bash
terraform init
terraform plan
terraform apply
```

### Step 4: Configure OpenAI Secrets in AWS

Navigate to AWS Secrets Manager in the AWS console. Find the OpenAI Secrets Manager and update it with your company's OpenAI GPT-4 API key.

### Step 5: Testing

You can test the setup using the AWS Lambda Test console or the API Gateway test console. Below are some payload examples:

```json
{
  "query": "What is the top 10 countries with higher oil price on the last year of data available?"
}
```

```json
{ "query": "Which States reported the least and maximum deaths?" }
```

### Step 6: Integrate with External Applications

To integrate into an external app, open Cognito in the AWS console and create your user. Use this user to request a token as per [AWS documentation](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-integrate-with-cognito.html).

---

We hope this guide helps you get started with DataDialogue. Feel free to contribute or raise issues!

---
