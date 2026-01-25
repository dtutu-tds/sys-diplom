# Security Group for Bastion Host
resource "yandex_vpc_security_group" "sg_bastion" {
  name        = "sg-bastion"
  description = "Security group for Bastion host"
  network_id  = yandex_vpc_network.net_main.id

  ingress {
    protocol       = "TCP"
    description    = "Allow SSH from internet"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outgoing traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for Web Servers
resource "yandex_vpc_security_group" "sg_web" {
  name        = "sg-web"
  description = "Security group for web servers"
  network_id  = yandex_vpc_network.net_main.id

  ingress {
    protocol          = "TCP"
    description       = "Allow HTTP from ALB health checks"
    predefined_target = "loadbalancer_healthchecks"
    port              = 80
  }

  ingress {
    protocol          = "TCP"
    description       = "Allow HTTP from ALB"
    security_group_id = yandex_vpc_security_group.sg_alb.id
    port              = 80
  }

  ingress {
    protocol          = "TCP"
    description       = "Allow SSH from bastion"
    security_group_id = yandex_vpc_security_group.sg_bastion.id
    port              = 22
  }

  ingress {
    protocol          = "TCP"
    description       = "Allow Zabbix Agent access from Zabbix Server"
    security_group_id = yandex_vpc_security_group.sg_zabbix.id
    port              = 10050
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outgoing traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for Elasticsearch
resource "yandex_vpc_security_group" "sg_elastic" {
  name        = "sg-elastic"
  description = "Security group for Elasticsearch"
  network_id  = yandex_vpc_network.net_main.id

  ingress {
    protocol          = "TCP"
    description       = "Allow Elasticsearch from web servers"
    security_group_id = yandex_vpc_security_group.sg_web.id
    port              = 9200
  }

  ingress {
    protocol          = "TCP"
    description       = "Allow Elasticsearch from Kibana"
    security_group_id = yandex_vpc_security_group.sg_kibana.id
    port              = 9200
  }

  ingress {
    protocol          = "TCP"
    description       = "Allow SSH from bastion"
    security_group_id = yandex_vpc_security_group.sg_bastion.id
    port              = 22
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outgoing traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for Kibana
resource "yandex_vpc_security_group" "sg_kibana" {
  name        = "sg-kibana"
  description = "Security group for Kibana"
  network_id  = yandex_vpc_network.net_main.id

  ingress {
    protocol       = "TCP"
    description    = "Allow Kibana web interface from internet"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 5601
  }

  ingress {
    protocol          = "TCP"
    description       = "Allow SSH from bastion"
    security_group_id = yandex_vpc_security_group.sg_bastion.id
    port              = 22
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outgoing traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for Zabbix
resource "yandex_vpc_security_group" "sg_zabbix" {
  name        = "sg-zabbix"
  description = "Security group for Zabbix server"
  network_id  = yandex_vpc_network.net_main.id

  ingress {
    protocol       = "TCP"
    description    = "Allow HTTP for Zabbix web interface"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "TCP"
    description    = "Allow Zabbix agent connections"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 10051
  }

  ingress {
    protocol       = "TCP"
    description    = "Allow SSH from internet"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outgoing traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for Application Load Balancer
resource "yandex_vpc_security_group" "sg_alb" {
  name        = "sg-alb"
  description = "Security group for Application Load Balancer"
  network_id  = yandex_vpc_network.net_main.id

  ingress {
    protocol       = "TCP"
    description    = "Allow HTTP from internet"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol          = "TCP"
    description       = "Health checks"
    predefined_target = "loadbalancer_healthchecks"
    from_port         = 0
    to_port           = 65535
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outgoing traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
