#!/bin/bash

# =============================================================================
# Comprehensive Service Testing Script
# =============================================================================
# This script tests all web interfaces and services in the infrastructure
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get current IP addresses from Terraform output
echo -e "${BLUE}Getting current IP addresses from Terraform...${NC}"
cd terraform

# Extract IP addresses from Terraform output
ALB_IP=$(terraform output -raw alb_public_ip 2>/dev/null || echo "")
ZABBIX_IP=$(terraform output -raw zabbix_public_ip 2>/dev/null || echo "")
KIBANA_IP=$(terraform output -raw kibana_public_ip 2>/dev/null || echo "")
BASTION_IP=$(terraform output -raw bastion_public_ip 2>/dev/null || echo "")

cd ..

# Check if we got the IPs
if [ -z "$ALB_IP" ] || [ -z "$ZABBIX_IP" ] || [ -z "$KIBANA_IP" ] || [ -z "$BASTION_IP" ]; then
    echo -e "${RED}Error: Could not retrieve IP addresses from Terraform output${NC}"
    echo -e "${YELLOW}Please ensure Terraform state is available and infrastructure is deployed${NC}"
    exit 1
fi

echo -e "${GREEN}Current IP addresses:${NC}"
echo -e "  ALB: $ALB_IP"
echo -e "  Zabbix: $ZABBIX_IP"
echo -e "  Kibana: $KIBANA_IP"
echo -e "  Bastion: $BASTION_IP"

WEBSITE_URL="http://${ALB_IP}"
ZABBIX_URL="http://${ZABBIX_IP}"
KIBANA_URL="http://${KIBANA_IP}:5601"

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_TESTS=()

# Function to print test header
print_test_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

# Function to print test result
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ PASS:${NC} $2"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL:${NC} $2"
        ((TESTS_FAILED++))
        FAILED_TESTS+=("$2")
    fi
}

# Function to test HTTP endpoint
test_http_endpoint() {
    local url=$1
    local description=$2
    local expected_status=${3:-200}
    local timeout=${4:-10}
    
    echo -e "${YELLOW}Testing:${NC} $description"
    echo -e "${YELLOW}URL:${NC} $url"
    
    if response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout $timeout --max-time $timeout "$url" 2>/dev/null); then
        if [ "$response" = "$expected_status" ]; then
            print_result 0 "$description (HTTP $response)"
            return 0
        else
            print_result 1 "$description (Expected HTTP $expected_status, got HTTP $response)"
            return 1
        fi
    else
        print_result 1 "$description (Connection failed or timeout)"
        return 1
    fi
}

# Function to test service with content check
test_service_content() {
    local url=$1
    local description=$2
    local search_pattern=$3
    local timeout=${4:-10}
    
    echo -e "${YELLOW}Testing:${NC} $description"
    echo -e "${YELLOW}URL:${NC} $url"
    echo -e "${YELLOW}Looking for:${NC} $search_pattern"
    
    if content=$(curl -s --connect-timeout $timeout --max-time $timeout "$url" 2>/dev/null); then
        if echo "$content" | grep -q "$search_pattern"; then
            print_result 0 "$description (Content found)"
            return 0
        else
            print_result 1 "$description (Expected content not found)"
            echo -e "${YELLOW}Response preview:${NC} $(echo "$content" | head -c 200)..."
            return 1
        fi
    else
        print_result 1 "$description (Connection failed or timeout)"
        return 1
    fi
}

# Function to test SSH connectivity
test_ssh_connectivity() {
    local host=$1
    local description=$2
    
    echo -e "${YELLOW}Testing:${NC} $description"
    echo -e "${YELLOW}Host:${NC} $host"
    
    if timeout 10 nc -z "$host" 22 2>/dev/null; then
        print_result 0 "$description (SSH port accessible)"
        return 0
    else
        print_result 1 "$description (SSH port not accessible)"
        return 1
    fi
}

# =============================================================================
# Main Testing Sequence
# =============================================================================

echo -e "${BLUE}Starting comprehensive service testing...${NC}"
echo -e "${BLUE}Timestamp: $(date)${NC}"

# Test 1: Main Website (Load Balancer)
print_test_header "1. Main Website Testing"
test_http_endpoint "$WEBSITE_URL" "Main website accessibility"
test_service_content "$WEBSITE_URL" "Website content verification" "nginx\|html\|web"

# Test 2: Zabbix Web Interface
print_test_header "2. Zabbix Monitoring System"
test_http_endpoint "$ZABBIX_URL" "Zabbix web interface accessibility"
test_service_content "$ZABBIX_URL" "Zabbix login page verification" "Zabbix\|login\|username"

# Test 3: Kibana Web Interface
print_test_header "3. Kibana Logging Interface"
test_http_endpoint "$KIBANA_URL" "Kibana web interface accessibility"
test_service_content "$KIBANA_URL" "Kibana interface verification" "Kibana\|Elastic\|loading"

# Test 4: SSH Connectivity
print_test_header "4. SSH Connectivity Testing"
test_ssh_connectivity "$BASTION_IP" "Bastion host SSH accessibility"
test_ssh_connectivity "$ZABBIX_IP" "Zabbix server SSH accessibility"
test_ssh_connectivity "$KIBANA_IP" "Kibana server SSH accessibility"

# Test 5: Load Balancer Health
print_test_header "5. Load Balancer Health Testing"
echo -e "${YELLOW}Testing load balancer distribution...${NC}"
for i in {1..5}; do
    echo -e "${YELLOW}Request $i:${NC}"
    if response=$(curl -s --connect-timeout 5 --max-time 5 "$WEBSITE_URL" 2>/dev/null); then
        server_info=$(echo "$response" | grep -o "web[0-9]\|server[0-9]\|hostname" | head -1)
        echo -e "  Response received (${server_info:-content found})"
    else
        echo -e "  ${RED}Request failed${NC}"
    fi
done

# Test 6: Service Port Accessibility
print_test_header "6. Service Port Testing"
echo -e "${YELLOW}Testing service ports...${NC}"

# Test Zabbix ports
if timeout 5 nc -z "$ZABBIX_IP" 80 2>/dev/null; then
    print_result 0 "Zabbix HTTP port (80) accessible"
else
    print_result 1 "Zabbix HTTP port (80) not accessible"
fi

# Test Kibana port
if timeout 5 nc -z "$KIBANA_IP" 5601 2>/dev/null; then
    print_result 0 "Kibana port (5601) accessible"
else
    print_result 1 "Kibana port (5601) not accessible"
fi

# Test ALB port
if timeout 5 nc -z "$ALB_IP" 80 2>/dev/null; then
    print_result 0 "Load Balancer HTTP port (80) accessible"
else
    print_result 1 "Load Balancer HTTP port (80) not accessible"
fi

# =============================================================================
# Test Summary
# =============================================================================

print_test_header "Test Summary"
echo -e "${BLUE}Total tests run: $((TESTS_PASSED + TESTS_FAILED))${NC}"
echo -e "${GREEN}Tests passed: $TESTS_PASSED${NC}"
echo -e "${RED}Tests failed: $TESTS_FAILED${NC}"

if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "\n${RED}Failed tests:${NC}"
    for test in "${FAILED_TESTS[@]}"; do
        echo -e "  ${RED}✗${NC} $test"
    done
    echo -e "\n${YELLOW}Please check the failed services and retry.${NC}"
    exit 1
else
    echo -e "\n${GREEN}🎉 All tests passed! Infrastructure is healthy.${NC}"
    exit 0
fi