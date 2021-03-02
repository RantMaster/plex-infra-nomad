job "radarr" {
  datacenters = ["lab"]
  type = "service"

  constraint {
    attribute = "${meta.media_node}"
    value     = "true"
  }

  update {
    max_parallel  = 0
    health_check  = "checks"
    auto_revert   = true
  }

  group "radarr" {
    count = 1

    restart {
      interval  = "12h"
      attempts  = 720
      delay     = "60s"
      mode      = "delay"
    }

    network {
      mode  = "bridge"
      port "radarr" { static = 7878 }
    }

    ephemeral_disk {
      sticky = true
      size = 2048
    }

    task "radarr" {
      driver = "containerd-driver"
      service {
        name = "radarr"
        port = "radarr"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.radarr.rule=PathPrefix(`/radarr`)",
          "traefik.http.routers.radarr.entrypoints=http",
          "traefik.http.services.radarr.loadbalancer.server.port=${NOMAD_HOST_PORT_radarr}",
        ]

        check {
          type      = "http"
          port      = "radarr"
          path      = "/radarr/login"
          interval  = "30s"
          timeout   = "2s"

          check_restart {
            limit = 10000
            grace = "60s"
          }
        }
      }

      env {
        PGID  = "1100"
        PUID  = "1100" 
        TZ    = "America/New_York"
      }

      config {
        image   = "docker.io/linuxserver/radarr:${RELEASE}"

        mounts  = [
                    {
                      type    = "bind"
                      target  = "/config"
                      source  = "/opt/radarr"
                      options = ["rbind", "rw"]
                    },
                    {
                      type    = "bind"
                      target  = "/downloads"
                      source  = "/mnt/downloads"
                      options = ["rbind", "rw"]
                    },
                    {
                      type    = "bind"
                      target  = "/media/movies"
                      source  = "/mnt/rclone/media/Movies"
                      options = ["rbind", "rw"]
                    }
                  ]
      }

      template {
        data          = <<EOH
IMAGE_ID={{ keyOrDefault "radarr/config/image_id" "1" }}
RELEASE={{ keyOrDefault "radarr/config/release" "latest" }}
EOH
        destination   = "env_info"
        env           = true
      }

      resources {
        cpu    = 500
        memory = 2048
      }

      kill_timeout = "20s"
    }
  }
}
