# =============================================================================
# Yandex Cloud Configuration Variables
# =============================================================================

# -----------------------------------------------------------------------------
# Required Variables (must be set in terraform.tfvars)
# -----------------------------------------------------------------------------

variable "cloud_id" {
  description = "Yandex Cloud ID - идентификатор облака"
  type        = string

  validation {
    condition     = length(var.cloud_id) > 0 && can(regex("^b1[a-z0-9]+$", var.cloud_id))
    error_message = "Cloud ID must start with 'b1' followed by alphanumeric characters."
  }
}

variable "folder_id" {
  description = "Yandex Cloud Folder ID - идентификатор каталога"
  type        = string

  validation {
    condition     = length(var.folder_id) > 0 && can(regex("^b1[a-z0-9]+$", var.folder_id))
    error_message = "Folder ID must start with 'b1' followed by alphanumeric characters."
  }
}

variable "ssh_public_key" {
  description = "SSH public key for VM access - публичный SSH-ключ для доступа к ВМ"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Optional Variables with Defaults
# -----------------------------------------------------------------------------

# Availability Zones
variable "default_zone" {
  description = "Default availability zone - зона доступности по умолчанию"
  type        = string
  default     = "ru-central1-a"

  validation {
    condition     = contains(["ru-central1-a", "ru-central1-b", "ru-central1-d"], var.default_zone)
    error_message = "Zone must be one of: ru-central1-a, ru-central1-b, ru-central1-d."
  }
}

variable "zone_a" {
  description = "Primary availability zone (zone A)"
  type        = string
  default     = "ru-central1-a"
}

variable "zone_b" {
  description = "Secondary availability zone (zone B)"
  type        = string
  default     = "ru-central1-b"
}

# Service Account
variable "service_account_key_file" {
  description = "Path to service account key file (JSON)"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Network Configuration
# -----------------------------------------------------------------------------

variable "vpc_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "diploma-network"
}

variable "subnet_public_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet_private_a_cidr" {
  description = "CIDR block for private subnet A"
  type        = string
  default     = "10.0.10.0/24"
}

variable "subnet_private_b_cidr" {
  description = "CIDR block for private subnet B"
  type        = string
  default     = "10.0.11.0/24"
}

# -----------------------------------------------------------------------------
# VM Configuration
# -----------------------------------------------------------------------------

variable "vm_username" {
  description = "Default username for VM SSH access"
  type        = string
  default     = "ubuntu"
}

variable "vm_platform_id" {
  description = "Platform ID for VMs (standard-v1, standard-v2, standard-v3)"
  type        = string
  default     = "standard-v2"
}

variable "vm_preemptible" {
  description = "Whether VMs should be preemptible (for cost savings)"
  type        = bool
  default     = true
}

variable "vm_core_fraction" {
  description = "Guaranteed vCPU share (5, 20, 50, 100)"
  type        = number
  default     = 20

  validation {
    condition     = contains([5, 20, 50, 100], var.vm_core_fraction)
    error_message = "Core fraction must be one of: 5, 20, 50, 100."
  }
}

# VM Resources - Bastion
variable "bastion_cores" {
  description = "Number of CPU cores for Bastion host"
  type        = number
  default     = 2
}

variable "bastion_memory" {
  description = "Memory in GB for Bastion host"
  type        = number
  default     = 2
}

variable "bastion_disk_size" {
  description = "Boot disk size in GB for Bastion host"
  type        = number
  default     = 10
}

# VM Resources - Web Servers
variable "web_cores" {
  description = "Number of CPU cores for web servers"
  type        = number
  default     = 2
}

variable "web_memory" {
  description = "Memory in GB for web servers"
  type        = number
  default     = 2
}

variable "web_disk_size" {
  description = "Boot disk size in GB for web servers"
  type        = number
  default     = 10
}

# VM Resources - Zabbix
variable "zabbix_cores" {
  description = "Number of CPU cores for Zabbix server"
  type        = number
  default     = 2
}

variable "zabbix_memory" {
  description = "Memory in GB for Zabbix server"
  type        = number
  default     = 4
}

variable "zabbix_disk_size" {
  description = "Boot disk size in GB for Zabbix server"
  type        = number
  default     = 10
}

# VM Resources - Elasticsearch
variable "elastic_cores" {
  description = "Number of CPU cores for Elasticsearch server"
  type        = number
  default     = 2
}

variable "elastic_memory" {
  description = "Memory in GB for Elasticsearch server"
  type        = number
  default     = 4
}

variable "elastic_disk_size" {
  description = "Boot disk size in GB for Elasticsearch server"
  type        = number
  default     = 20
}

# VM Resources - Kibana
variable "kibana_cores" {
  description = "Number of CPU cores for Kibana server"
  type        = number
  default     = 2
}

variable "kibana_memory" {
  description = "Memory in GB for Kibana server"
  type        = number
  default     = 2
}

variable "kibana_disk_size" {
  description = "Boot disk size in GB for Kibana server"
  type        = number
  default     = 10
}

# -----------------------------------------------------------------------------
# Snapshot Configuration
# -----------------------------------------------------------------------------

variable "snapshot_retention_days" {
  description = "Number of days to retain snapshots"
  type        = number
  default     = 7

  validation {
    condition     = var.snapshot_retention_days >= 1 && var.snapshot_retention_days <= 365
    error_message = "Snapshot retention must be between 1 and 365 days."
  }
}

variable "snapshot_schedule_expression" {
  description = "Cron expression for snapshot schedule"
  type        = string
  default     = "0 0 * * *"  # Daily at midnight
}

# -----------------------------------------------------------------------------
# Tags/Labels
# -----------------------------------------------------------------------------

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "Project name for resource labeling"
  type        = string
  default     = "diploma"
}
