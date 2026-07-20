output "my_serviceuser_password" {
  value     = random_password.my_serviceuser_password.result
  sensitive = true
  description = "Пароль для создаваемого сервисного пользователя my_serviceuser (используйте: terraform output -raw my_serviceuser_password)"
}