################################################################################
# General Variables from root module
################################################################################
variable "profile" {
  type = string
}

variable "main-region" {
  type = string
}
variable "vpc_id" {
  description = "VPC ID which EKS cluster is deployed in"
  type        = string
}

variable "private_subnets" {
  description = "VPC Private Subnets which EKS cluster is deployed in"
  type        = list(any)
}

variable "oidc_provider_arn" {
  description = "Add admin role to the aws-auth configmap"
}


