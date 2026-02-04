
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

#-------------------------------------------------------------------------------------

# отправляем запрос к API облака, с целью получить все сети в моем проекте и отфильтровать только те, у которых флаг external равен true".
# если такая сеть найдена, её параметры (ID, имя и т.д.) сохраняются в этом data-блоке.
#
# Еще один вариант объяснения:
#
# Блок data "openstack_networking_network_v2" "my_external_network" — это поисковый запрос, который находит в вашем облачном проекте предустановленную провайдером публичную сеть.
# Его основная цель в примере — предоставить информацию (ID или имя этой сети) для другого ресурса, который создает и назначает публичный IP-адрес вашему серверу.
#
# Вот пример того что получаем от облака:
#
# data.openstack_networking_network_v2.my_external_network
# {
#   "admin_state_up" = "true"
#   "all_tags" = toset([])
#   "availability_zone_hints" = tolist([])
#   "description" = ""
#   "dns_domain" = ""
#   "external" = true
#   "id" = "f16140a4-e736-4655-9a1b-d7d2df6f969e" <----------------- id внешней сети (у которой есть доступ в интернет)
#   "matching_subnet_cidr" = tostring(null)
#   "mtu" = 1500
#   "name" = "external-network"                   <----------------- обрати внимание на этом имя (оно потом будет использоваться для получения внешнего ip адреса из этой сети ниже в коде)
#   "network_id" = tostring(null)
#   "region" = "ru-9"
#   "segments" = toset([])
#   "shared" = "false"
#   "status" = tostring(null)
#   "subnets" = tolist([
#     "0a70ca1b-6613-49a3-9e65-a89d484330f7",
#     "0fe7a122-c205-4ece-ba0f-94e4497d955f",
#     "1751014e-9207-40a3-ac7a-7763dd0029a4",
#     "23a85638-428b-44f0-a4e0-d2fbb48f0093",
#     "2afae582-6c48-4d59-981e-f499fb61b1ea",
#     "2b6e3274-08cc-46ea-89ad-672fee9122ae",
#     "30ab21be-e7fe-4ae1-a381-0426e4a6e0b0",
#     "e945f98d-99bf-41b6-9bc2-c9e82ee3789b",
#     "ebece733-c29f-463c-ae07-711e548edf62",
#   ])
#   "tags" = toset(null) /* of string */
#   "tenant_id" = "5e204c6ffe184b9f8b69344d36178244"
#   "transparent_vlan" = false
# }
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

# получаем данные об образе из API облака
# 
# вот пример данных которые получаем:
#
# data.openstack_images_image_v2.image_1
# {
#   "checksum" = "97d4e186acf08652845014cc8ceda444"
#   "container_format" = "bare"
#   "created_at" = "2026-02-03T06:42:22Z"
#   "disk_format" = "raw"
#   "file" = "/v2/images/deaffa57-a54a-4018-a818-f56ae92f7cec/file"
#   "hidden" = false
#   "id" = "deaffa57-a54a-4018-a818-f56ae92f7cec"
#   "member_status" = tostring(null)
#   "metadata" = tomap({})
#   "min_disk_gb" = 5
#   "min_ram_mb" = 512
#   "most_recent" = true
#   "name" = "Ubuntu 20.04 LTS 64-bit"
#   "name_regex" = tostring(null)
#   "owner" = "3acf7ceddc024b86b86ef151e4972805"
#   "properties" = tomap({
#     "direct_url" = "rbd://49f37ff2-48ad-4eb7-962e-4e6365bc9c03/images/deaffa57-a54a-4018-a818-f56ae92f7cec/snap"
#     "hw_disk_bus" = "scsi"
#     "hw_qemu_guest_agent" = "yes"
#     "hw_scsi_model" = "virtio-scsi"
#     "os_distro" = "ubuntu"
#     "os_hash_algo" = "sha512"
#     "os_hash_value" = "1e1d7fa0ced3b190f5ad0150fb3e60a765d51301082ff61f7e13b4af9f97bd7703f0d942bc3d713135354c953c5142f6f4ea748fa248a9a6343c8ecf06b0a1c5"
#     "os_type" = "linux"
#     "stores" = "ru-9a"
#     "watchdog" = "pause"
#     "x_sel_image_agent_type" = "cloud-init"
#     "x_sel_image_os_arch" = "amd64"
#     "x_sel_image_os_dist" = "ubuntu"
#     "x_sel_image_owner" = "Selectel"
#     "x_sel_image_source_file" = "ubuntu-focal-amd64-selectel-master-product-0.1.img"
#     "x_sel_image_type" = "master"
#     "x_sel_os_type" = "linux"
#   })
#   "protected" = false
#   "region" = "ru-9"
#   "schema" = "/v2/schemas/image"
#   "size_bytes" = 4001955840
#   "size_max" = tonumber(null)
#   "size_min" = tonumber(null)
#   "sort" = "name:asc"
#   "tag" = tostring(null)
#   "tags" = toset([])
#   "updated_at" = "2026-02-03T06:45:51Z"
#   "visibility" = "public"
# }
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

# запрашиваем плавающий (внешний) IP-адрес из пула внешней сети с именем external-network
resource "openstack_networking_floatingip_v2" "my_floatingip" {
  pool = "external-network"
}

# связываем плавающий (внешний) IP, с сетевым портом сервера на котором уже висит ip из внутренней сети
# изнутри виртуальной машины будет виден только ip адрес из приватной сети, а внешний ip адрес виден не будет
# это так работает, так как в данном облаке реализован NAT один к одному
#
# NAT 1:1 — это полное зеркалирование всех портов внешнего IP-адреса на все порты внутреннего IP-адреса вашего сервера,
# дающее ему прямое присутствие в интернете под постоянным белым адресом. Всё, что приходит на белый IP, автоматически пересылается на сервер 1:1 без изменений портов.
#
# В OpenStack не всегда используется NAT 1:1, но для прямого доступа к виртуальным машинам извне (Floating IP) - это основной механизм
resource "openstack_networking_floatingip_associate_v2" "association_1" {
  port_id     = openstack_networking_port_v2.my_port.id
  floating_ip = openstack_networking_floatingip_v2.my_floatingip.address
}

# выводим публичный IP-адрес созданного нами сервера
output "server_ip_address" {
  value = openstack_networking_floatingip_v2.my_floatingip.address 
}