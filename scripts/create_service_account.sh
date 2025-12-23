#!/bin/bash
# Скрипт для создания сервисного аккаунта с ролью editor

set -e

echo "=== Создание сервисного аккаунта ==="
echo ""

# Проверка активного профиля
FOLDER_ID=$(yc config get folder-id)
if [ -z "$FOLDER_ID" ]; then
    echo "ERROR: Folder ID не настроен. Запустите scripts/init_yc.sh"
    exit 1
fi

echo "Folder ID: $FOLDER_ID"
echo ""

# Имя сервисного аккаунта
SA_NAME="sa-diploma"

# Проверка существования сервисного аккаунта
if yc iam service-account get "$SA_NAME" &>/dev/null; then
    echo "Сервисный аккаунт '$SA_NAME' уже существует"
    SA_ID=$(yc iam service-account get "$SA_NAME" --format json | grep "^id:" | awk '{print $2}')
else
    echo "Создание сервисного аккаунта '$SA_NAME'..."
    SA_ID=$(yc iam service-account create --name "$SA_NAME" --description "Service account for diploma project" --format json | grep "^id:" | awk '{print $2}')
    echo "Сервисный аккаунт создан: $SA_ID"
fi

echo ""
echo "Назначение роли 'editor' для каталога..."
yc resource-manager folder add-access-binding "$FOLDER_ID" \
    --role editor \
    --subject serviceAccount:"$SA_ID" 2>/dev/null || echo "Роль уже назначена"

echo ""
echo "Создание ключа доступа..."
KEY_FILE="sa-key.json"
if [ -f "$KEY_FILE" ]; then
    echo "Файл ключа $KEY_FILE уже существует. Удалить и создать новый? (y/n)"
    read -r ANSWER
    if [ "$ANSWER" = "y" ]; then
        rm "$KEY_FILE"
        yc iam key create --service-account-name "$SA_NAME" --output "$KEY_FILE"
        echo "Новый ключ создан: $KEY_FILE"
    fi
else
    yc iam key create --service-account-name "$SA_NAME" --output "$KEY_FILE"
    echo "Ключ создан: $KEY_FILE"
fi

echo ""
echo "=== Сервисный аккаунт настроен ==="
echo "Service Account ID: $SA_ID"
echo "Key file: $KEY_FILE"
echo ""
echo "Для использования с Terraform добавьте в terraform.tfvars:"
echo "service_account_key_file = \"../$KEY_FILE\""
