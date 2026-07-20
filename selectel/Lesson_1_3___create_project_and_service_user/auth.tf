# В этом файле перечисляем необходимые данные для авторизации в определенном провайдере

provider "selectel" {
  domain_name = var.selectel_domain_name
  username    = var.selectel_username
  password    = var.selectel_password
  auth_region = var.selectel_region
  auth_url    = var.selectel_url
}