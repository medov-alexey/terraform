output "db_password" {
  value     = random_password.my_serviceuser_1_password.result
  sensitive = true
  description = "Пароль для создаваемого сервисного пользователя my_serviceuser_1 (используйте: terraform output -raw my_serviceuser_1_password)"
}