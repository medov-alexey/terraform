# Явное описание необходимых провайдеров для корректной инициализации проекта
terraform {
  required_providers {
    selectel  = {
      source  = "selectel/selectel"
      version = "~> 7.1.0"
    }
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "2.1.0"
    }
  }
}

# Описываем общую конфигурацию ресурсов сервера ОДИН раз для всех машин
resource "openstack_compute_flavor_v2" "custom_tiny_flavor" {
  name      = "custom-tiny-flavor"
  vcpus     = 1
  ram       = 1024
  disk      = 0
  is_public = false

  lifecycle {
    create_before_destroy = true
  }
}

# Импорт персонального публичного SSH-ключ для авторизации на всех создаваемых серверах
resource "selectel_vpc_keypair_v2" "ssh_key" {
  name       = "vps_root_ssh_key"
  public_key = file("~/.ssh/id_rsa.pub")
  user_id    = var.selectel_user_id
}

# Инфраструктура L2: Создание изолированной приватной сети для взаимодействия серверов между собой
resource "openstack_networking_network_v2" "private_lan" {
  name           = "private_lan"
  admin_state_up = "true"
}

# Инфраструктура L3: Определение внутреннего адресного пространства (подсети) внутри приватной сети
resource "openstack_networking_subnet_v2" "private_subnet" {
  name       = "private_subnet"
  network_id = openstack_networking_network_v2.private_lan.id
  cidr       = "192.168.200.0/24"
}

# Обнаружение шлюза внешней сети Selectel, обеспечивающей физический выход в интернет
data "openstack_networking_network_v2" "external_wan" {
  external = true
}

# Создание виртуального маршрутизатора (роутера) для пересылки трафика между сетями
resource "openstack_networking_router_v2" "internet_router" {
  name                = "internet_router"
  external_network_id = data.openstack_networking_network_v2.external_wan.id
}

# Соединение приватной подсети с маршрутизатором для обеспечения серверов исходящим доступом в интернет
resource "openstack_networking_router_interface_v2" "router_to_subnet_link" {
  router_id = openstack_networking_router_v2.internet_router.id
  subnet_id = openstack_networking_subnet_v2.private_subnet.id
}

# Итеративный вызов шаблона (модуля) с пробросом индивидуальных параметров для каждого сервера
module "virtual_machines" {
  source   = "./modules/vps"
  for_each = var.vps_list

  server_name        = each.key
  availability_zone  = "ru-9a"
  selectel_user_id   = var.selectel_user_id
  subnet_id          = openstack_networking_subnet_v2.private_subnet.id
  private_network_id = openstack_networking_network_v2.private_lan.id
  key_pair_name      = selectel_vpc_keypair_v2.ssh_key.name 
  
  # Динамически пробрасываем индивидуальные железные и сетевые характеристики
  ram              = each.value.ram
  vcpus            = each.value.vcpus
  disk_size        = each.value.disk_size
  with_external_ip = each.value.with_external_ip
}

# Вывод итоговой карты распределения IP-адресов в консоль
output "assigned_ip_addresses" {
  value = { for name, instance in module.virtual_machines : name => instance.public_ip }
}