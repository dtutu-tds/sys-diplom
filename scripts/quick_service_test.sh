#!/bin/bash

# =============================================================================
# Quick Service Testing Script
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get current IP addresses from Terraform output
echo -e "${BLUE}Getting current IP addresses from Terraform...${NC}"
cd terraform

ALB_IP=$(terraform output -raw alb_public_ip 2>/dev/null || echo "")
ZABBIX_IP=$(terraform output -raw zabbix_public_ip 2>/dev/null || echo "")
KIBANA_IP=$(terraform output -raw kibana_public_ip 2>/dev/null || echo "")
BASTION_IP=$(terraform output -raw bastion_public_ip 2>/dev/null || echo "")

cd ..

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

# Function to print test result
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ PASS:${NC} $2"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL:${NC} $2"
        ((TESTS_FAILED++))
    fi
}

# Function to test HTTP endpoint
test_http_endpoint() {
    local url=$1
    local description=$2
    local timeout=${3:-10}
    
    echo -e "\n${YELLOW}Testing:${NC} $description"
    echo -e "${YELLOW}URL:${NC} $url"
    
    if response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout $timeout --max-time $timeout "$url" 2>/dev/null); then
        if [ "$response" = "200" ] || [ "$response" = "302" ]; then
            print_result 0 "$description (HTTP $response)"
            return 0
        else
            print_result 1 "$description (HTTP $response)"
            return 1
        fi
    else
        print_result 1 "$description (Connection failed)"
        return 1
    fi
}

echo -e "\n${BLUE}=== Quick Service Testing ===${NC}"

# Test 1: Main Website
test_http_endpoint "$WEBSITE_URL" "Main website"

# Test 2: Zabbix (may not be configured yet)
test_http_endpoint "$ZABBIX_URL" "Zabbix web interface"

# Test 3: Kibana
test_http_endpoint "$KIBANA_URL" "Kibana web interface"

# Test 4: SSH Connectivity
echo -e "\n${YELLOW}Testing SSH connectivity...${NC}"
if timeout 5 nc -z "$BASTION_IP" 22 2>/dev/null; then
    print_result 0 "Bastion SSH port accessible"
else
    print_result 1 "Bastion SSH port not accessible"
fi

# Summary
echo -e "\n${BLUE}=== Test Summary ===${NC}"
echo -e "${GREEN}Tests passed: $TESTS_PASSED${NC}"
echo -e "${RED}Tests failed: $TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}🎉 All tests passed!${NC}"
else
    echo -e "\n${YELLOW}Some services may need configuration.${NC}"
fi