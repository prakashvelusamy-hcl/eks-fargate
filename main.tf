module "vpc" {
  source         = "./modules/terraform-aws-vpc"
  vpc_cidr       = var.vpc_cidr
  pub_sub_count  = var.pub_sub_count
  priv_sub_count = var.priv_sub_count
  nat_count      = var.nat_count
}
# module "alb" {
#   source = "./modules/terraform-aws-alb"
#   public_subnet_ids = module.vpc.public_subnet_ids
#   environment = var.environment
#   vpc_id = module.vpc.vpc_id
# }

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
  depends_on = [module.vpc]
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

# provider "kubernetes" {
#   host                   = module.eks.cluster_endpoint
#   cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
#   token                  = data.aws_eks_cluster_auth.cluster.token
# }

module "rds" {
  source             = "./modules/terraform-aws-rds"
  private_subnet_ids = module.vpc.private_subnet_ids
  vpc_id             = module.vpc.vpc_id
  eks_node_sg_id     = module.eks.eks_node_sg_id

}

#module "apps" {
#  source = "./modules/terraform-aws-apps"
#}


module "iam" {
  source                                           = "./modules/terraform-aws-iam"
  aws_iam_openid_connect_provider_arn              = module.eks.aws_iam_openid_connect_provider_arn
  aws_iam_openid_connect_provider_extract_from_arn = module.eks.aws_iam_openid_connect_provider_extract_from_arn
}


module "helm" {
  source                             = "./modules/terraform-aws-helm"
  cluster_id                         = module.eks.cluster_id
  cluster_endpoint                   = module.eks.cluster_endpoint
  cluster_certificate_authority_data = module.eks.cluster_certificate_authority_data
  lbc_iam_depends_on                 = module.iam.lbc_iam_depends_on
  lbc_iam_role_arn                   = module.iam.lbc_iam_role_arn
  vpc_id                             = module.vpc.vpc_id
  region                             = var.region

  providers = {
    kubernetes = kubernetes.eks
    helm       = helm.eks
  }
}

data "aws_eks_cluster" "eks" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "eks" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  alias                  = "eks"
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}


provider "helm" {
  alias = "eks"
  kubernetes {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}
