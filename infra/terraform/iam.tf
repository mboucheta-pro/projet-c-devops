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
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "github_runner" {
  name = "${var.project}-github-runner-profile"
  role = aws_iam_role.github_runner.name
  tags = {}
}