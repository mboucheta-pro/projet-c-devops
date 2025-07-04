# IAM Role pour le runner GitHub
resource "aws_iam_role" "github_runner" {
  name = "${var.project}-github-runner-role"

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

  tags = {}
}

resource "aws_iam_role_policy" "github_runner" {
  name = "${var.project}-github-runner-policy"
  role = aws_iam_role.github_runner.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          aws_secretsmanager_secret.jenkins_credentials.arn,
          aws_secretsmanager_secret.gitlab_credentials.arn,
          aws_secretsmanager_secret.sonarqube_credentials.arn,
          aws_secretsmanager_secret.database_credentials.arn,
          aws_secretsmanager_secret.github_credentials.arn
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "github_runner" {
  name = "${var.project}-github-runner-profile"
  role = aws_iam_role.github_runner.name
  tags = {}
}

# IAM Role pour les instances CI/CD (Jenkins, GitLab)
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
          aws_secretsmanager_secret.gitlab_credentials.arn,
          aws_secretsmanager_secret.sonarqube_credentials.arn,
          aws_secretsmanager_secret.database_credentials.arn,
          aws_secretsmanager_secret.github_credentials.arn
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "cicd_instances" {
  name = "${var.project}-cicd-instances-profile"
  role = aws_iam_role.cicd_instances.name
}