#!/bin/bash
# Скрипт для генерации Ansible inventory из Terraform outputs

set -e

echo "=== Генерация Ansible inventory ==="
echo ""

cd terraform

# Проверка наличия state
if [ ! -f "terraform.tfstate" ]; then
    echo "ERROR: terraform.tfstate не найден. Сначала выполните 'terraform apply'"
    exit 1
fi

# Получение outputs
echo "Получение IP-адресов из Terraform..."
BASTION_IP=$(terraform output -raw bastion_public_ip 2>/dev/null || echo "")
ZABBIX_IP=$(terraform output -raw zabbix_public_ip 2>/dev/null || echo "")
KIBANA_IP=$(terraform output -raw kibana_public_ip 2>/dev/null || echo "")
KIBANA_PRIVATE_IP=$(terraform output -raw kibana_private_ip 2>/dev/null || echo "")
WEB1_IP=$(terraform output -raw web1_private_ip 2>/dev/null || echo "")
WEB2_IP=$(terraform output -raw web2_private_ip 2>/dev/null || echo "")
ELASTIC_IP=$(terraform output -raw elastic_private_ip 2>/dev/null || echo "")

cd ..

# Проверка наличия IP-адресов
if [ -z "$BASTION_IP" ]; then
    echo "ERROR: Не удалось получить IP-адреса. Проверьте terraform outputs"
    exit 1
fi

# Создание inventory
INVENTORY_FILE="ansible/inventories/prod.yml"

cat > "$INVENTORY_FILE" <<EOF
all:
  vars:
    ansible_user: ubuntu
    ansible_ssh_private_key_file: ~/.ssh/id_ed25519
    ansible_ssh_common_args: '-o StrictHostKeyChecking=no -o ProxyCommand="ssh -i ~/.ssh/id_ed25519 -W %h:%p -q ubuntu@${BASTION_IP}"'
  
  children:
    bastion:
      hosts:
        bastion.ru-central1.internal:
          ansible_host: ${BASTION_IP}
          ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
    
    web:
      hosts:
        web1.ru-central1.internal:
          ansible_host: ${WEB1_IP}
        web2.ru-central1.internal:
          ansible_host: ${WEB2_IP}
    
    elk:
      hosts:
        elastic.ru-central1.internal:
          ansible_host: ${ELASTIC_IP}
        kibana.ru-central1.internal:
          ansible_host: ${KIBANA_PRIVATE_IP}
    
    zabbix:
      hosts:
        zabbix.ru-central1.internal:
          ansible_host: ${ZABBIX_IP}
          ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
EOF

echo "Inventory создан: $INVENTORY_FILE"
echo ""
echo "IP-адреса:"
echo "  Bastion: $BASTION_IP"
echo "  Zabbix:  $ZABBIX_IP"
echo "  Kibana:  $KIBANA_IP (public), $KIBANA_PRIVATE_IP (private)"
echo "  Web1:    $WEB1_IP"
echo "  Web2:    $WEB2_IP"
echo "  Elastic: $ELASTIC_IP"
echo ""
echo "Проверьте доступность хостов:"
echo "  ansible all -m ping"
