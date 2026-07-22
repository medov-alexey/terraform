# Урок 7 — Создание Kubernetes-кластера через защищенный Bastion Host с помощью Kubespray

Архитектурный шаблон реализует концепцию **Zero Public IP** для целевой инфраструктуры. Все ноды Kubernetes полностью изолированы внутри приватной сети `10.10.0.0/24`. Управление и развертывание происходит через единую точку входа — **Bastion Host**.

## 🛠 Изменение в архитектуре (`vps_list.tf`)

Для реализации схемы в карту серверов добавлены изменения:
* У всех нод `k8s-master` и `k8s-worker` флаг `with_external_ip` выставлен в `false`.
* Добавлен новый инстанс `"jump-host"` с параметром `with_external_ip = true`.

## 🚀 Пошаговый сценарий установки кластера

### Шаг 1. Развертывание серверов
```bash
source ~/terraform-selectel
terraform init
terraform apply
```
Скопируйте из финального вывода публичный IP сервера `jump-host` и внутренние IP-адреса (`private_ip`) всех нод.

### Шаг 2. Подготовка Bastion Host
1. Зайдите на созданный бастион по SSH (благодаря общему ключу, вас пустит без пароля):
   ```bash
   ssh root@<ПУБЛИЧНЫЙ_IP_JUMP_HOST>
   ```
2. Установите необходимые для Kubespray утилиты (Git, Python, Ansible):
   ```bash
   add-apt-repository --yes ppa:deadsnakes/ppa
   apt update && apt install -y python3.11 python3.11-venv python3.11-dev git
   ```

### Шаг 3. Скачивание и запуск Kubespray
1. Клонируйте официальный репозиторий Kubespray прямо на Bastion Host:
   ```bash
   git clone https://github.com/kubernetes-sigs/kubespray.git
   cd kubespray
   python3.11 -m venv venv
   source venv/bin/activate
   pip install --upgrade pip setuptools wheel
   pip install -r requirements.txt
   ansible-playbook --version
   cp -rfp inventory/sample inventory/mycluster
   ```
2. Откройте файл `inventory.ini` внутри папки `inventory/mycluster/`, вписав туда внутренние IP-адреса нод (`10.10.0.x`).

Пример заполненного файла:
```ini
# 1. ОБЩИЙ СПИСОК ВСЕХ СЕРВЕРОВ КЛАСТЕРА
# Для каждой ноды указываем ее внутренний IP-адрес в приватной сети Selectel
[all]
k8s-master-1  ansible_host=10.10.0.11 ip=10.10.0.11
k8s-master-2  ansible_host=10.10.0.12 ip=10.10.0.12
k8s-master-3  ansible_host=10.10.0.13 ip=10.10.0.13
k8s-worker-1  ansible_host=10.10.0.21 ip=10.10.0.21
k8s-worker-2  ansible_host=10.10.0.22 ip=10.10.0.22
k8s-worker-3  ansible_host=10.10.0.23 ip=10.10.0.23

# 2. НАЗНАЧЕНИЕ MASTER-НОД (CONTROL PLANE)
# Эти сервера будут управлять кластером, на них запустятся api-server, etcd и контроллеры
[kube_control_plane]
k8s-master-1
k8s-master-2
k8s-master-3

# 3. НАЗНАЧЕНИЕ СЛУЖБЫ БАЗЫ ДАННЫХ KUBERNETES (ETCD)
# Рекомендуется запускать etcd на тех же машинах, что и Control Plane
[etcd]
k8s-master-1
k8s-master-2
k8s-master-3

# 4. НАЗНАЧЕНИЕ WORKER-НОД (РАБОЧИЕ СЕГМЕНТЫ)
# Здесь будут разворачиваться ваши поды, контейнеры и приложения
[kube_node]
k8s-worker-1
k8s-worker-2
k8s-worker-3

# 5. СЛУЖЕБНЫЕ ГРУППЫ ДЛЯ СИСТЕМНЫХ СЕРВИСОВ KUBESPRAY
[calico_rr]

[k8s_cluster:children]
kube_control_plane
kube_node
calico_rr

# 6. ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ДЛЯ АВТОМАТИЗАЦИИ (САМЫЙ ВАЖНЫЙ БЛОК)
[all:vars]
# Указываем, что подключаться к серверам нужно под пользователем root
ansible_user=root

# МАГИЯ BASTION: Если вы запускаете Kubespray со своего ЛОКАЛЬНОГО компьютера,
# эта строка заставит Ansible прозрачно ходить на все внутренние ноды СКВОЗЬ публичный IP бастиона.
# Замените 95.213.x.x на реальный внешний IP вашего k8s-bastion.
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -q root@95.213.x.x"'
```

3. Запустите деплой кластера локально изнутри сети Selectel:
   ```bash
   ansible-playbook -i inventory/mycluster/inventory.ini --become cluster.yml
   ```


## 🗑 Полное уничтожение инфраструктуры
По окончании лабораторной работы обязательно удалите все ресурсы, чтобы предотвратить списание средств за аренду дисков и публичных IP:
```bash
terraform destroy
```