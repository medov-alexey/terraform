# Список виртуальных машин, которыми мы хотим управлять в облаке Selectel
variable "vps_list" {
  description = "Список серверов для развертывания"
  type        = set(string)
  default     = [
    "web-prod-1",
    "web-prod-2",
    "db-primary",
    "db-replica",
    "cache-server",
    "balancer-node"
  ]
}