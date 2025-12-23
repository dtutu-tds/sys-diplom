# =============================================================================
# Terraform Outputs
# =============================================================================
# Outputs for accessing infrastructure resources
# Run: terraform output
# Run: terraform output -json > outputs.json
# =============================================================================

# -----------------------------------------------------------------------------
# Application Load Balancer
# -----------------------------------------------------------------------------

output "alb_public_ip" {
  description = "Public IP address of Application Load Balancer"
  value       = try(yandex_alb_load_balancer.alb_main.listener[0].endpoint[0].address[0].external_ipv4_address[0].address, "")
}

output "website_url" {
  description = "URL to access the website via ALB"
  value       = "http://${try(yandex_alb_load_balancer.alb_main.listener[0].endpoint[0].address[0].external_ipv4_address[0].address, "")}"
}

# -----------------------------------------------------------------------------
# Bastion Host
# -----------------------------------------------------------------------------

output "bastion_public_ip" {
  description = "Public IP address of Bastion host"
  value       = try(yandex_compute_instance.bastion.network_interface[0].nat_ip_address, "")
}

output "bastion_private_ip" {
  description = "Private IP address of Bastion host"
  value       = try(yandex_compute_instance.bastion.network_interface[0].ip_address, "")
}

output "bastion_fqdn" {
  description = "FQDN of Bastion host"
  value       = try(yandex_compute_instance.bastion.fqdn, "")
}

output "bastion_ssh_command" {
  description = "SSH command to connect to Bastion host"
  value       = "ssh ubuntu@${try(yandex_compute_instance.bastion.network_interface[0].nat_ip_address, "")}"
}

# -----------------------------------------------------------------------------
# Web Servers
# -----------------------------------------------------------------------------

output "web1_private_ip" {
  description = "Private IP address of web1"
  value       = try(yandex_compute_instance.web1.network_interface[0].ip_address, "")
}

output "web1_fqdn" {
  description = "FQDN of web1"
  value       = try(yandex_compute_instance.web1.fqdn, "")
}

output "web2_private_ip" {
  description = "Private IP address of web2"
  value       = try(yandex_compute_instance.web2.network_interface[0].ip_address, "")
}

output "web2_fqdn" {
  description = "FQDN of web2"
  value       = try(yandex_compute_instance.web2.fqdn, "")
}

# -----------------------------------------------------------------------------
# Zabbix Server
# -----------------------------------------------------------------------------

output "zabbix_public_ip" {
  description = "Public IP address of Zabbix server"
  value       = try(yandex_compute_instance.zabbix.network_interface[0].nat_ip_address, "")
}

output "zabbix_private_ip" {
  description = "Private IP address of Zabbix server"
  value       = try(yandex_compute_instance.zabbix.network_interface[0].ip_address, "")
}

output "zabbix_fqdn" {
  description = "FQDN of Zabbix server"
  value       = try(yandex_compute_instance.zabbix.fqdn, "")
}

output "zabbix_web_url" {
  description = "URL to access Zabbix web interface"
  value       = "http://${try(yandex_compute_instance.zabbix.network_interface[0].nat_ip_address, "")}/zabbix"
}

# -----------------------------------------------------------------------------
# Elasticsearch Server
# -----------------------------------------------------------------------------

output "elastic_private_ip" {
  description = "Private IP address of Elasticsearch"
  value       = try(yandex_compute_instance.elastic.network_interface[0].ip_address, "")
}

output "elastic_fqdn" {
  description = "FQDN of Elasticsearch server"
  value       = try(yandex_compute_instance.elastic.fqdn, "")
}

output "elastic_internal_url" {
  description = "Internal URL to access Elasticsearch API"
  value       = "http://${try(yandex_compute_instance.elastic.fqdn, "")}:9200"
}

# -----------------------------------------------------------------------------
# Kibana Server
# -----------------------------------------------------------------------------

output "kibana_public_ip" {
  description = "Public IP address of Kibana"
  value       = try(yandex_compute_instance.kibana.network_interface[0].nat_ip_address, "")
}

output "kibana_private_ip" {
  description = "Private IP address of Kibana"
  value       = try(yandex_compute_instance.kibana.network_interface[0].ip_address, "")
}

output "kibana_fqdn" {
  description = "FQDN of Kibana server"
  value       = try(yandex_compute_instance.kibana.fqdn, "")
}

output "kibana_web_url" {
  description = "URL to access Kibana web interface"
  value       = "http://${try(yandex_compute_instance.kibana.network_interface[0].nat_ip_address, "")}:5601"
}

# -----------------------------------------------------------------------------
# Summary Outputs (Maps)
# -----------------------------------------------------------------------------

output "public_ips" {
  description = "Map of all public IP addresses"
  value = {
    alb     = try(yandex_alb_load_balancer.alb_main.listener[0].endpoint[0].address[0].external_ipv4_address[0].address, "")
    bastion = try(yandex_compute_instance.bastion.network_interface[0].nat_ip_address, "")
    zabbix  = try(yandex_compute_instance.zabbix.network_interface[0].nat_ip_address, "")
    kibana  = try(yandex_compute_instance.kibana.network_interface[0].nat_ip_address, "")
  }
}

output "private_ips" {
  description = "Map of all private IP addresses"
  value = {
    bastion = try(yandex_compute_instance.bastion.network_interface[0].ip_address, "")
    web1    = try(yandex_compute_instance.web1.network_interface[0].ip_address, "")
    web2    = try(yandex_compute_instance.web2.network_interface[0].ip_address, "")
    zabbix  = try(yandex_compute_instance.zabbix.network_interface[0].ip_address, "")
    elastic = try(yandex_compute_instance.elastic.network_interface[0].ip_address, "")
    kibana  = try(yandex_compute_instance.kibana.network_interface[0].ip_address, "")
  }
}

output "fqdns" {
  description = "Map of all FQDNs"
  value = {
    bastion = try(yandex_compute_instance.bastion.fqdn, "")
    web1    = try(yandex_compute_instance.web1.fqdn, "")
    web2    = try(yandex_compute_instance.web2.fqdn, "")
    zabbix  = try(yandex_compute_instance.zabbix.fqdn, "")
    elastic = try(yandex_compute_instance.elastic.fqdn, "")
    kibana  = try(yandex_compute_instance.kibana.fqdn, "")
  }
}

output "web_urls" {
  description = "Map of all web interface URLs"
  value = {
    website = "http://${try(yandex_alb_load_balancer.alb_main.listener[0].endpoint[0].address[0].external_ipv4_address[0].address, "")}"
    zabbix  = "http://${try(yandex_compute_instance.zabbix.network_interface[0].nat_ip_address, "")}/zabbix"
    kibana  = "http://${try(yandex_compute_instance.kibana.network_interface[0].nat_ip_address, "")}:5601"
  }
}

# -----------------------------------------------------------------------------
# Ansible Inventory Helper
# -----------------------------------------------------------------------------

output "ansible_inventory_vars" {
  description = "Variables for generating Ansible inventory"
  value = {
    bastion_ip = try(yandex_compute_instance.bastion.network_interface[0].nat_ip_address, "")
    hosts = {
      web1    = try(yandex_compute_instance.web1.network_interface[0].ip_address, "")
      web2    = try(yandex_compute_instance.web2.network_interface[0].ip_address, "")
      elastic = try(yandex_compute_instance.elastic.network_interface[0].ip_address, "")
      kibana  = try(yandex_compute_instance.kibana.network_interface[0].ip_address, "")
      zabbix  = try(yandex_compute_instance.zabbix.network_interface[0].nat_ip_address, "")
    }
  }
}
