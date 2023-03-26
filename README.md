# errormess_infra
errormess Infra repository
---
## Знакомство с Terraform
#### Выполненные работы
1. Создаем ветку **terraform-1** и устанавливаем дистрибутив Terraform
```bash
git checkout -b terraform-1
wget wget https://releases.hashicorp.com/terraform/0.12.29/terraform_0.12.29_darwin_amd64.zip
unzip wget https://releases.hashicorp.com/terraform/0.12.29/terraform_0.12.29_darwin_amd64.zip
sudo mv terraform /usr/local/bin; rm terraform_0.12.29_darwin_amd64.zip
terraform -v
Terraform v0.12.29
```
2. Создаем каталог **terraform** с **main.tf** внутри и добавляем исключения в **.gitignore**
```bash
mkdir terraform; touch terraform/main.tf
cat .gitignore
...
### Terraform files
*.tfstate
*.tfstate.*.backup
*.tfstate.backup
*.tfvars
.terraform/
...
```
3. Редактируем **main.tf** и проводим инцициализацию
```
cat main.tf
provider "yandex" {
  cloud_id  = "asdfg"
  folder_id = "123asdf"
  zone      = "ru-central1-a"
}
```
```
terraform init
```
4. Создаем инстанс с помощью **terraform**
Заполняем main.tf конфигурацией из задания и делаем
```
terraform plan
```
затем
```
terraform apply
```
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```
5. Провряем подключение и создаем **outputs.tf**.
добавлаем строчки в наш **main.tf**
```
resource "yandex_compute_instance" "app" {
...
  metadata = {
  ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
...
}
и пересоздаем
```
terraform destroy -auto-approve
terraform apply -auto-approve
```
пробуем
```
ssh -i ~/.ssh/id_rsa ubuntu@ip
```
все работает, теперь создаем **outputs.ts** для вывода внешнего IP
```
cat outputs.tf
output "external_ip_address_app" {
  value = yandex_compute_instance.app.network_interface.0.nat_ip_address
}
```
проверяем
```
terraform refresh
terraform output
external_ip_address_app = 1.2.3.4
```
6. Настраиваем провижионеры, заливаем подготовленный за ранее puma.service на создаваемый инстанс для этого добавляем в **main.tf** провижионер file:
```
  provisioner "file" {
    source      = "files/puma.service"
    destination = "/tmp/puma.service"
  }
  ```
  для запуска приложения используем скрипт **deploy.sh**, для которого используем remote-exec
  ```
    provisioner "remote-exec" {
    script = "files/deploy.sh"
  }
  ```
  Для подключения используем  connection
  ```
    connection {
    type  = "ssh"
    host  = yandex_compute_instance.app.network_interface.0.nat_ip_address
    user  = "ubuntu"
    agent = false
    # путь до приватного ключа
    private_key = file("~/.ssh/id_rsa")
  }
  ```
для того чтобы наши изменения применились
```
terraform taint yandex_compute_instance.app
terraform plan
terraform apply
```
7.  Использование input vars, для начала опишем наши переменные в **variables.tf**
```
...
variable cloud_id {
  description = "Cloud"
}
...
```
параметры для переменные записываем в **terraform.tfvars**
```
...
cloud_id  = "123"
...
```
теперь указываем эти параметры в **main.tf**
```
cloud_id                 = var.cloud_id
```
И так делаем для других параметров, затем перепроверяем
```
terraform destroy -auto-approve
terraform apply -auto-approve
```
#### Задание со ⭐⭐
1. Создаем файл **lb.tf**
2. Первым делом нужно  создать *target group*, которую мы позже подключим к балансировщику
```terraform
resource "yandex_lb_target_group" "loadbalancer" {
  name      = "lb-group"
  folder_id = var.folder_id
#требуется указать регион.
  region_id = var.region_id

  target {
    address = yandex_compute_instance.app.network_interface.0.ip_address
      subnet_id = var.subnet_id
  }
}
```
2. Теперь необходимо создать сам балансировщик и указать для него целевую группу
```terraform
resource "yandex_lb_network_load_balancer" "lb" {
  name = "loadbalancer"
  type = "external"

  listener {
    name        = "listener"
    port        = 80
    target_port = 9292

    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.loadbalancer.id

    healthcheck {
      name = "tcp"
      tcp_options {
        port = 9292
      }
    }
  }
}
```
3.  Добавляем переменные в **output.tf**
```
output "loadbalancer_ip_address" {
  value = yandex_lb_network_load_balancer.lb.listener.*.external_address_spec[0].*.address
}
```
и собираем
```bash
terraform plan; terraform apply -auto-approve
```
4. Создаем еще один ресурс **reddit-app2** по аналогии с первым
```terraform
resource "yandex_compute_instance" "app2" {
  name = "reddit-app2"
  ...
}
```
добавляем его в целевую группу
```
  target {
    address = yandex_compute_instance.app2.network_interface.0.ip_address
      subnet_id = var.subnet_id
  }
```
и правим **output.tf**
```
output "external_ip_addresses_app" {
  value = yandex_compute_instance.app[*].network_interface.0.nat_ip_address
}
```
5. Создаем инстанцы с помощью **count**, которую указываем как пременную, в **variables.tf** с дефолтным значением 1
```
variable instances {
  description = "count instances"
  default     = 1
}
```
удаляем второй инстанс и редактируем первый
```
resource "yandex_compute_instance" "app" {
  count = var.instances
  name  = "reddit-app-${count.index}"
  ...
  connection {
  ...
    host  = self.network_interface.0.nat_ip_address
  }
  ...
}
```
затем правим таргет групп используя блок **dynamic**
```
 dynamic "target" {
    for_each = yandex_compute_instance.app.*.network_interface.0.ip_address
    content {
      subnet_id = var.subnet_id
      address   = target.value
    }
  }
```
добавляем в наши переменные значение 2, собираем и проверяем
```bash
terraform plan; terraform apply -auto-approve
```
---
## Подготовка образов с помощью packer
#### Выполненные работы
1. Создаем новую ветку **packer-base** и переносим скрипты из предыдущего ДЗ в **config-scripts**
2. Устанавливаем packer
3. Создаем сервисный аккаунт в **yc**
```bash
SVC_ACCT="service"
FOLDER_ID="abcde"
yc iam service-account create --name $SVC_ACCT --folder-id $FOLDER_ID
```
предоставляем ему права **editor**
```bash
ACCT_ID=$(yc iam service-account get $SVC_ACCT |  grep ^id | awk '{print $2}')
yc resource-manager folder add-access-binding --id $FOLDER_ID --role editor --service-account-id $ACCT_ID
```
создаем IAM ключ
```bash
yc iam key create --service-account-id $ACCT_ID --output /home/appuser/key.json
```
4.Создаем шаблон **packer**
```bash
mkdir packer
touch packer\ubuntu16.json
mkdir packer\scripts
cp config-scripts\install_ruby.sh packer\scripts\
cp config-install_mongodb.sh packer\scripts\
```
Заполняем шаблон **ubuntu16.json**
```json
{
    "builders": [
        {
            "type": "yandex",
            "service_account_key_file": "./key.json",
            "folder_id": "ID_NUMBER",
            "source_image_family": "ubuntu-1604-lts",
            "image_name": "reddit-base-{{timestamp}}",
            "image_family": "reddit-base",
            "ssh_username": "ubuntu",
            "use_ipv4_nat": "true",
            "platform_id": "standard-v1"
        }
    ],
    "provisioners": [
        {
            "type": "shell",
            "script": "scripts/install_ruby.sh",
            "execute_command": "sudo {{.Path}}"
        },
        {
            "type": "shell",
            "script": "scripts/install_mongodb.sh",
            "execute_command": "sudo {{.Path}}"
        }
    ]
}
```
5. Проверяем и собираем образ
```bash
packer validate ./ubuntu16.json
packer build ./ubuntu16.json
```
Необходимо добавить в скрипт **install_ruby.sh**, строчку после **apt update**
6. Проверяем работу нашего образа
7. Создаем файлы с переменными **variables.json** и **variables.json.example**
```json
{
  "key": "key.json",
  "fid": "ID_NUMBER",
  "image": "ubuntu-1604-lts"
}
```
8. Добвляем **variables.json** в **.gitignore**
## Работы с SSH / VPN
#### Выполненные работы
#Task: SSH
```
ssh -i ~/.ssh/appuser -J appuser@158.160.32.24 appuser@10.128.0.17
```
```
Host someinternalhost
        HostName 10.128.0.17
        User appuser
        ProxyJump appuser@158.160.32.24

Host bastion
        HostName 158.160.32.24
        User appuser
```
#Task VPN
```
https://158.160.32.24
bastion_IP = 158.160.32.24
someinternalhost_IP = 10.128.0.17
```
#Task reddit-app
```
testapp_IP = 158.160.34.149
testapp_port = 9292
```