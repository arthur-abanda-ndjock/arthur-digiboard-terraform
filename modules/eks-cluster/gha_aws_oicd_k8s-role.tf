resource "kubernetes_cluster_role" "gha_aws_oicd_role" {
  metadata {
    name = "gha-aws-oicd-role"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services", "secrets", "configmaps", "namespaces", "persistentvolumes", "persistentvolumeclaims"]
    verbs      = ["get", "list", "watch", "create", "update", "delete", "patch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "statefulsets", "replicasets", "daemonsets"]
    verbs      = ["get", "list", "watch", "create", "update", "delete", "patch"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses", "networkpolicies"]
    verbs      = ["get", "list", "watch", "create", "update", "delete", "patch"]
  }

  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["storageclasses", "volumeattachments"]
    verbs      = ["get", "list", "watch", "create", "update", "delete", "patch"]
  }

}

resource "kubernetes_cluster_role_binding" "gha_aws_oicd_role_binding" {
  metadata {
    name = "gha-aws-oicd-role-binding"
  }

  role_ref {
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.gha_aws_oicd_role.metadata.0.name
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind      = "User"
    name      = "admin_github_oicd"
    api_group = "rbac.authorization.k8s.io"
  }
}
