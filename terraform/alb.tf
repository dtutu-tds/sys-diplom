# Target Group for web servers
resource "yandex_alb_target_group" "tg_web" {
  name = "tg-web"

  target {
    subnet_id  = yandex_vpc_subnet.subnet_private_a.id
    ip_address = yandex_compute_instance.web1.network_interface[0].ip_address
  }

  target {
    subnet_id  = yandex_vpc_subnet.subnet_private_b.id
    ip_address = yandex_compute_instance.web2.network_interface[0].ip_address
  }
}

# Backend Group with health checks
resource "yandex_alb_backend_group" "bg_web" {
  name = "bg-web"

  http_backend {
    name             = "backend-web"
    weight           = 1
    port             = 80
    target_group_ids = [yandex_alb_target_group.tg_web.id]

    load_balancing_config {
      panic_threshold = 50
    }

    healthcheck {
      timeout             = "5s"
      interval            = "10s"
      healthy_threshold   = 2
      unhealthy_threshold = 2

      http_healthcheck {
        path = "/"
      }
    }
  }
}

# HTTP Router
resource "yandex_alb_http_router" "router_web" {
  name = "router-web"
}

# Virtual Host
resource "yandex_alb_virtual_host" "vh_web" {
  name           = "vh-web"
  http_router_id = yandex_alb_http_router.router_web.id

  route {
    name = "route-main"

    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.bg_web.id
        timeout          = "60s"
      }
    }
  }
}

# Application Load Balancer
resource "yandex_alb_load_balancer" "alb_main" {
  name               = "alb-main"
  network_id         = yandex_vpc_network.net_main.id
  security_group_ids = [yandex_vpc_security_group.sg_alb.id]

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.subnet_public.id
    }
  }

  listener {
    name = "listener-http"

    endpoint {
      address {
        external_ipv4_address {
        }
      }

      ports = [80]
    }

    http {
      handler {
        http_router_id = yandex_alb_http_router.router_web.id
      }
    }
  }
}
