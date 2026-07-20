
# Добавляем свой личный SSH ключ для доступа на создаваемую нами виртуальную машину
resource "selectel_vpc_keypair_v2" "my_ssh_keypair" {
  name       = "my_ssh_keypair"
  public_key = file("~/.ssh/id_rsa.pub")
  user_id    = var.selectel_user_id
}



# создаем приватную сеть (по сути это локальная сеть внутри облака, можем в этой сети объединять наши виртуалки как будто они в одной сети)
resource "openstack_networking_network_v2" "my_private_network" {
  name           = "my_private_network"
  admin_state_up = "true"
}



# создаем подсеть в нашей приватной сети (и из этой подсети наши сервера будут получать ip адреса)
resource "openstack_networking_subnet_v2" "subnet_for_my_private_network" {
  name       = "subnet_for_my_private_network"
  network_id = openstack_networking_network_v2.my_private_network.id
  cidr       = "192.168.200.0/24"
}



data "openstack_networking_network_v2" "my_external_network" {
  external = true
}



# создаем роутер и указываем id внешней сети (у которой есть доступ в интернет)
resource "openstack_networking_router_v2" "my_router" {
  name                = "my_router"
  external_network_id = data.openstack_networking_network_v2.my_external_network.id
}



# присоединяем роутер к приватной подсети (позволяем трафику ходить между сетями приватной и внешней)
resource "openstack_networking_router_interface_v2" "my_router_interface_1" {
  router_id = openstack_networking_router_v2.my_router.id
  subnet_id = openstack_networking_subnet_v2.subnet_for_my_private_network.id
}



data "openstack_images_image_v2" "image_1" {
  name        = "Ubuntu 20.04 LTS 64-bit"
  most_recent = true
  visibility  = "public"
}



# cоздаем загрузочный том (boot volume) для виртуальной машины на основе образа Ubuntu
resource "openstack_blockstorage_volume_v3" "volume_1" {
  name                 = "boot-volume-for-server"
  size                 = "5"
  image_id             = data.openstack_images_image_v2.image_1.id
  volume_type          = "fast.ru-9a"
  availability_zone    = "ru-9a"
  enable_online_resize = true

  lifecycle {
    ignore_changes = [image_id]
  }

}



# cоздаем дополнительный диск для хранения данных
resource "openstack_blockstorage_volume_v3" "volume_2" {
  name                 = "additional-volume-for-server"
  size                 = "7"
  volume_type          = "universal.ru-9a"
  availability_zone    = "ru-9a"
  enable_online_resize = true
}



# cоздаем виртуальную машину с заданными параметрами (используем наш ключ SSH, диск и сетевой порт)
resource "openstack_compute_instance_v2" "server_1" {
  name              = "server_1"
  flavor_name       = "CP1.1-1024" # Используем готовый флейвор Selectel (1 vCPU, 1 GB RAM)
  key_pair          = selectel_vpc_keypair_v2.my_ssh_keypair.name
  availability_zone = "ru-9a"

  network {
    uuid = openstack_networking_network_v2.my_private_network.id
  }

  lifecycle {
    ignore_changes = [image_id]
  }
  
  # указываем загрузочный диск
  block_device {
    uuid             = openstack_blockstorage_volume_v3.volume_1.id
    source_type      = "volume"
    destination_type = "volume"
    boot_index       = 0
  }

  vendor_options {
    ignore_resize_confirmation = true
  }
}



# запрашиваем плавающий (внешний) IP-адрес из пула внешней сети с именем external-network
resource "openstack_networking_floatingip_v2" "my_floatingip" {
  pool = "external-network"
}



resource "openstack_networking_floatingip_associate_v2" "association_1" {
  port_id     = openstack_networking_port_v2.my_port.id
  floating_ip = openstack_networking_floatingip_v2.my_floatingip.address
}



# выводим публичный IP-адрес созданного нами сервера
output "server_ip_address" {
  value = openstack_networking_floatingip_v2.my_floatingip.address 
}