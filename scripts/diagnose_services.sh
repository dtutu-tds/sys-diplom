#!/bin/bash

# =============================================================================
# Service Diagnostics Script
# =============================================================================
# This script provides detailed diagnostics for each service
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

# Function to test connectivity with detailed output
test_connectivity() {
    local host=$1
    local port=$2
    local service=$3
    
    echo -e "\n${BLUE}=== Testing $service connectivity ===${NC}"
    echo -e "${YELLOW}Host: $host:$port${NC}"
    
    # Test basic connectivity
    echo -e "${YELLOW}Testing basic connectivity...${NC}"
    if timeout 10 nc -z "$host" "$port" 2>/dev/null; then
        echo -e "${GREEN}✓ Port $port is open${NC}"
    else
        echo -e "${RED}✗ Port $port is not accessible${NC}"
        return 1
    fi
    
    # Test HTTP response if it's a web service
    if [ "$port" = "80" ] || [ "$port" = "5601" ]; then
        echo -e "${YELLOW}Testing HTTP response...${NC}"
        local url="http://$host"
        if [ "$port" != "80" ]; then
            url="http://$host:$port"
        fi
        
        if [ "$service" = "Zabbix" ]; then
            url="$url/zabbix"
        fi
        
        echo -e "${YELLOW}URL: $url${NC}"
        
        # Get HTTP status code
        if status_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 --max-time 10 "$url" 2>/dev/null); then
            echo -e "${GREEN}✓ HTTP Status: $status_code${NC}"
            
            # Get response headers
            echo -e "${YELLOW}Response headers:${NC}"
            curl -s -I --connect-timeout 10 --max-time 10 "$url" 2>/dev/null | head -5
            
            # Get first few lines of content
            echo -e "${YELLOW}Response content preview:${NC}"
            curl -s --connect-timeout 10 --max-time 10 "$url" 2>/dev/null | head -c 300 | tr -d '\0'
            echo ""
        else
            echo -e "${RED}✗ HTTP request failed${NC}"
        fi
    fi
}

# Test each service
test_connectivity "$ALB_IP" "80" "Load Balancer"
test_connectivity "$ZABBIX_IP" "80" "Zabbix"
test_connectivity "$KIBANA_IP" "5601" "Kibana"
test_connectivity "$BASTION_IP" "22" "Bastion SSH"

# Additional network diagnostics
echo -e "\n${BLUE}=== Additional Network Diagnostics ===${NC}"

echo -e "${YELLOW}Testing DNS resolution...${NC}"
for ip in "$ALB_IP" "$ZABBIX_IP" "$KIBANA_IP" "$BASTION_IP"; do
    if host_info=$(dig +short -x "$ip" 2>/dev/null); then
        echo -e "  $ip -> $host_info"
    else
        echo -e "  $ip -> No reverse DNS"
    fi
done

echo -e "\n${YELLOW}Testing ping connectivity...${NC}"
for ip in "$ALB_IP" "$ZABBIX_IP" "$KIBANA_IP" "$BASTION_IP"; do
    if ping -c 1 -W 3 "$ip" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ $ip is reachable${NC}"
    else
        echo -e "${RED}✗ $ip is not reachable${NC}"
    fi
done

echo -e "\n${BLUE}Diagnostics complete.${NC}"