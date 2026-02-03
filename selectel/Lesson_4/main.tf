
# Добавляем свой личный SSH ключ для доступа на создаваемую нами виртуальную машину
resource "selectel_vpc_keypair_v2" "my_ssh_keypair" {
  name       = "my_ssh_keypair"
  public_key = file("~/.ssh/id_rsa.pub")
  user_id    = var.selectel_user_id
}

# создаем свой собственный flavor с названием tiny (виртуальные машины с этим flavor будут иметь 1 ядро и 1 гиг памяти)
resource "openstack_compute_flavor_v2" "tiny" {
  name      = "tiny"
  vcpus     = 1
  ram       = 1024
  disk      = 0
  is_public = false

  lifecycle {
    create_before_destroy = true
  }

}

# создаем приватную сеть 
resource "openstack_networking_network_v2" "my_private_network" {
  name           = "my_private_network"
  admin_state_up = "true"
}

# создаем подсеть в нашей приватной сети которую создали выше 
resource "openstack_networking_subnet_v2" "subnet_for_my_private_network" {
  name       = "subnet_for_my_private_network"
  network_id = openstack_networking_network_v2.my_private_network.id
  cidr       = "192.168.200.0/24"
}

#-------------------------------------------------------------------------------------

# получаем информацию о существующей внешней сети
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

# cоздаем сетевой порт в приватной сети и назначим ему фиксированный ip типа 192.168.200.XXX (далее, чуть ниже в этом коде, подключим этот порт к нашей виртуальной машине)
resource "openstack_networking_port_v2" "my_port" {
  name       = "my_port"
  network_id = openstack_networking_network_v2.my_private_network.id

  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.subnet_for_my_private_network.id
  }
}

#-------------------------------------------------------------------------------------

# получаем данные об образе
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

# cоздаем виртуальную машину с заданными параметрами (используем наши flavor, ключ SSH, диски и сетевой порт)
resource "openstack_compute_instance_v2" "server_1" {
  name              = "server_1"
  flavor_id         = openstack_compute_flavor_v2.tiny.id
  key_pair          = selectel_vpc_keypair_v2.my_ssh_keypair.name
  availability_zone = "ru-9a"

  network {
    port = openstack_networking_port_v2.my_port.id
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

  # указываем дополнительный диск
  block_device {
    uuid             = openstack_blockstorage_volume_v3.volume_2.id
    source_type      = "volume"
    destination_type = "volume"
    boot_index       = -1
  }

  vendor_options {
    ignore_resize_confirmation = true
  }
}

# запрашиваем плавающий (внешний) IP-адрес из пула внешней сети
resource "openstack_networking_floatingip_v2" "my_floatingip" {
  pool = "external-network"
}

# связываем плавающий (внешний) IP с сетевым портом сервера на котором уже висит ip из внутренней сети
resource "openstack_networking_floatingip_associate_v2" "association_1" {
  port_id     = openstack_networking_port_v2.my_port.id
  floating_ip = openstack_networking_floatingip_v2.my_floatingip.address
}

# выводим публичный IP-адрес созданного сервера
output "public_ip_address" {
  value = openstack_networking_floatingip_v2.my_floatingip.fixed_ip
}