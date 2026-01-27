provider "selectel" {
  domain_name = var.selectel_domain_name
  username    = var.selectel_username
  password    = var.selectel_password
  auth_region = var.selectel_region
  auth_url    = var.selectel_url
}

provider "openstack" {
  domain_name = var.openstack_domain_name
  tenant_id   = selectel_vpc_project_v2.my_project.id
  user_name   = selectel_iam_serviceuser_v1.my_serviceuser_1.name
  password    = selectel_iam_serviceuser_v1.my_serviceuser_1.password
  region      = var.openstack_region
  auth_url    = var.openstack_url
}