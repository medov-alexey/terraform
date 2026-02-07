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