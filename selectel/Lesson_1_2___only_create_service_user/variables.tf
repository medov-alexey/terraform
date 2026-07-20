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
# Дополнительные переменные
# 

variable "set_manual_project_id" {
  description = "Укажите ID существующего проекта в вашем личном аккаунте Selectel в котором будем работать"
  type        = string
}
# если переменная set_manual_project_id не будет задана в переменных окружения, или в default, то
# потребуется ввести ее при запуске команды terraform apply (будет выведен запрос на ввод)


resource "random_password" "my_serviceuser_password" {
  length           = 20    # Сгенерируем случайный пароль для нашего будущего сервисного пользователя my_serviceuser длинной в 20 символов
  special          = true  # Обязательно использовать спецсимволы (@, #, $ и т.д.)
  upper            = true  # Обязательно заглавные буквы
  lower            = true  # Обязательно строчные буквы
  numeric          = true  # Обязательно цифры
  override_special = "!_-%" # Selectel иногда не любит слишком экзотические символы, лучше ограничить этим набором
}
# Для просмотра сгенерированного нами пароля для сервисного пользователя введите эту команду:
#
# terraform output -raw my_serviceuser_password 