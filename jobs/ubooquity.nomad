job "ubooquity" {
  datacenters = ["lab"]
  type = "service"

  constraint {
    attribute = "${meta.media_node}"
    value     = "true"
  }

  group "ubooquity" {
    count = 1

    network {
      mode = "bridge"
      port "ubooquity" { to = 2202 }
      port "ubooquity-admin" { to = 2203 }
    }

    update {
      max_parallel  = 0
      health_check  = "checks"
      auto_revert   = true
    }

    task "ubooquity" {
      driver = "docker"

      service {
        name = "ubooquity"
        port = "ubooquity"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.ubooquity.rule=Host(`${ACME_HOST}`) && PathPrefix(`/ubooquity`)",
        ]

        check {
          type      = "http"
          port      = "ubooquity"
          path      = "/ubooquity/index"
          interval  = "30s"
          timeout   = "2s"

          check_restart {
            limit = 2
            grace = "10s"
          }
        }
      }

      restart {
        interval  = "12h"
        attempts  = 720
        delay     = "60s"
        mode      = "delay"
      }

      env {
        PGID = "1100"
        PUID = "1100" 
      }

      config {
        image   = "lscr.io/linuxserver/ubooquity:${RELEASE}"
        ports = ["ubooquity","ubooquity-admin"]

        mount {
          type    = "bind"
          target  = "/books"
          source  = "/mnt/rclone/media/Books"
          readonly = false
          bind_options {
            propagation = "rshared"
          }
        }

        mount {
          type    = "bind"
          target  = "/config"
          source  = "/opt/ubooquity"
          readonly = false
          bind_options {
            propagation = "rshared"
          }
        }
      }

      template {
        data          = <<-EOH
          IMAGE_DIGEST={{ keyOrDefault "ubooquity/config/image_digest" "1" }}
          RELEASE={{ keyOrDefault "ubooquity/config/release" "latest" }}
          ACME_HOST={{ key "traefik/config/acme_host" }}
          EOH
        destination   = "env_info"
        env           = true
      }

      resources {
        cpu    = 200
        memory = 1024
      }

      kill_timeout = "20s"
    }
  }
}
