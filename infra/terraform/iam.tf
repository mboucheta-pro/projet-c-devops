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
      }
    ]
  })
}

resource "aws_iam_instance_profile" "cicd_instances" {
  name = "${var.project}-cicd-instances-profile"
  role = aws_iam_role.cicd_instances.name
}