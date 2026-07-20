# Добавляем свой личный SSH-ключ в проект Selectel для последующего безопасного доступа к виртуальной машине
resource "selectel_vpc_keypair_v2" "my_ssh_keypair" {
  name       = "my_ssh_keypair"
  public_key = file("~/.ssh/id_rsa.pub")
  user_id    = var.selectel_user_id
}

# Описываем конфигурацию ресурсов сервера — флейвор (1 vCPU, 1024 MB RAM)
resource "openstack_compute_flavor_v2" "my_custom_flavor" {
  name      = "custom-tiny-flavor"
  vcpus     = 1
  ram       = 1024
  disk      = 0
  is_public = false

  lifecycle {
    create_before_destroy = true
  }
}

# Создаем изолированную приватную сеть для объединения облачных серверов
resource "openstack_networking_network_v2" "my_private_network" {
  name           = "my_private_network"
  admin_state_up = "true"
}

# Создаем подсеть внутри приватной сети, определяющую диапазон внутренних IP-адресов
resource "openstack_networking_subnet_v2" "my_subnet" {
  name       = "my_subnet"
  network_id = openstack_networking_network_v2.my_private_network.id
  cidr       = "192.168.200.0/24"
}

# Запрашиваем у Selectel данные о существующей общей внешней сети, через которую работает интернет
data "openstack_networking_network_v2" "my_external_network" {
  external = true
}

# Создаем виртуальный роутер для связи приватной сети с внешней интернет-сетью
resource "openstack_networking_router_v2" "my_router" {
  name                = "my_router"
  external_network_id = data.openstack_networking_network_v2.my_external_network.id
}

# Подключаем роутер к приватной подсети для маршрутизации трафика наружу
resource "openstack_networking_router_interface_v2" "my_router_interface_1" {
  router_id = openstack_networking_router_v2.my_router.id
  subnet_id = openstack_networking_subnet_v2.my_subnet.id
}

# Создаем сетевой порт в приватной сети (ручное создание отключает дефолтные блокировки Selectel и открывает доступ по SSH)
resource "openstack_networking_port_v2" "my_port" {
  name       = "my_port"
  network_id = openstack_networking_network_v2.my_private_network.id

  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.my_subnet.id
  }
}

# Ищем в каталоге Selectel актуальный и официальный публичный образ операционной системы Ubuntu 22.04 LTS
data "openstack_images_image_v2" "my_image" {
  name        = "Ubuntu 22.04 LTS 64-bit"
  most_recent = true
  visibility  = "public"
}

# Создаем сетевой загрузочный том (системный диск) на основе найденного образа Ubuntu
resource "openstack_blockstorage_volume_v3" "volume_1" {
  name                 = "boot-volume-for-server"
  size                 = "10"
  image_id             = data.openstack_images_image_v2.my_image.id
  volume_type          = "fast.ru-9a"
  availability_zone    = "ru-9a"
  enable_online_resize = true

  lifecycle {
    ignore_changes = [image_id]
  }
}

# Создаем виртуальную машину и подключаем её через наш ручной сетевой порт и загрузочный диск
resource "openstack_compute_instance_v2" "my_test_server" {
  name              = "my_test_server"
  flavor_id         = openstack_compute_flavor_v2.my_custom_flavor.id
  key_pair          = selectel_vpc_keypair_v2.my_ssh_keypair.name
  availability_zone = "ru-9a"

  network {
    port = openstack_networking_port_v2.my_port.id
  }
  
  block_device {
    uuid             = openstack_blockstorage_volume_v3.volume_1.id
    source_type      = "volume"
    destination_type = "volume"
    boot_index       = 0
  }
}

# Запрашиваем (арендуем) свободный публичный (плавающий) IP-адрес из внешнего пула Selectel
resource "openstack_networking_floatingip_v2" "my_floatingip" {
  pool = "external-network"
}

# Привязываем арендованный публичный IP-адрес напрямую к сетевому порту нашей виртуальной машины
resource "openstack_networking_floatingip_associate_v2" "association_1" {
  floating_ip = openstack_networking_floatingip_v2.my_floatingip.address
  port_id     = openstack_networking_port_v2.my_port.id
}

# Автоматически выводим выделенный публичный IP-адрес сервера в консоль после завершения работы команды terraform apply
output "server_ip_address" {
  value = openstack_networking_floatingip_v2.my_floatingip.address 
}
