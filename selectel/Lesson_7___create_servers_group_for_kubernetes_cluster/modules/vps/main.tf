# обязательно указываем через какого провайдера будем работать (иначе получим ошибку)
terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "2.1.0" # Версия должна строго совпадать с корневой
    }
  }
}

# Входные переменные для кастомизации параметров конкретного сервера
variable "server_name" {}
variable "availability_zone" {}
variable "selectel_user_id" {}
variable "subnet_id" {}
variable "private_network_id" {}
variable "key_pair_name" {}

# Новые переменные, приходящие из карты vps_list
variable "ram" {}
variable "vcpus" {}
variable "disk_size" {}
variable "with_external_ip" {}

# Поиск актуального публичного образа Ubuntu
data "openstack_images_image_v2" "ubuntu_linux" {
  name        = "Ubuntu 22.04 LTS 64-bit"
  most_recent = true
  visibility  = "public"
}

# Создаем уникальный тарифный план (flavor) под индивидуальные требования сервера
resource "openstack_compute_flavor_v2" "this" {
  name      = "flavor-${var.server_name}"
  vcpus     = var.vcpus
  ram       = var.ram
  disk      = 0
  is_public = false

  lifecycle {
    create_before_destroy = true
  }
}

# Создание выделенного сетевого интерфейса (порта)
resource "openstack_networking_port_v2" "this" {
  name       = "port-${var.server_name}"
  network_id = var.private_network_id

  fixed_ip {
    subnet_id = var.subnet_id
  }
}

# Создание сетевого загрузочного тома с динамическим размером
resource "openstack_blockstorage_volume_v3" "boot" {
  name                 = "vol-${var.server_name}"
  size                 = var.disk_size # Размер подставляется из настроек сервера
  image_id             = data.openstack_images_image_v2.ubuntu_linux.id
  volume_type          = "fast.${var.availability_zone}"
  availability_zone    = var.availability_zone
  enable_online_resize = true

  lifecycle {
    ignore_changes = [image_id]
  }
}

# Развертывание виртуальной машины
resource "openstack_compute_instance_v2" "this" {
  name              = var.server_name
  flavor_id         = openstack_compute_flavor_v2.this.id
  key_pair          = var.key_pair_name
  availability_zone = var.availability_zone

  network {
    port = openstack_networking_port_v2.this.id
  }
  
  block_device {
    uuid             = openstack_blockstorage_volume_v3.boot.id
    source_type      = "volume"
    destination_type = "volume"
    boot_index       = 0
  }
}

# Аренда публичного IP-адреса (Создается ТОЛЬКО если сработал флаг с conditional оператором)
resource "openstack_networking_floatingip_v2" "this" {
  count = var.with_external_ip ? 1 : 0
  pool  = "external-network"
}

# Связывание публичного IP-адреса с портом машины (Тоже создается по условию)
resource "openstack_networking_floatingip_associate_v2" "this" {
  count       = var.with_external_ip ? 1 : 0
  floating_ip = openstack_networking_floatingip_v2.this[0].address
  port_id     = openstack_networking_port_v2.this.id
}

# Выходной параметр возвращает IP, либо понятную строку "Internal Only", если интернета нет
output "public_ip" {
  value = var.with_external_ip ? openstack_networking_floatingip_v2.this[0].address : "Internal Only (No WAN)"
}

# Берём внутренний IP-адрес напрямую из сетевых свойств созданной виртуальной машины
output "private_ip" {
  value = openstack_compute_instance_v2.this.network[0].fixed_ip_v4
}