#!/usr/bin/env python3
"""
Скрипт для автоматической настройки мониторинга в Zabbix
Выполняет:
- Добавление всех хостов в Zabbix
- Применение шаблонов "Linux by Zabbix agent" ко всем хостам
- Применение шаблона "Nginx by Zabbix agent" к веб-серверам
- Настройку веб-сценария для проверки доступности сайта через ALB
"""

import requests
import json
import sys
import argparse
from typing import Dict, List, Optional


class ZabbixAPI:
    def __init__(self, url: str, username: str, password: str):
        self.url = url.rstrip('/') + '/api_jsonrpc.php'
        self.username = username
        self.password = password
        self.auth_token = None
        self.request_id = 1
        
    def _call(self, method: str, params: Dict) -> Dict:
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
        print(f"Подключение к Zabbix API: {self.url}")
        result = self._call('user.login', {
            'username': self.username,
            'password': self.password
        })
        self.auth_token = result
        print("✓ Успешная аутентификация")
        
    def get_template_id(self, template_name: str) -> Optional[str]:
        """Получить ID шаблона по имени"""
        result = self._call('template.get', {
            'filter': {'host': template_name},
            'output': ['templateid', 'host']
        })
        
        if result:
            return result[0]['templateid']
        return None
    
    def get_host_group_id(self, group_name: str) -> Optional[str]:
        """Получить ID группы хостов"""
        result = self._call('hostgroup.get', {
            'filter': {'name': group_name},
            'output': ['groupid', 'name']
        })
        
        if result:
            return result[0]['groupid']
        return None
    
    def create_host_group(self, group_name: str) -> str:
        """Создать группу хостов"""
        result = self._call('hostgroup.create', {
            'name': group_name
        })
        return result['groupids'][0]
    
    def get_host_id(self, hostname: str) -> Optional[str]:
        """Получить ID хоста по имени"""
        result = self._call('host.get', {
            'filter': {'host': hostname},
            'output': ['hostid', 'host']
        })
        
        if result:
            return result[0]['hostid']
        return None
    
    def create_host(self, hostname: str, visible_name: str, ip_address: str, 
                   group_ids: List[str], template_ids: List[str]) -> str:
        """Создать хост в Zabbix"""
        params = {
            'host': hostname,
            'name': visible_name,
            'interfaces': [{
                'type': 1,  # Agent interface
                'main': 1,
                'useip': 1,
                'ip': ip_address,
                'dns': '',
                'port': '10050'
            }],
            'groups': [{'groupid': gid} for gid in group_ids],
            'templates': [{'templateid': tid} for tid in template_ids]
        }
        
        result = self._call('host.create', params)
        return result['hostids'][0]
    
    def update_host_templates(self, host_id: str, template_ids: List[str]):
        """Обновить шаблоны хоста"""
        self._call('host.update', {
            'hostid': host_id,
            'templates': [{'templateid': tid} for tid in template_ids]
        })
    
    def create_web_scenario(self, name: str, host_id: str, url: str) -> str:
        """Создать веб-сценарий"""
        params = {
            'name': name,
            'hostid': host_id,
            'steps': [{
                'name': 'Homepage check',
                'url': url,
                'status_codes': '200',
                'no': 1
            }],
            'delay': '60s'
        }
        
        result = self._call('httptest.create', params)
        return result['httptestids'][0]
    
    def get_web_scenario(self, host_id: str, name: str) -> Optional[str]:
        """Получить ID веб-сценария"""
        result = self._call('httptest.get', {
            'hostids': host_id,
            'filter': {'name': name},
            'output': ['httptestid', 'name']
        })
        
        if result:
            return result[0]['httptestid']
        return None
    
    def get_item_id(self, host_id: str, key: str) -> Optional[str]:
        """Получить ID элемента данных по ключу"""
        result = self._call('item.get', {
            'hostids': host_id,
            'search': {'key_': key},
            'output': ['itemid', 'key_', 'name']
        })
        
        if result:
            return result[0]['itemid']
        return None
    
    def get_trigger_id(self, description: str, host_id: str = None) -> Optional[str]:
        """Получить ID триггера по описанию"""
        params = {
            'filter': {'description': description},
            'output': ['triggerid', 'description']
        }
        if host_id:
            params['hostids'] = host_id
            
        result = self._call('trigger.get', params)
        
        if result:
            return result[0]['triggerid']
        return None
    
    def create_trigger(self, description: str, expression: str, priority: int, 
                      comments: str = '') -> str:
        """Создать триггер"""
        params = {
            'description': description,
            'expression': expression,
            'priority': priority,
            'comments': comments
        }
        
        result = self._call('trigger.create', params)
        return result['triggerids'][0]
    
    def get_dashboard_id(self, name: str) -> Optional[str]:
        """Получить ID дашборда по имени"""
        result = self._call('dashboard.get', {
            'filter': {'name': name},
            'output': ['dashboardid', 'name']
        })
        
        if result:
            return result[0]['dashboardid']
        return None
    
    def create_dashboard(self, name: str, widgets: List[Dict]) -> str:
        """Создать дашборд"""
        params = {
            'name': name,
            'pages': [{
                'widgets': widgets
            }]
        }
        
        result = self._call('dashboard.create', params)
        return result['dashboardids'][0]
    
    def get_all_hosts(self, group_id: str = None) -> List[Dict]:
        """Получить список всех хостов"""
        params = {
            'output': ['hostid', 'host', 'name']
        }
        if group_id:
            params['groupids'] = group_id
            
        return self._call('host.get', params)


