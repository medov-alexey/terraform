#
# Переменные для Selectel провайдера
#

variable "selectel_domain_name" {
  description = "Номер аккаунта в Selectel"
  type        = string
  sensitive   = true
}

variable "selectel_username" {
  description = "Имя основного сервисного пользователя в Selectel (должен быть создан вручную через личный кабинет Selectel, можно назвать как угодно, например my_main_service_user)"
  type        = string
  sensitive   = true
}

variable "selectel_password" {
  description = "Пароль основного сервисного пользователя в Selectel"
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
# Пример того, как указать значения для этой переменной: 
#
# export TF_VAR_selectel_project_id="e2fb376a3e07422c817e710b930480a1"
#

variable "selectel_project_id" {
  description = "ID существующего проекта в котором будем управлять ресурсами (можно посмотреть в личном кабинете Selectel, id нужного нам проекта)"
  type        = string
  sensitive   = true
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
