terraform {
  backend "s3" {
    bucket       = "chatbot-aws-tf-state-484632959006"
    key          = "bedrock-rag/dev/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}
