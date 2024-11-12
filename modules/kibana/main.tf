resource "kubernetes_deployment" "kibana" {
  metadata {
    name = "kibana"
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "kibana"
      }
    }

    template {
      metadata {
        labels = {
          app = "kibana"
        }
      }

      spec {
        container {
          name  = "kibana"
          image = "docker.elastic.co/kibana/kibana:7.9.3"

          port {
            container_port = 5601
          }

          env {
            name  = "ELASTICSEARCH_HOSTS"
            value = "http://elasticsearch:9200" 
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "kibana" {
  metadata {
    name = "kibana"
  }

  spec {
    selector = {
      app = "kibana"
    }

    port {
      port        = 5601
      target_port = 5601
    }

    type = "LoadBalancer"
  }
}
