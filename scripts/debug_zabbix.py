import requests
import json
import sys

ZABBIX_BASE = "http://158.160.106.109"

def probe(url):
    print(f"Probing {url}...")
    try:
        response = requests.get(url, timeout=5)
        print(f"Status: {response.status_code}")
        print(f"Content: {response.text[:200]}...")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    probe(f"{ZABBIX_BASE}/zabbix/index.php")
    probe(f"{ZABBIX_BASE}/index.php")
    probe(f"{ZABBIX_BASE}/zabbix/api_jsonrpc.php")
    probe(f"{ZABBIX_BASE}/api_jsonrpc.php")
