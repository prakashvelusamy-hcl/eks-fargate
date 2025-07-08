resource "aws_iam_role" "backend_irsa_role" {
  name = "eks-backend-irsa-role"

  assume_role_policy = data.aws_iam_policy_document.eks_assume_role_policy.json
}

data "aws_iam_policy_document" "eks_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.oidc_provider.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.oidc_provider.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:backend:backend-sa"]
    }
  }
}

resource "aws_iam_policy" "secrets_policy" {
  name = "allow-secrets-access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["secretsmanager:GetSecretValue"],
        Resource = [
          var.credentials_secret_arn,
          var.connection_secret_arn
        ]
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.backend_irsa_role.name
  policy_arn = aws_iam_policy.secrets_policy.arn
}

resource "kubernetes_namespace" "backend" {
  metadata {
    name = "backend"
  }
}

resource "kubernetes_service_account" "backend_sa" {
  metadata {
    name      = "backend-sa"
    namespace = "backend"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.backend_irsa_role.arn
    }
  }
}
