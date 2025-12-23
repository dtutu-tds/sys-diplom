# VPC Network
resource "yandex_vpc_network" "net_main" {
  name        = "net-main"
  description = "Main VPC network for diploma infrastructure"
}

# Public subnet in ru-central1-a
resource "yandex_vpc_subnet" "subnet_public" {
  name           = "subnet-public"
  description    = "Public subnet for bastion, zabbix, kibana"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.net_main.id
  v4_cidr_blocks = ["10.0.1.0/24"]
}

# Private subnet A in ru-central1-a
resource "yandex_vpc_subnet" "subnet_private_a" {
  name           = "subnet-private-a"
  description    = "Private subnet A for web1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.net_main.id
  v4_cidr_blocks = ["10.0.10.0/24"]
  route_table_id = yandex_vpc_route_table.rt_private.id
}

# Private subnet B in ru-central1-b
resource "yandex_vpc_subnet" "subnet_private_b" {
  name           = "subnet-private-b"
  description    = "Private subnet B for web2, elastic"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.net_main.id
  v4_cidr_blocks = ["10.0.11.0/24"]
  route_table_id = yandex_vpc_route_table.rt_private.id
}

# NAT Gateway for private subnets
resource "yandex_vpc_gateway" "nat_gateway" {
  name = "nat-gateway"
  shared_egress_gateway {}
}

# Route table for private subnets
resource "yandex_vpc_route_table" "rt_private" {
  name       = "rt-private"
  network_id = yandex_vpc_network.net_main.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}
