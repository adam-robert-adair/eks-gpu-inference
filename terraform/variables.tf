variable "region" {
  type        = string
  description = "AWS region for EKS/GPU workloads"
  default     = "us-west-2"
}

variable "cluster_name" {
  type        = string
  description = "Existing EKS cluster name from project 1"
  default     = "eks-ai-platform"
}

variable "karpenter_namespace" {
  type        = string
  description = "Namespace for Karpenter"
  default     = "karpenter"
}

variable "gpu_nodepool_name" {
  type        = string
  description = "Name of GPU nodepool"
  default     = "gpu-spot-pool"
}

variable "max_total_gpus" {
  type        = number
  description = "Hard cap for total provisioned GPUs"
  default     = 4
}

variable "gpu_instance_families" {
  type        = list(string)
  description = "Allowed GPU families"
  default     = ["g4dn", "g5", "g6"]
}

variable "budget_limit_usd" {
  type        = string
  description = "Monthly budget alert amount"
  default     = "150"
}

variable "budget_email" {
  type        = string
  description = "Email for budget alerts"
}
