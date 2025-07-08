variable "vpc_id" {}
variable "private_subnet_ids" {
  type = list(string)
}
variable "eks_node_sg_id" {
  description = "EKS node security group ID"
}
