# Конфигурация провайдеров, которая берет данные из ваших системных переменных через префикс TF_VAR_
provider "selectel" {
  domain_name = var.selectel_domain_name
  username    = var.selectel_username
  password    = var.selectel_password
  auth_region = var.selectel_region
  auth_url    = var.selectel_url
}

provider "openstack" {
  domain_name = var.openstack_domain_name
  tenant_id   = var.selectel_project_id
  user_name   = var.selectel_username
  password    = var.selectel_password
  region      = var.openstack_region
  auth_url    = var.openstack_url
}
