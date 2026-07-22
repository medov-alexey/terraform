# Карточка серверов, оптимизированная для развертывания кластера Kubernetes (Lesson 7)
variable "vps_list" {
  description = "Конфигурация пула серверов для кластера Kubernetes"
  type = map(object({
    ram              = number # Объем оперативной памяти в МБ
    vcpus            = number # Количество ядер CPU
    disk_size        = number # Размер системного диска в ГБ (увеличен под образы контейнеров)
    with_external_ip = bool   # Нужен ли публичный IP-адрес для доступа из интернета
  }))
  
  default = {
    # Отдельный сервер для установки кластера (логинимся на него и запускаем Kubespray)
    "k8s-bastion" = {
      ram              = 1024  # Ему не нужны мощности, он просто пересылает команды
      vcpus            = 1
      disk_size        = 10
      with_external_ip = true  # ТОЛЬКО у него будет доступ из интернета
    }
    
    # Control Plane (Master ноды) — требуют минимум 2 CPU и 2GB RAM
    "k8s-master-1" = {
      ram              = 2048
      vcpus            = 2
      disk_size        = 20
      with_external_ip = false
    }
    "k8s-master-2" = {
      ram              = 2048
      vcpus            = 2
      disk_size        = 20
      with_external_ip = false
    }
    "k8s-master-3" = {
      ram              = 2048
      vcpus            = 2
      disk_size        = 20
      with_external_ip = false
    }

    # Worker ноды (Рабочие лошадки, где будут жить контейнеры)
    "k8s-worker-1" = {
      ram              = 2048
      vcpus            = 2
      disk_size        = 25
      with_external_ip = false
    }
    "k8s-worker-2" = {
      ram              = 2048
      vcpus            = 2
      disk_size        = 25
      with_external_ip = false
    }
    "k8s-worker-3" = {
      ram              = 2048
      vcpus            = 2
      disk_size        = 25
      with_external_ip = false
    }
  }
}
