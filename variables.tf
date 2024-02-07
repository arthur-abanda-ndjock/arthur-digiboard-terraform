################################################################################
# Terraform State Backend  Variables
################################################################################

variable "tf_state_s3_bucket" {
  type    = string
  default = "terraform-infra-bckt"
}

variable "tf_state_s3_key" {
  type    = string
  default = "tf-state"
}


variable "tf_state_lock_tbl_name" {
  type    = string
  default = "terraform-state-locking"
}


################################################################################
# Default Variables
################################################################################

variable "profile" {
  type    = string
  default = "default"
}

variable "main-region" {
  type    = string
  default = "us-east-2"
}


################################################################################
# EKS Cluster Variables
################################################################################

variable "cluster_name" {
  type    = string
  default = "tf-cluster"
}

variable "rolearn" {
  description = "Add admin role to the aws-auth configmap"
}

################################################################################
# ALB Controller Variables
################################################################################

variable "env_name" {
  type    = string
  default = "dev"
}