def configure_triggers(zapi: ZabbixAPI, hosts_config: List[Dict], web_scenario_host: str):
    """Настроить триггеры для мониторинга"""
    print("\nНастройка триггеров...")
    
    triggers_created = 0
    
    for host_config in hosts_config:
        hostname = host_config['hostname']
        host_id = zapi.get_host_id(hostname)
        
        if not host_id:
            print(f"  ⚠ Хост '{hostname}' не найден, пропускаем")
            continue
        
        # Триггер: CPU > 80% в течение 5 минут
        trigger_name = f"High CPU usage on {hostname}"
        if not zapi.get_trigger_id(trigger_name, host_id):
            try:
                expression = f"avg(//{hostname}/system.cpu.util,5m)>80"
                zapi.create_trigger(
                    description=trigger_name,
                    expression=expression,
                    priority=2,  # Warning
                    comments="CPU загрузка превышает 80% в течение 5 минут"
                )
                print(f"  ✓ Создан триггер: {trigger_name}")
                triggers_created += 1
            except Exception as e:
                print(f"  ⚠ Не удалось создать триггер CPU для {hostname}: {e}")
        
        # Триггер: свободное место на диске < 15%
        trigger_name = f"Low disk space on {hostname}"
        if not zapi.get_trigger_id(trigger_name, host_id):
            try:
                expression = f"last(//{hostname}/vfs.fs.size[/,pfree])<15"
                zapi.create_trigger(
                    description=trigger_name,
                    expression=expression,
                    priority=3,  # Average
                    comments="Свободное место на диске меньше 15%"
                )
                print(f"  ✓ Создан триггер: {trigger_name}")
                triggers_created += 1
            except Exception as e:
                print(f"  ⚠ Не удалось создать триггер диска для {hostname}: {e}")
    
    # Триггер для веб-сценария
    web_scenario_host_id = zapi.get_host_id(web_scenario_host)
    if web_scenario_host_id:
        trigger_name = "ALB Website is unavailable"
        if not zapi.get_trigger_id(trigger_name, web_scenario_host_id):
            try:
                expression = f"last(//{web_scenario_host}/web.test.fail[ALB Website Availability])>0"
                zapi.create_trigger(
                    description=trigger_name,
                    expression=expression,
                    priority=4,  # High
                    comments="Веб-сценарий проверки доступности ALB завершился с ошибкой"
                )
                print(f"  ✓ Создан триггер: {trigger_name}")
                triggers_created += 1
            except Exception as e:
                print(f"  ⚠ Не удалось создать триггер веб-сценария: {e}")
    
    print(f"  Создано триггеров: {triggers_created}")


