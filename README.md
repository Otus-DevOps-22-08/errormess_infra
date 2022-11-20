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
