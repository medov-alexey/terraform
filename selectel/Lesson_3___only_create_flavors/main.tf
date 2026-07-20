resource "openstack_compute_flavor_v2" "type-1c1g" {
  name  = "type-1c1g"
  ram   = "1024"
  vcpus = "1"
  disk  = "0"
}

resource "openstack_compute_flavor_v2" "type-4c32g" {
  name  = "type-4c32g"
  ram   = "32384"
  vcpus = "4"
  disk  = "0"
}