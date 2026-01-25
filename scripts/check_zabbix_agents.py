#!/usr/bin/env python3
"""
Скрипт для проверки статуса Zabbix агентов
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
        """Получить список всех хостов с их статусом"""
        return self._call('host.get', {
            'output': ['hostid', 'host', 'name', 'status'],
            'selectInterfaces': ['ip', 'port', 'type'],
            'selectItems': 'count'
        })

def main():
    zabbix_url = "http://158.160.48.113/zabbix"
    username = "Admin"
    password = "zabbix"
    
    try:
        print("🔍 Проверка статуса Zabbix агентов...")
        print(f"📡 Подключение к Zabbix: {zabbix_url}")
        
        zapi = ZabbixAPI(zabbix_url, username, password)
        zapi.login()
        print("✅ Успешная аутентификация")
        
        hosts = zapi.get_hosts()
        
        print(f"\n📊 Найдено хостов: {len(hosts)}")
        print("=" * 80)
        
        for host in hosts:
            host_name = host['name']
            host_hostname = host['host']
            status = "Включен" if host['status'] == '0' else "Отключен"
            
            print(f"🖥️  {host_name} ({host_hostname})")
            print(f"   Статус: {status}")
            
            # Показать интерфейсы
            if host.get('interfaces'):
                for interface in host['interfaces']:
                    if interface['type'] == '1':  # Agent interface
                        print(f"   IP: {interface['ip']}:{interface['port']}")
            
            print()
        
        # Статистика
        enabled_hosts = sum(1 for h in hosts if h['status'] == '0')
        
        print("📈 Статистика:")
        print(f"   Всего хостов: {len(hosts)}")
        print(f"   Включено: {enabled_hosts}")
        
        if enabled_hosts > 0:
            print("🎉 Хосты настроены в Zabbix!")
        else:
            print("❌ Нет активных хостов")
            
    except Exception as e:
        print(f"❌ Ошибка: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()