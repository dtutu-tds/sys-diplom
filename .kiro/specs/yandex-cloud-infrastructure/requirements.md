# Requirements Document

## Introduction

Разработка отказоустойчивой инфраструктуры для веб-сайта в Yandex Cloud с использованием Terraform и Ansible. Инфраструктура должна включать веб-серверы, мониторинг, сбор логов, резервное копирование и соответствовать стандартам безопасности.

## Glossary

- **Infrastructure**: Совокупность всех компонентов системы (ВМ, сети, балансировщики)
- **Web_Servers**: Виртуальные машины с установленным nginx для обслуживания веб-сайта
- **Load_Balancer**: Application Load Balancer Yandex Cloud для распределения трафика
- **Monitoring_System**: Система мониторинга на базе Zabbix
- **Log_System**: Система сбора и анализа логов на базе ELK Stack
- **Bastion_Host**: Сервер-посредник для безопасного доступа к внутренним ресурсам
- **Backup_System**: Система резервного копирования через snapshots
- **Security_Groups**: Правила сетевой безопасности Yandex Cloud
- **NAT_Gateway**: Шлюз для исходящего интернет-трафика из приватных сетей

## Requirements

### Requirement 1: Infrastructure Deployment

**User Story:** Как системный администратор, я хочу развернуть инфраструктуру с помощью Infrastructure as Code, чтобы обеспечить воспроизводимость и управляемость.

#### Acceptance Criteria

1. THE Infrastructure SHALL be deployed using Terraform for resource provisioning
2. THE Infrastructure SHALL be configured using Ansible for service setup
3. WHEN deploying infrastructure, THE System SHALL use FQDN names instead of IP addresses in Ansible inventory
4. THE Infrastructure SHALL use minimal VM configurations (2 cores 20% Intel Ice Lake, 2-4GB RAM, 10GB HDD)
5. THE Infrastructure SHALL NOT expose cloud tokens in version control

### Requirement 2: Web Server Setup

**User Story:** Как пользователь, я хочу получить доступ к веб-сайту через отказоустойчивую систему, чтобы сайт был всегда доступен.

#### Acceptance Criteria

1. THE System SHALL create two web server VMs in different availability zones
2. WHEN web servers are created, THE System SHALL install and configure nginx on each VM
3. THE Web_Servers SHALL serve identical static content
4. THE Web_Servers SHALL NOT have external IP addresses
5. THE Web_Servers SHALL be accessible only through the Load_Balancer

### Requirement 3: Load Balancer Configuration

**User Story:** Как пользователь, я хочу получить доступ к сайту через единую точку входа, чтобы система автоматически направляла запросы на доступные серверы.

#### Acceptance Criteria

1. THE System SHALL create a Target Group containing both web server VMs
2. THE System SHALL create a Backend Group with health checks on port 80, path "/"
3. THE System SHALL create an HTTP Router with path "/" pointing to the Backend Group
4. THE System SHALL create an Application Load Balancer with HTTP listener on port 80
5. WHEN accessing the load balancer public IP, THE System SHALL return web content from available servers

### Requirement 4: Monitoring System

**User Story:** Как системный администратор, я хочу мониторить состояние всех компонентов инфраструктуры, чтобы оперативно реагировать на проблемы.

#### Acceptance Criteria

1. THE System SHALL deploy Zabbix server on a dedicated VM
2. THE System SHALL install Zabbix agents on all VMs
3. THE Monitoring_System SHALL collect USE metrics (Utilization, Saturation, Errors) for CPU, RAM, disk, network
4. THE Monitoring_System SHALL monitor HTTP requests to web servers
5. THE Monitoring_System SHALL have configured dashboards with appropriate thresholds

### Requirement 5: Log Collection System

**User Story:** Как системный администратор, я хочу централизованно собирать и анализировать логи, чтобы диагностировать проблемы и анализировать работу системы.

#### Acceptance Criteria

1. THE System SHALL deploy Elasticsearch on a dedicated VM
2. THE System SHALL deploy Kibana on a dedicated VM with connection to Elasticsearch
3. THE System SHALL install Filebeat on web server VMs
4. THE Log_System SHALL collect nginx access.log and error.log from web servers
5. THE Log_System SHALL make logs searchable and analyzable through Kibana interface

### Requirement 6: Network Security

**User Story:** Как системный администратор, я хочу обеспечить безопасность сетевого доступа, чтобы минимизировать поверхность атак.

#### Acceptance Criteria

1. THE System SHALL deploy all resources in a single VPC
2. THE System SHALL place web servers and Elasticsearch in private subnets
3. THE System SHALL place Zabbix, Kibana, and Load Balancer in public subnets
4. THE System SHALL configure Security Groups allowing only necessary port access
5. THE System SHALL deploy a Bastion Host with only SSH port open for secure access to private resources
6. THE System SHALL provide internet access for private VMs through NAT Gateway

### Requirement 7: Backup System

**User Story:** Как системный администратор, я хочу автоматически создавать резервные копии, чтобы восстановить систему в случае сбоев.

#### Acceptance Criteria

1. THE Backup_System SHALL create daily snapshots of all VM disks
2. THE Backup_System SHALL limit snapshot retention to one week
3. THE Backup_System SHALL automatically schedule snapshot creation
4. WHEN snapshots are older than one week, THE System SHALL automatically delete them

### Requirement 8: Security Compliance

**User Story:** Как системный администратор, я хочу соблюдать стандарты безопасности, чтобы защитить инфраструктуру от несанкционированного доступа.

#### Acceptance Criteria

1. THE System SHALL NOT store cloud authentication tokens in version control
2. THE System SHALL use service accounts and key files for cloud authentication
3. THE System SHALL implement principle of least privilege for all network access
4. THE System SHALL require SSH key authentication for all server access
5. WHEN accessing private resources, THE System SHALL require connection through Bastion Host

### Requirement 9: High Availability

**User Story:** Как пользователь, я хочу, чтобы сайт был доступен даже при отказе одного из серверов, чтобы обеспечить непрерывность работы.

#### Acceptance Criteria

1. THE System SHALL distribute web servers across different availability zones
2. THE Load_Balancer SHALL automatically detect failed servers through health checks
3. WHEN one web server fails, THE System SHALL continue serving traffic from remaining servers
4. THE Load_Balancer SHALL automatically restore traffic to recovered servers
5. THE System SHALL maintain service availability during planned maintenance

### Requirement 10: Operational Readiness

**User Story:** Как системный администратор, я хочу иметь готовую к эксплуатации систему с документацией, чтобы эффективно управлять инфраструктурой.

#### Acceptance Criteria

1. THE System SHALL provide access to all web interfaces (site, Kibana, Zabbix)
2. THE System SHALL include documentation with screenshots and commands for verification
3. THE System SHALL provide clear deployment and configuration instructions
4. THE System SHALL include troubleshooting guides for common issues
5. WHEN presenting the work, THE System SHALL demonstrate all functional components