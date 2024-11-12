resource "kubernetes_persistent_volume" "elastic_pv" {
  metadata {
    name = "elastic-pv"
  }

  spec {
    persistent_volume_source {
      local {
        path = "/Users/tomeroko/mnt/es"
      }
    }

    capacity = {
      storage = "5Gi"
    }

    storage_class_name = "hostpath"

    # Setting access_modes to ["ReadWriteOnce"] means only one node can
    # mount and write to the volume at a time, ensuring data consistency
    # and preventing conflicts
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

resource "kubernetes_persistent_volume_claim" "elastic_pvc" {
  metadata {
    name = "elastic-pvc"
  }

  depends_on = [
    kubernetes_persistent_volume.elastic_pv
  ]

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "hostpath"
    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }
}

resource "kubernetes_deployment" "elastic" {
  metadata {
    name = "elastic"
  }

  depends_on = [
    kubernetes_persistent_volume_claim.elastic_pvc
  ]

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "elasticsearch"
      }
    }

    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          app = "elasticsearch"
        }
      }

      spec {
        container {
          image = "docker.elastic.co/elasticsearch/elasticsearch:7.9.3"
          name  = "elastic"

          port {
            container_port = 9200
            name           = "http"
          }

          port {
            container_port = 9300
            name           = "transport"
          }

          env {
            name  = "discovery.type"
            value = "single-node"
          }

          volume_mount {
            name       = "elastic-ps" # persistent storage
            mount_path = "/usr/share/elasticsearch/data"
          }
        }

        volume {
          name = "elastic-ps"

          persistent_volume_claim {
            claim_name = "elastic-pvc"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "elasticsearch" {
  metadata {
    name = "elasticsearch"
  }

  spec {
    selector = {
      app = "elasticsearch"
    }


    port {
      port        = 9200
      target_port = 9200
      name        = "http"         # Added name for the HTTP port
    }

    port {
      port        = 9300
      target_port = 9300
      name        = "transport"    # Added name for the Transport port
    }


    type = "LoadBalancer"
  }
}

