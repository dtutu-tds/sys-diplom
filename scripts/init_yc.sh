#!/bin/bash
# Скрипт для инициализации Yandex Cloud CLI

set -e

echo "=== Инициализация Yandex Cloud CLI ==="
echo ""

# Проверка установки yc CLI
if ! command -v yc &> /dev/null; then
    echo "ERROR: yc CLI не установлен"
    echo "Установите его с помощью:"
    echo "curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash"
    exit 1
fi

echo "yc CLI версия: $(yc --version)"
echo ""

# Создание профиля diploma
echo "Создание профиля 'diploma'..."
yc config profile create diploma 2>/dev/null || echo "Профиль 'diploma' уже существует"

# Активация профиля
yc config profile activate diploma

echo ""
echo "Введите ваш OAuth токен (получить можно на https://oauth.yandex.ru/authorize?response_type=token&client_id=1a6990aa636648e9b2ef855fa7bec2fb):"
read -s OAUTH_TOKEN

yc config set token "$OAUTH_TOKEN"

echo ""
echo "Доступные облака:"
yc resource-manager cloud list

echo ""
echo "Введите Cloud ID:"
read CLOUD_ID
yc config set cloud-id "$CLOUD_ID"

echo ""
echo "Доступные каталоги:"
yc resource-manager folder list

echo ""
echo "Введите Folder ID:"
read FOLDER_ID
yc config set folder-id "$FOLDER_ID"

echo ""
echo "Установка зоны по умолчанию: ru-central1-a"
yc config set compute-default-zone ru-central1-a

echo ""
echo "=== Конфигурация завершена ==="
yc config list

echo ""
echo "Профиль 'diploma' настроен и активирован!"
