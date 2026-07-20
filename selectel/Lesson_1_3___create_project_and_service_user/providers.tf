terraform {
  required_providers {
    selectel  = {
      source  = "selectel/selectel"
      version = "~> 6.0"
    }
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "2.1.0"
    }
  }
}
