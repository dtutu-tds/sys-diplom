import requests
import sys

KIBANA_URL = "http://178.154.223.32:5601" # Need to check if this is correct IP from output step 253. 
# Wait, Step 253 output: kibana public ip 158.160.97.16.
# Step 243 cat output: 10.0.1.20 (Private). 
# Terraform output in Step 253 confirms Public IP: 158.160.97.16.

def check_kibana():
    print(f"Checking Kibana at {KIBANA_URL}...")
    try:
        resp = requests.get(f"{KIBANA_URL}/api/status", timeout=10)
        print(f"Status Code: {resp.status_code}")
        if resp.status_code == 200:
            print("Kibana is UP")
            # print(resp.json()) # Verbose
            metrics = resp.json().get('metrics', {})
            print("Usage metrics available keys:", metrics.keys())
        else:
            print("Kibana returned non-200 status")
            print(resp.text[:200])
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    check_kibana()
