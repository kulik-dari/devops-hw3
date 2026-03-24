output "vpc_id" {
  value = module.vpc.vpc_id
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "s3_bucket_id" {
  value = module.s3_backend.bucket_id
}

output "jenkins_url" {
  value = module.jenkins.jenkins_url
}

output "argocd_url" {
  value = module.argo_cd.argocd_url
}
