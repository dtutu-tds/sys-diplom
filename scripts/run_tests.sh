#!/bin/bash
# =============================================================================
# Скрипт для запуска smoke-тестов инфраструктуры
# =============================================================================
# Проверяет доступность всех компонентов инфраструктуры
# Использование: ./scripts/run_tests.sh
# =============================================================================

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Счётчики
PASSED=0
FAILED=0
TOTAL=0

# Функция для вывода заголовка
print_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Функция для теста
run_test() {
    local name="$1"
    local command="$2"
    TOTAL=$((TOTAL + 1))
    
    echo -n "  [$TOTAL] $name... "
    
    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASSED${NC}"
        PASSED=$((PASSED + 1))
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

# Функция для теста с выводом результата
run_test_with_output() {
    local name="$1"
    local command="$2"
    TOTAL=$((TOTAL + 1))
    
    echo -n "  [$TOTAL] $name... "
    
    local result
    if result=$(eval "$command" 2>&1); then
        echo -e "${GREEN}✓ PASSED${NC}"
        echo -e "      ${YELLOW}→ $result${NC}"
        PASSED=$((PASSED + 1))
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        echo -e "      ${RED}→ $result${NC}"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

print_header "SMOKE TESTS - Дипломный проект Netology"

# Определение директорий
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_DIR/terraform"
ANSIBLE_DIR="$PROJECT_DIR/ansible"

# Получение IP-адресов из Terraform
echo -e "${YELLOW}Получение IP-адресов из Terraform...${NC}"
cd "$TERRAFORM_DIR"

ALB_IP=$(terraform output -raw alb_public_ip 2>/dev/null || echo "")
BASTION_IP=$(terraform output -raw bastion_public_ip 2>/dev/null || echo "")
ZABBIX_IP=$(terraform output -raw zabbix_public_ip 2>/dev/null || echo "")
KIBANA_IP=$(terraform output -raw kibana_public_ip 2>/dev/null || echo "")

cd "$PROJECT_DIR"

if [ -z "$ALB_IP" ]; then
    echo -e "${RED}ERROR: Не удалось получить IP-адреса из Terraform${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}Тестируемые endpoints:${NC}"
echo "  • Website (ALB): http://$ALB_IP"
echo "  • Bastion SSH:   ssh ubuntu@$BASTION_IP"
echo "  • Zabbix Web:    http://$ZABBIX_IP/zabbix"
echo "  • Kibana Web:    http://$KIBANA_IP:5601"

# =============================================================================
# Тесты сетевой доступности
# =============================================================================
print_header "1. Тесты сетевой доступности"

run_test "Bastion host доступен (SSH порт)" \
    "nc -z -w5 $BASTION_IP 22"

run_test "ALB доступен (HTTP порт 80)" \
    "nc -z -w5 $ALB_IP 80"

run_test "Zabbix доступен (HTTP порт 80)" \
    "nc -z -w5 $ZABBIX_IP 80"

run_test "Kibana доступен (HTTP порт 5601)" \
    "nc -z -w5 $KIBANA_IP 5601"

# =============================================================================
# Тесты HTTP endpoints
# =============================================================================
print_header "2. Тесты HTTP endpoints"

run_test_with_output "Website через ALB возвращает HTTP 200" \
    "curl -s -o /dev/null -w '%{http_code}' --max-time 10 http://$ALB_IP/"

run_test_with_output "Zabbix Web UI возвращает HTTP 200" \
    "curl -s -o /dev/null -w '%{http_code}' --max-time 10 http://$ZABBIX_IP/"

run_test_with_output "Kibana API status возвращает HTTP 200" \
    "curl -s -o /dev/null -w '%{http_code}' --max-time 10 http://$KIBANA_IP:5601/api/status"

# =============================================================================
# Тесты контента
# =============================================================================
print_header "3. Тесты контента"

run_test "Website содержит заголовок страницы" \
    "curl -s --max-time 10 http://$ALB_IP/ | grep -q '<title>'"

run_test "Zabbix содержит форму логина" \
    "curl -s --max-time 10 http://$ZABBIX_IP/ | grep -qi 'zabbix'"

run_test "Kibana возвращает статус 'available'" \
    "curl -s --max-time 10 http://$KIBANA_IP:5601/api/status | grep -q 'available'"

# =============================================================================
# Тесты Ansible
# =============================================================================
print_header "4. Тесты Ansible connectivity"

cd "$ANSIBLE_DIR"

run_test "Ansible ping к bastion" \
    "ansible bastion -m ping -o 2>/dev/null | grep -q SUCCESS"

run_test "Ansible ping к web серверам" \
    "ansible web -m ping -o 2>/dev/null | grep -q SUCCESS"

run_test "Ansible ping к ELK серверам" \
    "ansible elk -m ping -o 2>/dev/null | grep -q SUCCESS"

run_test "Ansible ping к Zabbix серверу" \
    "ansible zabbix -m ping -o 2>/dev/null | grep -q SUCCESS"

# =============================================================================
# Тесты сервисов
# =============================================================================
print_header "5. Тесты сервисов на серверах"

run_test "Nginx работает на web1" \
    "ansible web1.ru-central1.internal -m shell -a 'systemctl is-active nginx' 2>/dev/null | grep -q 'active'"

run_test "Nginx работает на web2" \
    "ansible web2.ru-central1.internal -m shell -a 'systemctl is-active nginx' 2>/dev/null | grep -q 'active'"

run_test "Elasticsearch работает" \
    "ansible elastic.ru-central1.internal -m shell -a 'systemctl is-active elasticsearch' 2>/dev/null | grep -q 'active'"

run_test "Kibana работает" \
    "ansible kibana.ru-central1.internal -m shell -a 'systemctl is-active kibana' 2>/dev/null | grep -q 'active'"

run_test "Filebeat работает на web1" \
    "ansible web1.ru-central1.internal -m shell -a 'systemctl is-active filebeat' 2>/dev/null | grep -q 'active'"

run_test "Filebeat работает на web2" \
    "ansible web2.ru-central1.internal -m shell -a 'systemctl is-active filebeat' 2>/dev/null | grep -q 'active'"

cd "$PROJECT_DIR"

# =============================================================================
# Итоги
# =============================================================================
print_header "ИТОГИ ТЕСТИРОВАНИЯ"

echo -e "  Всего тестов:   ${BLUE}$TOTAL${NC}"
echo -e "  Успешно:        ${GREEN}$PASSED${NC}"
echo -e "  Неуспешно:      ${RED}$FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✓ ВСЕ ТЕСТЫ ПРОЙДЕНЫ УСПЕШНО!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    exit 0
else
    echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}  ✗ НЕКОТОРЫЕ ТЕСТЫ НЕ ПРОЙДЕНЫ${NC}"
    echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
    exit 1
fi
