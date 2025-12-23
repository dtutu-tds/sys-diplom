#!/bin/bash

# =============================================================================
# Zabbix Initial Setup Script
# =============================================================================
# This script completes the initial Zabbix setup by creating the config file
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ZABBIX_IP="178.154.240.244"

echo -e "${BLUE}=== Zabbix Initial Setup ===${NC}"
echo -e "${YELLOW}Zabbix Server: http://$ZABBIX_IP${NC}"

# Check if Zabbix is accessible
echo -e "\n${YELLOW}Checking Zabbix accessibility...${NC}"
if ! curl -s -o /dev/null -w "%{http_code}" "http://$ZABBIX_IP/" | grep -q "302"; then
    echo -e "${RED}✗ Zabbix server is not accessible${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Zabbix server is accessible${NC}"

# Create Zabbix configuration file directly on the server
echo -e "\n${YELLOW}Creating Zabbix configuration file...${NC}"
ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ubuntu@$ZABBIX_IP << 'EOF'
sudo tee /usr/share/zabbix/conf/zabbix.conf.php > /dev/null << 'CONFIG'
<?php
// Zabbix GUI configuration file.

$DB['TYPE']				= 'POSTGRESQL';
$DB['SERVER']			= 'localhost';
$DB['PORT']				= '5432';
$DB['DATABASE']			= 'zabbix';
$DB['USER']				= 'zabbix';
$DB['PASSWORD']			= 'zabbix_secure_password';

// Schema name. Used for PostgreSQL.
$DB['SCHEMA']			= '';

// Used for TLS connection.
$DB['ENCRYPTION']		= false;
$DB['KEY_FILE']			= '';
$DB['CERT_FILE']		= '';
$DB['CA_FILE']			= '';
$DB['VERIFY_HOST']		= false;

// Use IEEE754 compatible value range for 64-bit Numeric (float) history values.
// This option is enabled by default for new Zabbix installations.
// For upgraded installations, please read database upgrade notes before enabling this option.
$DB['DOUBLE_IEEE754']	= true;

$ZBX_SERVER			= 'localhost';
$ZBX_SERVER_PORT		= '10051';
$ZBX_SERVER_NAME		= 'Zabbix Server';

$IMAGE_FORMAT_DEFAULT	= IMAGE_FORMAT_PNG;

// Uncomment this block only if you are using Elasticsearch.
// Elasticsearch url (can be string if same url is used for all types).
//$HISTORY['url'] = [
//	'uint' => 'http://localhost:9200',
//	'text' => 'http://localhost:9200'
//];
// Value types stored in Elasticsearch.
//$HISTORY['types'] = ['uint', 'text'];

// Used for SAML authentication.
// Uncomment to override the default paths to SP private key, SP and IdP X.509 certificates, and to set extra settings.
//$SSO['SP_KEY']			= 'conf/certs/sp.key';
//$SSO['SP_CERT']			= 'conf/certs/sp.crt';
//$SSO['IDP_CERT']		= 'conf/certs/idp.crt';
//$SSO['SETTINGS']		= [];
CONFIG

# Set proper permissions
sudo chown www-data:www-data /usr/share/zabbix/conf/zabbix.conf.php
sudo chmod 644 /usr/share/zabbix/conf/zabbix.conf.php

echo "✓ Zabbix configuration file created"
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Zabbix configuration file created successfully${NC}"
else
    echo -e "${RED}✗ Failed to create Zabbix configuration file${NC}"
    exit 1
fi

# Test Zabbix web interface
echo -e "\n${YELLOW}Testing Zabbix web interface...${NC}"
sleep 2

if curl -s "http://$ZABBIX_IP/" | grep -q "Zabbix"; then
    echo -e "${GREEN}✓ Zabbix web interface is working${NC}"
else
    echo -e "${YELLOW}⚠ Zabbix may still be initializing...${NC}"
fi

echo -e "\n${BLUE}=== Setup Complete ===${NC}"
echo -e "${GREEN}Zabbix is now ready for configuration!${NC}"
echo -e "${YELLOW}Access Zabbix at: http://$ZABBIX_IP${NC}"
echo -e "${YELLOW}Default credentials: Admin / zabbix${NC}"
echo -e "\n${YELLOW}Next steps:${NC}"
echo -e "  1. Access the web interface"
echo -e "  2. Run the monitoring configuration script"
echo -e "  3. Set up hosts and monitoring"