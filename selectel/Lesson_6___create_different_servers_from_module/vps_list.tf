# Карта серверов с их индивидуальными системными и сетевыми характеристиками
variable "vps_list" {
  description = "Конфигурация пула серверов"
  type = map(object({
    ram              = number # Объем оперативной памяти в МБ
    vcpus            = number # Количество ядер CPU
    disk_size        = number # Размер системного диска в ГБ
    with_external_ip = bool   # Нужен ли публичный IP-адрес из интернета
  }))
  
  default = {
    "web-prod-1" = {
      ram              = 2048
      vcpus            = 2
      disk_size        = 15
      with_external_ip = true
    }
    "web-prod-2" = {
      ram              = 2048
      vcpus            = 2
      disk_size        = 15
      with_external_ip = true
    }
    "db-primary" = {
      ram              = 1024
      vcpus            = 1
      disk_size        = 10
      with_external_ip = false # База данных должна быть спрятана внутри приватной сети!
    }
    "db-replica" = {
      ram              = 1024
      vcpus            = 1
      disk_size        = 10
      with_external_ip = false # Защищаем реплику от внешнего мира
    }
    "cache-server" = {
      ram              = 1024
      vcpus            = 1
      disk_size        = 10
      with_external_ip = false # Кэшу не нужен доступ снаружи
    }
    "balancer-node" = {
      ram              = 1024
      vcpus            = 1
      disk_size        = 12
      with_external_ip = true  # Балансировщик принимает весь трафик из интернета
    }
  }
}
