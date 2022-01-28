job "caddy" {
  datacenters = ["lab"]
  type = "service"

  constraint {
    attribute = "${meta.media_node}"
    value     = "true"
  }

  group "caddy" {
    count = 1

    network {
      mode  = "bridge"
      port "caddy" {}
    }

    service {
      name = "caddy"
      port = 2020

      connect {
        sidecar_service {}
      }

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.caddy.rule=Host(`HOST.DOMAIN.NAME`) && PathPrefix(`/downloads`)",
        "traefik.http.routers.caddy.tls.certresolver=letsencrypt",
        "traefik.http.routers.caddy.entrypoints=web-secure",
      ]
    }

    update {
      max_parallel  = 0
      health_check  = "checks"
      auto_revert   = true
    }

    task "caddy" {
      driver = "docker"

      restart {
        interval  = "12h"
        attempts  = 720
        delay     = "60s"
        mode      = "delay"
      }

      config {
        image   = "${IMAGE}:${RELEASE}"
        command = "caddy"
        ports   = [ "caddy" ]

        args    = [
                    "run",
                    "--config",
                    "/local/Caddyfile"
                  ]

        mount {
          type      = "bind"
          target    = "/config"
          source    = "/opt/caddy/config"
          readonly  = false
          bind_options {
            propagation = "rshared"
          }
        }

        mount {
          type      = "bind"
          target    = "/downloads"
          source    = "/mnt/downloads/complete"
          readonly  = false
          bind_options {
            propagation = "rshared"
          }
        }

        mount {
          type      = "bind"
          target    = "/data"
          source    = "/opt/caddy/data"
          readonly  = false
          bind_options {
            propagation = "rshared"
          }
        }

      }

      template {
        data          = <<-EOH
          IMAGE={{ key "caddy/config/image" }}
          IMAGE_DIGEST={{ keyOrDefault "caddy/config/image_digest" "1" }}
          RELEASE={{ keyOrDefault "caddy/config/release" "latest" }}
          ACME_HOST={{ key "traefik/config/acme_host" }}
          EOH
        destination   = "env_info"
        env           = true
      }

      template {
        data        = <<-EOH
          {
            admin       off
            auto_https  off
          }

          http://:2020 {
            handle_path   /downloads* {
              file_server browse
              root  * /downloads
              basicauth {
                {{ range tree "caddy/config/basicauth_users/" -}}
                  {{- .Key }} {{ .Value }}
                {{ end -}}
                }
          }
          EOH
        destination = "/local/Caddyfile"
        change_mode = "restart"
      }

      resources {
        cpu    = 200
        memory = 512 
      }

      kill_timeout = "20s"
    }
  }
}
