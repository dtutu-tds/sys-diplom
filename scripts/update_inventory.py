import json
import re
import subprocess
import os

TERRAFORM_DIR = "terraform"
INVENTORY_FILE = "ansible/inventories/prod.yml"

def get_terraform_outputs():
    cmd = ["terraform", "output", "-json"]
    result = subprocess.run(cmd, cwd=TERRAFORM_DIR, capture_output=True, text=True, check=True)
    return json.loads(result.stdout)

def update_inventory(outputs):
    with open(INVENTORY_FILE, 'r') as f:
        content = f.read()

    # Map hostnames/keys to terraform output keys
    # Output keys: public_ips (map), private_ips (map)
    # bastion -> public_ips.bastion
    # web1 -> private_ips.web1
    # web2 -> private_ips.web2
    # elastic -> private_ips.elastic
    # kibana -> public_ips.kibana (Wait, kibana has public ip in inventory? 
    # Let's check prod.yml again.
    # kibana.ru-central1.internal: ansible_host: 10.0.1.34 (Private IP?)
    # Wait, check Step 37 output.
    # kibana... ansible_host: 10.0.1.34. Private.
    # zabbix... ansible_host: 158.160.53.53. Public.
    
    public_ips = outputs['public_ips']['value']
    private_ips = outputs['private_ips']['value']

    replacements = {
        r'(bastion\.ru-central1\.internal:\s+ansible_host:\s+)(\d+\.\d+\.\d+\.\d+)': public_ips['bastion'],
        r'(web1\.ru-central1\.internal:\s+ansible_host:\s+)(\d+\.\d+\.\d+\.\d+)': private_ips['web1'],
        r'(web2\.ru-central1\.internal:\s+ansible_host:\s+)(\d+\.\d+\.\d+\.\d+)': private_ips['web2'],
        r'(elastic\.ru-central1\.internal:\s+ansible_host:\s+)(\d+\.\d+\.\d+\.\d+)': private_ips['elastic'],
        r'(kibana\.ru-central1\.internal:\s+ansible_host:\s+)(\d+\.\d+\.\d+\.\d+)': private_ips['kibana'], 
        r'(zabbix\.ru-central1\.internal:\s+ansible_host:\s+)(\d+\.\d+\.\d+\.\d+)': public_ips['zabbix'],
        # Also update bastion IP in ProxyCommand in all:vars
        r'(ProxyCommand="ssh .+ ubuntu@)(\d+\.\d+\.\d+\.\d+)"': public_ips['bastion']
    }

    new_content = content
    for pattern, new_ip in replacements.items():
        if not new_ip:
            print(f"Warning: No IP found for pattern {pattern}")
            continue
        
        # Use a function to replace with group 1 + new_ip
        def replacer(match):
            return match.group(1) + new_ip + (match.group(3) if len(match.groups()) > 2 else "")

        # For ProxyCommand, group 1 is prefix, group 2 is IP.
        # But wait, ProxyCommand regex: group 1 end with @, group 2 is IP, then we match " at end.
        # So we want to replace with group 1 + new_ip + "
        
        if "ProxyCommand" in pattern:
             new_content = re.sub(pattern, lambda m: m.group(1) + new_ip + '"', new_content)
        else:
             # Standard hosts: group 1 is prefix, group 2 is old IP.
             new_content = re.sub(pattern, lambda m: m.group(1) + new_ip, new_content)

    with open(INVENTORY_FILE, 'w') as f:
        f.write(new_content)
    
    print("Inventory updated successfully.")
    print("New Bastion Public IP:", public_ips['bastion'])
    print("New Zabbix Public IP:", public_ips['zabbix'])

if __name__ == "__main__":
    try:
        outputs = get_terraform_outputs()
        update_inventory(outputs)
    except Exception as e:
        print(f"Error: {e}")
