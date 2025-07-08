# IAM Role pour les instances CI/CD (Jenkins, SonarQube)
resource "aws_iam_role" "cicd_instances" {
  name = "${var.project}-cicd-instances-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "cicd_instances" {
  name = "${var.project}-cicd-instances-policy"
  role = aws_iam_role.cicd_instances.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          aws_secretsmanager_secret.jenkins_credentials.arn,
          aws_secretsmanager_secret.sonarqube_credentials.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.tf_backend_bucket}",
          "arn:aws:s3:::${var.tf_backend_bucket}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:GetRecords",
          "dynamodb:UpdateItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:BatchGetItem",
          "dynamodb:DescribeTable",
          "dynamodb:ListTables"
        ]
        Resource = [
          "arn:aws:dynamodb:${var.region}:*:table/${var.tf_backend_dynamodb}",
          "arn:aws:dynamodb:${var.region}:*:table/terraform-locks"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "cicd_instances" {
  name = "${var.project}-cicd-instances-profile"
  role = aws_iam_role.cicd_instances.name
}