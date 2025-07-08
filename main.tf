#############################################
# VPC Module
#############################################
module "vpc" {
  source         = "./modules/terraform-aws-vpc"
  vpc_cidr       = var.vpc_cidr
  pub_sub_count  = var.pub_sub_count
  priv_sub_count = var.priv_sub_count
  nat_count      = var.nat_count
}

#############################################
# EKS IAM
#############################################
module "iam" {
  source = "./modules/terraform-aws-iam"
  aws_iam_openid_connect_provider_arn              = module.eks.aws_iam_openid_connect_provider_arn
  aws_iam_openid_connect_provider_extract_from_arn = module.eks.aws_iam_openid_connect_provider_extract_from_arn
}

#############################################
# RDS
#############################################
module "rds" {
  source             = "./modules/terraform-aws-rds"
  private_subnet_ids = module.vpc.private_subnet_ids
  vpc_id             = module.vpc.vpc_id
  eks_node_sg_id     = module.eks.eks_node_sg_id
}

#############################################
# EKS Module
#############################################
module "eks" {
  source                      = "./modules/terraform-aws-eks"
  private_subnet_ids          = module.vpc.private_subnet_ids
  public_subnet_ids           = module.vpc.public_subnet_ids
  cluster_role_arn            = module.iam.eks_cluster_role_arn
  node_role_arn               = module.iam.eks_node_role_arn
  eks_oidc_root_ca_thumbprint = var.eks_oidc_root_ca_thumbprint
  cluster_role_dependency     = module.iam.eks_role_depends_on
  vpc_id                      = module.vpc.vpc_id
  credentials_secret_arn      = module.rds.credentials_secret_arn
  connection_secret_arn       = module.rds.connection_secret_arn

  providers = {
    kubernetes = kubernetes.eks
  }

   depends_on = [
    module.helm ]
}

#############################################
# EKS Data Sources (AFTER EKS IS CREATED)
#############################################
data "aws_eks_cluster" "eks" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "eks" {
  name = module.eks.cluster_id
}

#############################################
# Kubernetes Provider (With EKS Token)
#############################################
provider "kubernetes" {
  alias                  = "eks"
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

#############################################
# Helm Provider
#############################################
provider "helm" {
  alias = "eks"
  kubernetes {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}

#############################################
# Helm Module
#############################################
module "helm" {
  source                             = "./modules/terraform-aws-helm"
  cluster_id                         = module.eks.cluster_id
  cluster_endpoint                   = data.aws_eks_cluster.eks.endpoint
  cluster_certificate_authority_data = data.aws_eks_cluster.eks.certificate_authority[0].data
  lbc_iam_depends_on                 = module.iam.lbc_iam_depends_on
  lbc_iam_role_arn                   = module.iam.lbc_iam_role_arn
  vpc_id                             = module.vpc.vpc_id
  region                             = var.region

  providers = {
    kubernetes = kubernetes.eks
    helm       = helm.eks
  }
}