def configure_dashboards(zapi: ZabbixAPI, hosts_config: List[Dict]):
    """Создать дашборды для мониторинга"""
    print("\nСоздание дашбордов...")
    
    # Получить ID всех хостов
    all_hosts = []
    web_hosts = []
    
    for host_config in hosts_config:
        hostname = host_config['hostname']
        host_id = zapi.get_host_id(hostname)
        if host_id:
            all_hosts.append({'hostid': host_id, 'name': host_config['visible_name']})
            if host_config.get('is_web_server', False):
                web_hosts.append({'hostid': host_id, 'name': host_config['visible_name']})
    
    # Дашборд 1: System Overview
    dashboard_name = "System Overview"
    if not zapi.get_dashboard_id(dashboard_name):
        try:
            widgets = []
            y_pos = 0
            
            # Виджет: Статус всех хостов
            widgets.append({
                'type': 'problemhosts',
                'name': 'Host Status',
                'x': 0,
                'y': y_pos,
                'width': 12,
                'height': 4,
                'fields': [
                    {'type': 0, 'name': 'groupids', 'value': ''}
                ]
            })
            y_pos += 4
            
            # Виджеты CPU для каждого хоста
            x_pos = 0
            for i, host in enumerate(all_hosts[:4]):  # Максимум 4 хоста
                widgets.append({
                    'type': 'graph',
                    'name': f"CPU - {host['name']}",
                    'x': x_pos,
                    'y': y_pos,
                    'width': 6,
                    'height': 4,
                    'fields': [
                        {'type': 0, 'name': 'source_type', 'value': '1'},
                        {'type': 0, 'name': 'itemid', 'value': host['hostid']}
                    ]
                })
                x_pos += 6
                if x_pos >= 12:
                    x_pos = 0
                    y_pos += 4
            
            dashboard_id = zapi.create_dashboard(dashboard_name, widgets)
            print(f"  ✓ Создан дашборд '{dashboard_name}'")
        except Exception as e:
            print(f"  ⚠ Не удалось создать дашборд '{dashboard_name}': {e}")
    else:
        print(f"  ⚠ Дашборд '{dashboard_name}' уже существует")
    
    # Дашборд 2: Web Servers
    if web_hosts:
        dashboard_name = "Web Servers"
        if not zapi.get_dashboard_id(dashboard_name):
            try:
                widgets = []
                y_pos = 0
                
                # Виджет: Проблемы веб-серверов
                widgets.append({
                    'type': 'problems',
                    'name': 'Web Server Problems',
                    'x': 0,
                    'y': y_pos,
                    'width': 12,
                    'height': 4,
                    'fields': [
                        {'type': 0, 'name': 'show', 'value': '3'}
                    ]
                })
                y_pos += 4
                
                # Виджеты для каждого веб-сервера
                for i, host in enumerate(web_hosts):
                    x_pos = (i % 2) * 6
                    if i > 0 and i % 2 == 0:
                        y_pos += 4
                    
                    widgets.append({
                        'type': 'graph',
                        'name': f"Nginx - {host['name']}",
                        'x': x_pos,
                        'y': y_pos,
                        'width': 6,
                        'height': 4,
                        'fields': [
                            {'type': 0, 'name': 'source_type', 'value': '1'},
                            {'type': 0, 'name': 'itemid', 'value': host['hostid']}
                        ]
                    })
                
                dashboard_id = zapi.create_dashboard(dashboard_name, widgets)
                print(f"  ✓ Создан дашборд '{dashboard_name}'")
            except Exception as e:
                print(f"  ⚠ Не удалось создать дашборд '{dashboard_name}': {e}")
        else:
            print(f"  ⚠ Дашборд '{dashboard_name}' уже существует")


