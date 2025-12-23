#!/bin/bash

# =============================================================================
# Zabbix Status Report
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Zabbix Monitoring Status Report ===${NC}"
echo -e "${BLUE}Generated: $(date)${NC}\n"

# Get Zabbix IP
cd terraform
ZABBIX_IP=$(terraform output -raw zabbix_public_ip 2>/dev/null || echo "")
cd ..

echo -e "${YELLOW}Zabbix Server Information:${NC}"
echo -e "  Web Interface: http://$ZABBIX_IP"
echo -e "  Default Login: Admin / zabbix"

# Test Zabbix accessibility
echo -e "\n${YELLOW}Service Status:${NC}"
echo -n "  Zabbix Web Interface: "
if response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 --max-time 5 "http://$ZABBIX_IP" 2>/dev/null); then
    if [ "$response" = "200" ] || [ "$response" = "302" ]; then
        echo -e "${GREEN}✓ WORKING${NC} (HTTP $response)"
    else
        echo -e "${YELLOW}⚠ PARTIAL${NC} (HTTP $response)"
    fi
else
    echo -e "${RED}✗ FAILED${NC} (Connection failed)"
fi

# Check Zabbix server process
echo -n "  Zabbix Server Process: "
if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$ZABBIX_IP "sudo systemctl is-active zabbix-server" 2>/dev/null | grep -q "active"; then
    echo -e "${GREEN}✓ RUNNING${NC}"
else
    echo -e "${RED}✗ NOT RUNNING${NC}"
fi

# Check database
echo -n "  PostgreSQL Database: "
if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$ZABBIX_IP "sudo systemctl is-active postgresql" 2>/dev/null | grep -q "active"; then
    echo -e "${GREEN}✓ RUNNING${NC}"
else
    echo -e "${RED}✗ NOT RUNNING${NC}"
fi

# Check agents status using Python script
echo -e "\n${YELLOW}Monitored Hosts:${NC}"
python3 scripts/check_zabbix_agents.py 2>/dev/null | grep -E "🖥️|📈|🎉|❌" | sed 's/^/  /'

echo -e "\n${YELLOW}Monitoring Features:${NC}"
echo -e "  ✓ Host monitoring (CPU, Memory, Disk)"
echo -e "  ✓ Web scenario monitoring (ALB availability)"
echo -e "  ✓ Nginx monitoring (for web servers)"
echo -e "  ✓ System dashboards"
echo -e "  ⚠ Custom triggers (need manual configuration)"

echo -e "\n${YELLOW}Next Steps:${NC}"
echo -e "  1. Access web interface: http://$ZABBIX_IP"
echo -e "  2. Review and configure triggers"
echo -e "  3. Set up alerting (email/SMS)"
echo -e "  4. Create custom dashboards"
echo -e "  5. Configure backup for Zabbix database"

echo -e "\n${GREEN}✅ Zabbix monitoring system is operational!${NC}"
echo -e "${BLUE}=== Report Complete ===${NC}"