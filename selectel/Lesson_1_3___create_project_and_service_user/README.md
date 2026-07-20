Lesson 1.3 - третий демонстрационный пример создания ресурсов через Terraform

Где мы создаем тестовый проект и тестового сервисного пользователя в облаке Selectel за один запуск terraform.
И потом удаляем их (в рамках знакомства с Terraform)

Так как в Selectel по умолчанию можно создавать только один проект на аккаунт, при запуске terraform plan вы можете получить ошибку.

Чтобы не получить ошибку при запуске задачи на создание ресурсов (terraform plan) нужно, либо удалить существующий проект (если он уже существует), либо запросите в поддержке увеличение количества проектов которые можно создать на одном аккаунте.

Пример ошибки:
Error: error creating project: Expected HTTP response code [200] when accessing [POST https://api.selectel.ru/vpc/resell/v2/projects], but got 409 instead {"error": "quota_exceeded"}

1. terraform init

2. terraform plan

3. terraform apply

4. terraform destroy

Так как мы в файле variables.tf сделали так, чтобы при создании пароля для пользователя в выводе логов по умолчанию он не отображался, для просмотра пароля создаваемого в рамках обучения сервисного пользователя нужно использовать команду:

terraform output -raw my_serviceuser_password