def configure_monitoring(zabbix_url: str, username: str, password: str, 
                        alb_ip: str, hosts_config: List[Dict]):
    """Основная функция настройки мониторинга"""
    zapi = ZabbixAPI(zabbix_url, username, password)
    zapi.login()
    
    # Получить ID необходимых шаблонов
    print("\nПоиск шаблонов...")
    linux_template_id = zapi.get_template_id('Linux by Zabbix agent')
    nginx_template_id = zapi.get_template_id('Nginx by Zabbix agent')
    
    if not linux_template_id:
        raise Exception("Шаблон 'Linux by Zabbix agent' не найден")
    print(f"  ✓ Найден шаблон 'Linux by Zabbix agent' (ID: {linux_template_id})")
    
    if nginx_template_id:
        print(f"  ✓ Найден шаблон 'Nginx by Zabbix agent' (ID: {nginx_template_id})")
    else:
        print("  ⚠ Шаблон 'Nginx by Zabbix agent' не найден, будет пропущен")
    
    # Создать или получить группу хостов
    print("\nНастройка группы хостов...")
    group_name = 'Yandex Cloud Infrastructure'
    group_id = zapi.get_host_group_id(group_name)
    
    if not group_id:
        group_id = zapi.create_host_group(group_name)
        print(f"  ✓ Создана группа хостов '{group_name}'")
    else:
        print(f"  ✓ Группа хостов '{group_name}' уже существует")
    
    # Добавить хосты
    print("\nДобавление хостов...")
    for host_config in hosts_config:
        hostname = host_config['hostname']
        visible_name = host_config['visible_name']
        ip_address = host_config['ip']
        is_web_server = host_config.get('is_web_server', False)
        
        # Определить шаблоны для хоста
        template_ids = [linux_template_id]
        if is_web_server and nginx_template_id:
            template_ids.append(nginx_template_id)
        
        # Проверить существование хоста
        host_id = zapi.get_host_id(hostname)
        
        if host_id:
            print(f"  ⚠ Хост '{visible_name}' уже существует, обновление шаблонов...")
            zapi.update_host_templates(host_id, template_ids)
            print(f"  ✓ Обновлены шаблоны для '{visible_name}'")
        else:
            host_id = zapi.create_host(
                hostname=hostname,
                visible_name=visible_name,
                ip_address=ip_address,
                group_ids=[group_id],
                template_ids=template_ids
            )
            print(f"  ✓ Добавлен хост '{visible_name}' ({ip_address})")
    
    # Настроить веб-сценарий на одном из хостов
    print("\nНастройка веб-сценария...")
    web_scenario_host = hosts_config[0]['hostname']  # Используем первый хост
    web_scenario_host_id = zapi.get_host_id(web_scenario_host)
    
    if web_scenario_host_id:
        scenario_name = 'ALB Website Availability'
        scenario_url = f'http://{alb_ip}/'
        
        existing_scenario = zapi.get_web_scenario(web_scenario_host_id, scenario_name)
        
        if existing_scenario:
            print(f"  ⚠ Веб-сценарий '{scenario_name}' уже существует")
        else:
            scenario_id = zapi.create_web_scenario(
                name=scenario_name,
                host_id=web_scenario_host_id,
                url=scenario_url
            )
            print(f"  ✓ Создан веб-сценарий '{scenario_name}' для проверки {scenario_url}")
    
    # Настроить триггеры
    configure_triggers(zapi, hosts_config, web_scenario_host)
    
    # Создать дашборды
    configure_dashboards(zapi, hosts_config)
    
    print("\n✓ Настройка мониторинга завершена успешно!")


def main():
    parser = argparse.ArgumentParser(
        description='Настройка мониторинга в Zabbix через API'
    )
    parser.add_argument('--zabbix-url', required=True, 
                       help='URL Zabbix сервера (например: http://158.160.104.168)')
    parser.add_argument('--username', default='Admin',
                       help='Имя пользователя Zabbix (по умолчанию: Admin)')
    parser.add_argument('--password', default='zabbix',
                       help='Пароль пользователя Zabbix (по умолчанию: zabbix)')
    parser.add_argument('--alb-ip', required=True,
                       help='Публичный IP адрес ALB')
    
    args = parser.parse_args()
    
    # Конфигурация хостов (получаем из Terraform или используем значения по умолчанию)
    # Эти значения можно переопределить через аргументы командной строки
    hosts_config = [
        {
            'hostname': 'bastion.ru-central1.internal',
            'visible_name': 'Bastion Host',
            'ip': '10.0.1.33',  # Приватный IP для мониторинга через агента
            'is_web_server': False
        },
        {
            'hostname': 'web1.ru-central1.internal',
            'visible_name': 'Web Server 1',
            'ip': '10.0.10.4',
            'is_web_server': True
        },
        {
            'hostname': 'web2.ru-central1.internal',
            'visible_name': 'Web Server 2',
            'ip': '10.0.11.5',
            'is_web_server': True
        },
        {
            'hostname': 'zabbix.ru-central1.internal',
            'visible_name': 'Zabbix Server',
            'ip': '10.0.1.22',  # Приватный IP
            'is_web_server': False
        },
        {
            'hostname': 'elastic.ru-central1.internal',
            'visible_name': 'Elasticsearch Server',
            'ip': '10.0.11.19',
            'is_web_server': False
        },
        {
            'hostname': 'kibana.ru-central1.internal',
            'visible_name': 'Kibana Server',
            'ip': '10.0.1.9',
            'is_web_server': False
        }
    ]
    
    try:
        configure_monitoring(
            zabbix_url=args.zabbix_url,
            username=args.username,
            password=args.password,
            alb_ip=args.alb_ip,
            hosts_config=hosts_config
        )
    except Exception as e:
        print(f"\n✗ Ошибка: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
