resource "aws_eks_cluster" "eks" {
  name     = "EKS"
  role_arn = var.cluster_role_arn
  version  = "1.32"
  vpc_config {
    subnet_ids = var.private_subnet_ids
  }
}


terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}


# resource "aws_launch_template" "eks_node_lt" {
#   name_prefix   = "eks-node-"
#   image_id      = "ami-0f4ea56cce2a654c6"
#   instance_type = "t3.medium"

#   vpc_security_group_ids = [aws_security_group.eks.id]

#   tag_specifications {
#     resource_type = "instance"

#     tags = {
#       "Name" = "eks-node"
#     }
#   }
# }


# resource "aws_eks_node_group" "ng" {
#   cluster_name    = aws_eks_cluster.eks.name
#   node_group_name = "node_group_flask"
#   node_role_arn   = var.node_role_arn
#   subnet_ids      = var.private_subnet_ids

#   scaling_config {
#     desired_size = 1
#     max_size     = 3
#     min_size     = 1
#   }

#   launch_template {
#     id      = aws_launch_template.eks_node_lt.id
#     version = "$Latest"
#   }

#   labels = {
#     workload = "backend"
#   }

#   depends_on = [aws_eks_cluster.eks]
# }


resource "aws_eks_node_group" "ng" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "node_group_flask"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = ["t2.medium"]

  scaling_config {
    desired_size = 1
    max_size     = 3
    min_size     = 1
  }

  labels = {
    workload = "backend"
  }

  disk_size = 20

  update_config {
    max_unavailable = 1
  }

  depends_on = [aws_eks_cluster.eks]
}




resource "aws_eks_fargate_profile" "frontend" {
  cluster_name           = aws_eks_cluster.eks.name
  fargate_profile_name   = "frontend-fargate-profile"
  pod_execution_role_arn = aws_iam_role.fargate_pod_execution_role.arn
  subnet_ids             = var.private_subnet_ids
  selector {
    namespace = "frontend"
  }

  depends_on = [aws_eks_cluster.eks]
}



data "aws_partition" "current" {}

# Resource: AWS IAM Open ID Connect Provider
resource "aws_iam_openid_connect_provider" "oidc_provider" {
  client_id_list  = ["sts.${data.aws_partition.current.dns_suffix}"]
  thumbprint_list = [var.eks_oidc_root_ca_thumbprint]
  url             = aws_eks_cluster.eks.identity[0].oidc[0].issuer

  tags = {
    Name = "eks-irsa"
  }
}

# Extract OIDC Provider from OIDC Provider ARN
locals {
  aws_iam_oidc_connect_provider_extract_from_arn = element(split("oidc-provider/", "${aws_iam_openid_connect_provider.oidc_provider.arn}"), 1)
}