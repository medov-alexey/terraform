#
# 1.
#
# Как установить terraform клиент на debian based linux 
#
# используя прокси для доступа к сайту hashicorp (который на данный момент недоступен из россии)
#

sudo su

export http_proxy="http://10.20.30.40:8888"
export https_proxy="http://10.20.30.40:8888"

cd /tmp && wget https://releases.hashicorp.com/terraform/1.14.4/terraform_1.14.4_linux_amd64.zip && \
unzip terraform_1.14.4_linux_amd64.zip && mv ./terraform /bin/ && terraform version && terraform --help && rm -rf ./terraform*

#
# Другие способы установки клиента смотри на оффицальном сайте https://developer.hashicorp.com/terraform/install
#



#
# 2.
#
# В личном аккаунте Selectel нужно завести сервисного пользователя, назовем его например my-test-user, с двумя ролям:
# - iam.admin (область доступа: аккаунт)
# - member (область доступа: аккаунт)


#
# 3.
#
# Добавляем все необходимые переменные с значениями в файл и сохраняем его
nano ~/terraform-selectel

#! only for learning (my own account)
export TF_VAR_selectel_url="https://cloud.api.selcloud.ru/identity/v3/"
export TF_VAR_selectel_domain_name="123456"
export TF_VAR_selectel_username="my-test-user"
export TF_VAR_selectel_password="XXXXXXXXXXXXXXX"
export TF_VAR_selectel_region="ru-9"
export TF_VAR_selectel_user_id="fa7e5b21ec5541fba6a2f8182edad6cb"
export TF_VAR_selectel_project_id="e2fb376a3e07422c817e710b930480a1"
export TF_VAR_openstack_url="https://cloud.api.selcloud.ru/identity/v3/"
export TF_VAR_openstack_domain_name="123456"
export TF_VAR_openstack_region="ru-9"

# Где переменная TF_VAR_selectel_user_id должна содержать id пользователя указанного в переменной TF_VAR_selectel_username
# Значения для переменной TF_VAR_selectel_project_id можно посмотреть в личном аккаунте пользователя Selectel.