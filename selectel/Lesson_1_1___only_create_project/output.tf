output "project_name" {
  value     = selectel_vpc_project_v2.my_project.name
  sensitive = false
  description = "Имя нашего проекта который будет создан в личном кабинете Selectel"
}

output "project_id" {
  value     = selectel_vpc_project_v2.my_project.id
  sensitive = false
  description = "Уникальный ID нашего проекта который будет создан в личном кабинете Selectel"
}