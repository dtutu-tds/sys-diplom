#!/bin/bash
# Скрипт для завершения установки Zabbix через создание конфигурационного файла

set -e

ZABBIX_IP="${1:-158.160.104.168}"

echo "=== Завершение установки Zabbix ==="
echo "Zabbix IP: $ZABBIX_IP"
echo

# Создать конфигурационный файл напрямую на сервере
echo "Создание конфигурационного файла zabbix.conf.php..."

ssh -o StrictHostKeyChecking=no ubuntu@${ZABBIX_IP} 'sudo tee /usr/share/zabbix/conf/zabbix.conf.php > /dev/null << EOF
<?php
// Zabbix GUI configuration file.

\$DB["TYPE"]     = "POSTGRESQL";
\$DB["SERVER"]   = "localhost";
\$DB["PORT"]     = "5432";
\$DB["DATABASE"] = "zabbix";
\$DB["USER"]     = "zabbix";
\$DB["PASSWORD"] = "zabbix_secure_password";

// Schema name. Used for PostgreSQL.
\$DB["SCHEMA"] = "";

\$ZBX_SERVER      = "localhost";
\$ZBX_SERVER_PORT = "10051";
\$ZBX_SERVER_NAME = "Diploma Zabbix Server";

\$IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;

// Uncomment and set to desired values to override Zabbix hostname/IP and port.
// \$ZBX_SERVER_NAME = "";
EOF
'

# Перезапустить PHP-FPM для применения изменений
ssh -o StrictHostKeyChecking=no ubuntu@${ZABBIX_IP} 'sudo systemctl restart php8.1-fpm'

echo "✓ Конфигурационный файл создан"

# Установить правильные права
ssh -o StrictHostKeyChecking=no ubuntu@${ZABBIX_IP} 'sudo chown www-data:www-data /usr/share/zabbix/conf/zabbix.conf.php'
ssh -o StrictHostKeyChecking=no ubuntu@${ZABBIX_IP} 'sudo chmod 640 /usr/share/zabbix/conf/zabbix.conf.php'

echo "✓ Права установлены"
echo
echo "=== Установка завершена ==="
echo
echo "Откройте веб-интерфейс: http://${ZABBIX_IP}"
echo "Логин: Admin"
echo "Пароль: zabbix"
