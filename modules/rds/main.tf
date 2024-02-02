
resource "aws_db_instance" "default" {
  allocated_storage = 20
  storage_type      = "gp2"
  engine            = "mysql"
  engine_version    = "5.7"
  instance_class    = "db.t2.medium"
  identifier        = "mydb"
  username          = "dbuser"
  password          = "dbpassword"

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.my_db_subnet_group.name

  backup_retention_period      = 7
  backup_window                = "03:00-04:00"
  maintenance_window           = "mon:04:00-mon:04:30"
  skip_final_snapshot          = false
  final_snapshot_identifier    = "my-db-3"
  monitoring_interval          = 60
  monitoring_role_arn          = aws_iam_role.rds_monitoring_role.arn
  performance_insights_enabled = true
  storage_encrypted            = true
  kms_key_id                   = aws_kms_key.my_kms_key.arn

  parameter_group_name = aws_db_parameter_group.my_db_pmg.name

  # Enable Multi-AZ deployment for high availability
  multi_az = true
}

resource "aws_security_group" "rds_sg" {
  name_prefix = "rds-"
  vpc_id      = var.vpc_id

  # Add any additional ingress/egress rules as needed
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "my_db_subnet_group" {
  name       = "my-db-subnet-group"
  subnet_ids = var.private_subnets

  tags = {
    Name = "My DB Subnet Group"
  }
}

##
## DB setup Replica 

# resource "aws_db_instance" "replica" {
#   replicate_source_db = aws_db_instance.default.identifier
#   instance_class      = "db.t2.medium"

#   vpc_security_group_ids = [aws_security_group.rds_sg.id]

#   backup_retention_period = 7
#   backup_window           = "03:00-04:00"
#   maintenance_window      = "mon:04:00-mon:04:30"
#   skip_final_snapshot     = true
#   //final_snapshot_identifier    = "my-db-2"
#   monitoring_interval          = 60
#   monitoring_role_arn          = aws_iam_role.rds_monitoring_role.arn
#   performance_insights_enabled = true
#   storage_encrypted            = true
#   kms_key_id                   = aws_kms_key.my_kms_key.arn

#   parameter_group_name = aws_db_parameter_group.my_db_pmg.name

#   # Enable Multi-AZ deployment for high availability
#   multi_az = true
# }

# resource "aws_db_instance_automated_backups_replication" "default" {
#   source_db_instance_arn = aws_db_instance.default.arn
#   retention_period       = 14
#   kms_key_id             = aws_kms_key.my_kms_key_us_west.arn

#   provider = aws.replica
# }

# resource "aws_kms_key" "my_kms_key_us_west" {
#   description             = "My KMS Key for RDS Encryption"
#   deletion_window_in_days = 30

#   tags = {
#     Name = "MyKMSKey"
#   }

#   provider = aws.replica
# }

resource "aws_kms_key" "my_kms_key" {
  description             = "My KMS Key for RDS Encryption"
  deletion_window_in_days = 30

  tags = {
    Name = "MyKMSKey"
  }
}

resource "aws_db_parameter_group" "my_db_pmg" {
  name   = "mysql"
  family = "mysql5.7"

  parameter {
    name  = "connect_timeout"
    value = "15"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role" "rds_monitoring_role" {
  name = "arthur-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "rds_monitoring_attachment" {
  name       = "rds-monitoring-attachment"
  roles      = [aws_iam_role.rds_monitoring_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

data "aws_caller_identity" "current" {}


# Define Local Values in Terraform
locals {
  owners      = "arth-business"
  environment = "dev-env"
  name        = "arth-business-dev-env"
  common_tags = {
    owners      = local.owners
    environment = local.environment
  }
  #eks_cluster_name       = data.terraform_remote_state.eks.outputs.cluster_id
  irsa_oidc_provider_url = replace(var.oidc_provider_arn, "/^(.*provider/)/", "")
}



# Resource: Create IAM Role and associate the EBS IAM Policy to it
resource "aws_iam_role" "irsa_iam_role" {
  name = "${local.name}-irsa-iam-role"

  # Terraform's "jsonencode" function converts a Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${local.irsa_oidc_provider_url}:sub" : "system:serviceaccount:default:irsa-demo-sa"
          }
        }

        Condition = {
          StringEquals = {
            "${local.irsa_oidc_provider_url}:aud" : "sts.amazonaws.com"
          }
        }
      },
    ]
  })

  tags = {
    tag-key = "${local.name}-irsa-iam-role"
  }
}

resource "aws_iam_role_policy" "rds_access_from_k8s_pods" {
  name = "rds-access-from-k8s-pods"
  role = aws_iam_role.irsa_iam_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "rds-db:connect",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:rds-db:${var.main-region}:${data.aws_caller_identity.current.account_id}:dbuser:${aws_db_instance.default.resource_id}/metabase"
      }
    ]
  })
}

# Associate IAM Role and Policy
resource "aws_iam_role_policy_attachment" "irsa_iam_role_policy_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
  role       = aws_iam_role.irsa_iam_role.name
}

# Associate IAM Role and Policy
resource "aws_iam_role_policy_attachment" "irsa_iam_role_rds_alldata_policy_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSReadOnlyAccess"
  role       = aws_iam_role.irsa_iam_role.name
}

# Resource: Kubernetes Service Account
resource "kubernetes_service_account_v1" "irsa_demo_sa" {
  depends_on = [aws_iam_role_policy_attachment.irsa_iam_role_policy_attach, aws_iam_role_policy_attachment.irsa_iam_role_rds_alldata_policy_attach, aws_iam_role_policy.rds_access_from_k8s_pods]
  metadata {
    name = "irsa-demo-sa"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.irsa_iam_role.arn
    }
  }
}



output "irsa_iam_role_arn" {
  description = "IRSA Demo IAM Role ARN"
  value       = aws_iam_role.irsa_iam_role.arn
}


