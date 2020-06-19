# Terraform AWS VPC with Dynamic Peering

Demo Terraform code to create peered VPCs in two AWS regions using dynamically generated info.

## Requirements

- HashiCorp [Terraform, >v0.12.0](https://www.terraform.io/downloads.html)
- [AWS Account](https://aws.amazon.com/console/)

## System Requirements

This can be executed on either a Windows or Linux system

Must setup environment variables for AWS credentials; access key and secret key.

AWS S3 bucket for backend state storage.

## Execution Instructions

```bash
# Clone the respository
git clone git@github.com:nukdcbear/terraform-aws-vpcs-dynamic-peering.git

# cd in the directory
cd terraform-aws-vpcs-dynamic-peering

# Execute Terraform
terraform init
terraform plan -out=mytfplan
terraform apply mytfplan
```