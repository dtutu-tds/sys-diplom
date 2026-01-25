#!/bin/bash
# Скрипт для автоматической настройки мониторинга в Zabbix

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=== Настройка мониторинга в Zabbix ==="
echo

# Проверка наличия Python
if ! command -v python3 &> /dev/null; then
    echo "Ошибка: Python 3 не установлен"
    exit 1
fi

# Проверка наличия библиотеки requests
if ! python3 -c "import requests" 2>/dev/null; then
    echo "Установка библиотеки requests..."
    pip3 install requests
fi

# Получение IP адресов из Terraform
echo "Получение IP адресов из Terraform..."
cd "$PROJECT_ROOT/terraform"

if [ ! -f "terraform.tfstate" ]; then
    echo "Ошибка: terraform.tfstate не найден. Сначала выполните terraform apply"
    exit 1
fi

ALB_IP=$(terraform output -raw alb_public_ip 2>/dev/null || echo "")
ZABBIX_IP=$(terraform output -raw zabbix_public_ip 2>/dev/null || echo "")

if [ -z "$ALB_IP" ] || [ -z "$ZABBIX_IP" ]; then
    echo "Ошибка: Не удалось получить IP адреса из Terraform"
    echo "ALB_IP: $ALB_IP"
    echo "ZABBIX_IP: $ZABBIX_IP"
    exit 1
fi

echo "ALB IP: $ALB_IP"
echo "Zabbix IP: $ZABBIX_IP"
echo

# Запрос учетных данных
read -p "Имя пользователя Zabbix [Admin]: " ZABBIX_USER
ZABBIX_USER=${ZABBIX_USER:-Admin}

read -sp "Пароль Zabbix [zabbix]: " ZABBIX_PASS
ZABBIX_PASS=${ZABBIX_PASS:-zabbix}
echo
echo

# Запуск скрипта настройки
echo "Запуск настройки мониторинга..."
cd "$PROJECT_ROOT"

python3 scripts/configure_zabbix_monitoring.py \
    --zabbix-url "http://${ZABBIX_IP}" \
    --username "${ZABBIX_USER}" \
    --password "${ZABBIX_PASS}" \
    --alb-ip "${ALB_IP}"

echo
echo "=== Настройка завершена ==="
echo
echo "Откройте веб-интерфейс Zabbix: http://${ZABBIX_IP}"
echo "Проверьте статус хостов: Monitoring → Hosts"
echo "Проверьте веб-сценарий: Monitoring → Web"
