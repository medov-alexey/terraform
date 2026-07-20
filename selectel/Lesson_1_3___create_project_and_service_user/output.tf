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

output "my_serviceuser_password" {
  value     = random_password.my_serviceuser_password.result
  sensitive = true
  description = "Пароль для создаваемого сервисного пользователя my_serviceuser (используйте: terraform output -raw my_serviceuser_password)"
}

output "my_serviceuser_name" {
  value     = selectel_iam_serviceuser_v1.my_serviceuser.name
  sensitive = false
  description = "Пароль для создаваемого сервисного пользователя my_serviceuser (используйте: terraform output -raw my_serviceuser_password)"
}