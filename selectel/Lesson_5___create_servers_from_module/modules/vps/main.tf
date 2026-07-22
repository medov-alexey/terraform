# обязательно указываем через какого провайдера будем работать (иначе получим ошибку)
terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "2.1.0" # Версия должна строго совпадать с корневой
    }
  }
}

# Входные переменные для настройки шаблона сервера
variable "server_name" {}
variable "availability_zone" {}
variable "selectel_user_id" {}
variable "subnet_id" {}
variable "private_network_id" {}
variable "key_pair_name" {}
variable "flavor_id" {} # Новая переменная для готового флейвора

# Поиск актуального публичного образа Ubuntu
data "openstack_images_image_v2" "ubuntu_linux" {
  name        = "Ubuntu 22.04 LTS 64-bit"
  most_recent = true
  visibility  = "public"
}

# Создание выделенного сетевого интерфейса (порта)
resource "openstack_networking_port_v2" "this" {
  name       = "port-${var.server_name}"
  network_id = var.private_network_id

  fixed_ip {
    subnet_id = var.subnet_id
  }
}

# Создание постоянного сетевого диска
resource "openstack_blockstorage_volume_v3" "boot" {
  name                 = "vol-${var.server_name}"
  size                 = "10"
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
  key_pair          = var.key_pair_name
  availability_zone = var.availability_zone
  
  # Используем ID флейвора, который пришел сверху из главного файла
  flavor_id         = var.flavor_id 

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

# Аренда статического публичного IP-адреса
resource "openstack_networking_floatingip_v2" "this" {
  pool = "external-network"
}

# Связывание публичного IP-адреса с портом
resource "openstack_networking_floatingip_associate_v2" "this" {
  floating_ip = openstack_networking_floatingip_v2.this.address
  port_id     = openstack_networking_port_v2.this.id
}

# Выходной параметр модуля
output "public_ip" {
  value = openstack_networking_floatingip_v2.this.address
}
