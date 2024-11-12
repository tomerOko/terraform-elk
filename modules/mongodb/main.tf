
resource "kubernetes_persistent_volume" "mongo_pv" {
  metadata {
    name = "main-mon-pv"
  }

  spec {
    persistent_volume_source {
      local {
        path = "/Users/tomeroko/mnt/data/main"
      }
    }

    capacity = {
      storage = "2Gi"
    }

    storage_class_name = "hostpath"

    access_modes = ["ReadWriteOnce"]

    persistent_volume_reclaim_policy = "Retain"

    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key      = "kubernetes.io/hostname"
            operator = "In"
            values   = ["docker-desktop"]
          }
        }
      }
    }

  }
}

resource "kubernetes_persistent_volume_claim" "mongo_pvc" {

  metadata {
    name = "main-mon-pvc"
  }

  depends_on = [
    kubernetes_persistent_volume.mongo_pv
  ]

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "hostpath"
    resources {
      requests = {
        storage = "2Gi"
      }
    }
  }
}

resource "kubernetes_deployment" "mongo" {

  metadata {
    name = "main-mon"
  }

  depends_on = [
    kubernetes_persistent_volume_claim.mongo_pvc
  ]

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "main-mon"
      }
    }

    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          app = "main-mon"
        }
      }

      spec {
        container {
          image = "mongo:latest"
          name  = "main-mon"

          port {
            container_port = 27017
            name           = "main-mon"
          }

          volume_mount {
            name       = "main-mon-ps" # persistent storage
            mount_path = "/data/db"
          }
        }

        volume {
          name = "main-mon-ps"

          persistent_volume_claim {
            claim_name = "main-mon-pvc"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "mongo_service" {

  metadata {
    name = "main-mon"
  }

  depends_on = [
    kubernetes_deployment.mongo
  ]

  spec {
    selector = {
      app = "main-mon"
    }

    port {
      port        = 27017
      target_port = 27017
    }
  }
}
