# errormess_infra
errormess Infra repository

#Task: SSH
ssh -i ~/.ssh/appuser -J appuser@158.160.32.24 appuser@10.128.0.17

Host someinternalhost
        HostName 10.128.0.17
        User appuser
        ProxyJump appuser@158.160.32.24

Host bastion
        HostName 158.160.32.24
        User appuser

#Task VPN
https://158.160.32.24
bastion_IP = 158.160.32.24
someinternalhost_IP = 10.128.0.17

#Task reddit-app
testapp_IP = 158.160.34.149
testapp_port = 9292

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
