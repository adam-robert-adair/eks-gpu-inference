provider "aws" {
  region = var.region
}

data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
}

data "aws_caller_identity" "current" {}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

resource "kubernetes_namespace" "karpenter" {
  metadata {
    name = var.karpenter_namespace
  }
}

resource "helm_release" "karpenter" {
  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "1.0.8"
  namespace  = kubernetes_namespace.karpenter.metadata[0].name

  set {
    name  = "settings.clusterName"
    value = var.cluster_name
  }

  set {
    name  = "settings.interruptionQueue"
    value = "${var.cluster_name}-karpenter"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/KarpenterControllerRole-${var.cluster_name}"
  }
}


resource "helm_release" "nvidia_device_plugin" {
  name       = "nvidia-device-plugin"
  repository = "https://nvidia.github.io/k8s-device-plugin"
  chart      = "nvidia-device-plugin"
  version    = "0.16.2"
  namespace  = "kube-system"

  set {
    name  = "gfd.enabled"
    value = "true"
  }
}

resource "helm_release" "keda" {
  name       = "keda"
  repository = "https://kedacore.github.io/charts"
  chart      = "keda"
  version    = "2.15.1"
  namespace  = "keda"

  create_namespace = true
}

resource "kubernetes_manifest" "gpu_node_class" {
  manifest = {
    apiVersion = "karpenter.k8s.aws/v1"
    kind       = "EC2NodeClass"
    metadata = {
      name = "gpu-node-class"
    }
    spec = {
      amiFamily = "AL2"
      role      = "KarpenterNodeRole-${var.cluster_name}"
      subnetSelectorTerms = [{
        tags = {
          "karpenter.sh/discovery" = var.cluster_name
        }
      }]
      securityGroupSelectorTerms = [{
        tags = {
          "karpenter.sh/discovery" = var.cluster_name
        }
      }]
      tags = {
        "karpenter.sh/discovery" = var.cluster_name
        "workload"               = "gpu-inference"
      }
    }
  }

  depends_on = [helm_release.karpenter]
}

resource "kubernetes_manifest" "gpu_node_pool" {
  manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata = {
      name = var.gpu_nodepool_name
    }
    spec = {
      limits = {
        "nvidia.com/gpu" = tostring(var.max_total_gpus)
      }
      disruption = {
        consolidationPolicy = "WhenEmptyOrUnderutilized"
        consolidateAfter    = "60s"
      }
      template = {
        metadata = {
          labels = {
            "workload" = "gpu-inference"
          }
        }
        spec = {
          nodeClassRef = {
            group = "karpenter.k8s.aws"
            kind  = "EC2NodeClass"
            name  = kubernetes_manifest.gpu_node_class.manifest.metadata.name
          }
          taints = [{
            key    = "nvidia.com/gpu"
            value  = "true"
            effect = "NoSchedule"
          }]
          requirements = [
            {
              key      = "karpenter.k8s.aws/instance-family"
              operator = "In"
              values   = var.gpu_instance_families
            },
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["spot", "on-demand"]
            },
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["amd64"]
            }
          ]
        }
      }
    }
  }

  depends_on = [kubernetes_manifest.gpu_node_class, helm_release.nvidia_device_plugin]
}

resource "aws_budgets_budget" "gpu_guardrail" {
  name              = "eks-gpu-inference-monthly"
  budget_type       = "COST"
  limit_amount      = var.budget_limit_usd
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2025-01-01_00:00"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_email]
  }
}
