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

def main():
    print(f"Connecting to {API_URL}...")
    
    # 1. Login
    login_resp = api_call("user.login", {"user": USERNAME, "password": PASSWORD})
    if not login_resp or 'result' not in login_resp:
        print("Login failed:", login_resp)
        return
    
    auth_token = login_resp['result']
    print("Login successful.")

    # 2. Get Hosts
    hosts_resp = api_call("host.get", {"output": "extend"}, auth_token)
    if hosts_resp and 'result' in hosts_resp:
        print(f"Found {len(hosts_resp['result'])} hosts:")
        for host in hosts_resp['result']:
            # Debug keys
            # print(host.keys())
            status = "Available" if host.get('available') == '1' else "Unavailable"
            print(f" - {host['name']} (ID: {host['hostid']}) -> {status} (Error: {host.get('error', '')})")
    else:
        print("Failed to get hosts")

    # 3. Create Dashboard (Mockup)
    # We will expand this if login works
    
if __name__ == "__main__":
    main()
