#!/usr/bin/env python3
"""
Скрипт для обновления IP адресов хостов в Zabbix
"""

import requests
import json
import sys

class ZabbixAPI:
    def __init__(self, url: str, username: str, password: str):
        self.url = url.rstrip('/') + '/api_jsonrpc.php'
        self.username = username
        self.password = password
        self.auth_token = None
        self.request_id = 1
        
    def _call(self, method: str, params: dict) -> dict:
        """Выполнить API запрос к Zabbix"""
        headers = {'Content-Type': 'application/json'}
        payload = {
            'jsonrpc': '2.0',
            'method': method,
            'params': params,
            'id': self.request_id
        }
        
        if self.auth_token:
            payload['auth'] = self.auth_token
            
        self.request_id += 1
        
        try:
            response = requests.post(self.url, json=payload, headers=headers, timeout=10)
            response.raise_for_status()
            result = response.json()
            
            if 'error' in result:
                raise Exception(f"Zabbix API error: {result['error']}")
                
            return result.get('result')
        except requests.exceptions.RequestException as e:
            raise Exception(f"HTTP request failed: {e}")
    
    def login(self):
        """Аутентификация в Zabbix"""
        result = self._call('user.login', {
            'username': self.username,
            'password': self.password
        })
        self.auth_token = result
        
    def get_hosts(self):
        """Получить список всех хостов"""
        return self._call('host.get', {
            'output': ['hostid', 'host', 'name'],
            'selectInterfaces': ['interfaceid', 'ip', 'port', 'type', 'main']
        })
    
    def update_host_interface(self, interface_id: str, new_ip: str):
        """Обновить IP адрес интерфейса хоста"""
        return self._call('hostinterface.update', {
            'interfaceid': interface_id,
            'ip': new_ip
        })

def main():
    zabbix_url = "http://178.154.240.244"
    username = "Admin"
    password = "zabbix"
    
    # Правильные IP адреса
    correct_ips = {
        'bastion.ru-central1.internal': '10.0.1.33',
        'web1.ru-central1.internal': '10.0.10.4',
        'web2.ru-central1.internal': '10.0.11.5',
        'zabbix.ru-central1.internal': '10.0.1.22',
        'elastic.ru-central1.internal': '10.0.11.19',
        'kibana.ru-central1.internal': '10.0.1.9'
    }
    
    try:
        print("🔧 Обновление IP адресов хостов в Zabbix...")
        
        zapi = ZabbixAPI(zabbix_url, username, password)
        zapi.login()
        print("✅ Успешная аутентификация")
        
        hosts = zapi.get_hosts()
        
        updated_count = 0
        
        for host in hosts:
            hostname = host['host']
            host_name = host['name']
            
            if hostname in correct_ips:
                correct_ip = correct_ips[hostname]
                
                # Найти agent интерфейс
                for interface in host.get('interfaces', []):
                    if interface['type'] == '1' and interface['main'] == '1':  # Agent interface, main
                        current_ip = interface['ip']
                        
                        if current_ip != correct_ip:
                            print(f"🔄 Обновление {host_name}: {current_ip} → {correct_ip}")
                            
                            try:
                                zapi.update_host_interface(interface['interfaceid'], correct_ip)
                                print(f"   ✅ Успешно обновлен")
                                updated_count += 1
                            except Exception as e:
                                print(f"   ❌ Ошибка: {e}")
                        else:
                            print(f"✅ {host_name}: IP адрес уже корректный ({current_ip})")
                        break
            else:
                print(f"⚠️  {host_name}: не найден в списке для обновления")
        
        print(f"\n📊 Обновлено интерфейсов: {updated_count}")
        
        if updated_count > 0:
            print("🎉 IP адреса успешно обновлены!")
        else:
            print("ℹ️  Все IP адреса уже корректные")
            
    except Exception as e:
        print(f"❌ Ошибка: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()