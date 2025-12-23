#!/bin/bash

# =============================================================================
# Service Status Report
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Infrastructure Service Status Report ===${NC}"
echo -e "${BLUE}Generated: $(date)${NC}\n"

# Get current IP addresses from Terraform output
cd terraform
ALB_IP=$(terraform output -raw alb_public_ip 2>/dev/null || echo "N/A")
ZABBIX_IP=$(terraform output -raw zabbix_public_ip 2>/dev/null || echo "N/A")
KIBANA_IP=$(terraform output -raw kibana_public_ip 2>/dev/null || echo "N/A")
BASTION_IP=$(terraform output -raw bastion_public_ip 2>/dev/null || echo "N/A")
cd ..

echo -e "${YELLOW}Infrastructure Endpoints:${NC}"
echo -e "  Main Website: http://$ALB_IP"
echo -e "  Zabbix:       http://$ZABBIX_IP"
echo -e "  Kibana:       http://$KIBANA_IP:5601"
echo -e "  Bastion SSH:  ssh ubuntu@$BASTION_IP"

echo -e "\n${YELLOW}Service Status:${NC}"

# Test Main Website
echo -n "  Main Website (ALB + Web Servers): "
if response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 --max-time 5 "http://$ALB_IP" 2>/dev/null); then
    if [ "$response" = "200" ]; then
        echo -e "${GREEN}✓ WORKING${NC} (HTTP $response)"
    else
        echo -e "${YELLOW}⚠ PARTIAL${NC} (HTTP $response)"
    fi
else
    echo -e "${RED}✗ FAILED${NC} (Connection failed)"
fi

# Test Kibana
echo -n "  Kibana (ELK Stack):                "
if response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 --max-time 5 "http://$KIBANA_IP:5601" 2>/dev/null); then
    if [ "$response" = "302" ] || [ "$response" = "200" ]; then
        echo -e "${GREEN}✓ WORKING${NC} (HTTP $response)"
    else
        echo -e "${YELLOW}⚠ PARTIAL${NC} (HTTP $response)"
    fi
else
    echo -e "${RED}✗ FAILED${NC} (Connection failed)"
fi

# Test Zabbix
echo -n "  Zabbix (Monitoring):               "
if response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 --max-time 5 "http://$ZABBIX_IP" 2>/dev/null); then
    if [ "$response" = "200" ] || [ "$response" = "302" ]; then
        echo -e "${GREEN}✓ WORKING${NC} (HTTP $response)"
    else
        echo -e "${YELLOW}⚠ PARTIAL${NC} (HTTP $response)"
    fi
else
    echo -e "${RED}✗ FAILED${NC} (Connection failed)"
fi

# Test SSH
echo -n "  Bastion SSH Access:                "
if timeout 3 nc -z "$BASTION_IP" 22 2>/dev/null; then
    echo -e "${GREEN}✓ WORKING${NC} (Port 22 open)"
else
    echo -e "${RED}✗ FAILED${NC} (Port 22 not accessible)"
fi

echo -e "\n${YELLOW}Data Collection Status:${NC}"

# Check if we can connect to servers to verify services
echo -n "  Web Server nginx:                  "
if ansible web -i ansible/inventories/prod.yml -m shell -a "systemctl is-active nginx" --become 2>/dev/null | grep -q "SUCCESS"; then
    echo -e "${GREEN}✓ RUNNING${NC}"
else
    echo -e "${YELLOW}⚠ CHECKING${NC}"
fi

echo -n "  Elasticsearch:                     "
if ansible elk -i ansible/inventories/prod.yml -m shell -a "systemctl is-active elasticsearch" --become 2>/dev/null | grep -q "SUCCESS"; then
    echo -e "${GREEN}✓ RUNNING${NC}"
else
    echo -e "${YELLOW}⚠ CHECKING${NC}"
fi

echo -n "  Filebeat (Log Collection):         "
if ansible web -i ansible/inventories/prod.yml -m shell -a "systemctl is-active filebeat" --become 2>/dev/null | grep -q "SUCCESS"; then
    echo -e "${GREEN}✓ RUNNING${NC}"
else
    echo -e "${YELLOW}⚠ CHECKING${NC}"
fi

echo -e "\n${YELLOW}Next Steps:${NC}"
echo -e "  1. Configure Zabbix server (if needed)"
echo -e "  2. Set up monitoring dashboards"
echo -e "  3. Configure backup schedules"
echo -e "  4. Test failover scenarios"

echo -e "\n${BLUE}=== Report Complete ===${NC}"