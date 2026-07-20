# Создаем проект
resource "selectel_vpc_project_v2" "my_project" {
  name = "my_project"
}

# создаем приватную сеть и сразу ее активируем
resource "openstack_networking_network_v2" "my_test_private_network" {
  name           = "my_test_private_network"
  admin_state_up = "true"
}

# создаем подсеть для нашей приватной сети (указываем к какой сети относится подсеть, диапазон адресов и включаем DHCP)
resource "openstack_networking_subnet_v2" "my_test_private_network_subnet" {
  name       = "my_test_private_network_subnet"
  network_id = openstack_networking_network_v2.my_test_private_network.id
  cidr       = "192.168.200.0/24"
  enable_dhcp = true
}