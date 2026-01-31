
Еще не готово, надо пройти этот путь и убрать этот комментарий <---- (пока просто добавил в гит чтобы потом не начинать с нуля)

Lesson 4 - из под основного сервисного пользователя, в существующем проекте my_project, создаем облачный сервер my_test_server_1, произвольной конфигурации
           с загрузочным сетевым диском и дополнительным сетевым диском. Это включает в себя создание таких openstack сущностей:
           flavor, keypair, network (private), subnet for network (also for private), external network, router, router interface, port, volume 1, volume 2, server, floatingip_1

1. terraform init

2. terraform plan

3. terraform apply

4. terraform destroy