#
# Переменные для Selectel провайдера
#

variable "selectel_domain_name" {
  description = "Номер аккаунта в Selectel"
  type        = string
  sensitive   = true
}

variable "selectel_username" {
  description = "Имя основного пользователя в Selectel"
  type        = string
  sensitive   = true
}

variable "selectel_password" {
  description = "Пароль основного пользователя в Selectel"
  type        = string
  sensitive   = true
}

variable "selectel_region" {
  description = "Имя региона в Selectel (ru-9, ru-3 и т.д.)"
  type        = string
  default     = "ru-9"
}

variable "selectel_url" {
  description = "Ссылка по которой доступен Selectel API"
  type        = string
  default     = "https://cloud.api.selcloud.ru/identity/v3/"
}

#
# Переменные для Openstack провайдера
#

variable "openstack_domain_name" {
  description = "Номер аккаунта в Selectel"
  type        = string
  sensitive   = true
}

variable "openstack_region" {
  description = "Имя региона в Selectel (ru-9, ru-3 и т.д.)"
  type        = string
  default     = "ru-9"
}

variable "openstack_url" {
  description = "Ссылка по которой доступен Selectel API"
  type        = string
  default     = "https://cloud.api.selcloud.ru/identity/v3/"
}

#
# Переменные для проекта
# 

resource "random_password" "my_serviceuser_1_password" {
  length = 20
  description = "Сгенерируем случайный пароль для нашего будущего сервисного пользователя my_serviceuser_1"
}