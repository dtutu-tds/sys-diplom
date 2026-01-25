import requests
import json
import sys

ZABBIX_URL = "http://158.160.106.109"
API_URL = f"{ZABBIX_URL}/api_jsonrpc.php"
USERNAME = "Admin"
PASSWORD = "zabbix"

def api_call(method, params, auth=None):
    headers = {'Content-Type': 'application/json-rpc'}
    payload = {
        'jsonrpc': '2.0',
        'method': method,
        'params': params,
        'auth': auth,
        'id': 1
    }
    try:
        response = requests.post(API_URL, headers=headers, json=payload, timeout=5)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        print(f"Error calling {method}: {e}")
        return None

def get_item_id(host_id, key, auth_token):
    resp = api_call("item.get", {
        "output": ["itemid"],
        "hostids": host_id,
        "search": {"key_": key},
        "sortfield": "name"
    }, auth_token)
    if resp and 'result' in resp and len(resp['result']) > 0:
        return resp['result'][0]['itemid']
    return None

def main():
    print(f"Connecting to {API_URL}...")
    
    # 1. Login
    login_resp = api_call("user.login", {"user": USERNAME, "password": PASSWORD})
    if not login_resp or 'result' not in login_resp:
        print("Login failed:", login_resp)
        return
    
    auth_token = login_resp['result']
    print("Login successful.")

    # 2. Get or Create Hosts
    hosts_data = [
        {"name": "web1.ru-central1.internal", "ip": "10.0.10.13"},
        {"name": "web2.ru-central1.internal", "ip": "10.0.11.8"}
    ]
    
    # Get Group ID for "Linux servers" or "Virtual machines"
    group_resp = api_call("hostgroup.get", {"filter": {"name": ["Linux servers"]}, "output": ["groupid"]}, auth_token)
    group_id = group_resp['result'][0]['groupid'] if group_resp and 'result' in group_resp and len(group_resp['result']) > 0 else "2" # Default to 2

    # Get Template ID for "Linux by Zabbix agent"
    template_resp = api_call("template.get", {"filter": {"name": ["Linux by Zabbix agent"]}, "output": ["templateid"]}, auth_token)
    template_id = template_resp['result'][0]['templateid'] if template_resp and 'result' in template_resp and len(template_resp['result']) > 0 else "10001"

    for h in hosts_data:
        h_resp = api_call("host.get", {"filter": {"host": [h["name"]]}, "output": ["hostid"]}, auth_token)
        if not h_resp or 'result' not in h_resp or len(h_resp['result']) == 0:
            print(f"Creating host {h['name']}...")
            create_params = {
                "host": h["name"],
                "interfaces": [
                    {
                        "type": 1,
                        "main": 1,
                        "useip": 1,
                        "ip": h["ip"],
                        "dns": "",
                        "port": "10050"
                    }
                ],
                "groups": [{"groupid": group_id}],
                "templates": [{"templateid": template_id}]
            }
            c_resp = api_call("host.create", create_params, auth_token)
            if c_resp and 'hostids' in c_resp.get('result', {}):
                print(f"Created host {h['name']} ID: {c_resp['result']['hostids'][0]}")
            else:
                print(f"Failed to create host: {c_resp}")
        else:
             print(f"Host {h['name']} already exists ID: {h_resp['result'][0]['hostid']}")

    # Get first host ID for dashboard
    hosts_resp = api_call("host.get", {"filter": {"host": ["web1.ru-central1.internal"]}, "output": ["hostid"]}, auth_token)
    if not hosts_resp or 'result' not in hosts_resp or len(hosts_resp['result']) == 0:
        print("Host web1 not found")
        return

    host_id = hosts_resp['result'][0]['hostid']
    print(f"Found web1 ID: {host_id}")


    # 3. Get Item IDs
    items = {
        "CPU Load": "system.cpu.load[all,avg1]",
        "CPU Util": "system.cpu.util[,user]",  # or just system.cpu.util
        "Memory": "vm.memory.size[pavailable]",
        "Disk": "vfs.fs.size[/,pused]",
        "Net In": "net.if.in[eth0]",
        "Net Out": "net.if.out[eth0]"
    }
    
    item_ids = {}
    for name, key in items.items():
        iid = get_item_id(host_id, key, auth_token)
        if iid:
            item_ids[name] = iid
            print(f"Found item {name}: {iid}")
        else:
            print(f"Item {name} with key {key} not found")

    # 4. Create Dashboard
    dashboard_name = "Web Server Monitoring (USE)"
    
    # Check if exists
    dash_resp = api_call("dashboard.get", {"filter": {"name": [dashboard_name]}, "output": ["dashboardid"]}, auth_token)
    if dash_resp and 'result' in dash_resp and len(dash_resp['result']) > 0:
        print(f"Dashboard {dashboard_name} already exists. Deleting...")
        api_call("dashboard.delete", [dash_resp['result'][0]['dashboardid']], auth_token)

    widgets = []
    
    # CPU Graph
    if "CPU Load" in item_ids:
        widgets.append({
            "type": "graph",
            "name": "CPU Load",
            "x": 0, "y": 0, "width": 12, "height": 5,
            "fields": [
                {"type": 1, "name": "source_type", "value": "1"}, # Simple graph
                {"type": 4, "name": "itemid", "value": str(item_ids["CPU Load"])} 
            ]
        })

    # Memory Graph
    if "Memory" in item_ids:
        widgets.append({
            "type": "graph",
            "name": "Memory Usage",
            "x": 12, "y": 0, "width": 12, "height": 5,
            "fields": [
                {"type": 1, "name": "source_type", "value": "1"},
                {"type": 4, "name": "itemid", "value": str(item_ids["Memory"])}
            ]
        })

    create_params = {
        "name": dashboard_name,
        "userid": 1, # Admin
        "pages": [
            {
                "widgets": widgets
            }
        ]
    }
    
    create_resp = api_call("dashboard.create", create_params, auth_token)
    if create_resp and 'result' in create_resp:
        print(f"Dashboard created successfully: {create_resp['result']['dashboardids'][0]}")
    else:
        print("Failed to create dashboard:", create_resp)

if __name__ == "__main__":
    main()
