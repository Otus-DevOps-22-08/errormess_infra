#!/bin/bash
sudo apt update
echo 'sleep 4m for install updates'; sleep 4m; echo "start install ruby"
sudo apt install -y ruby-full ruby-bundler build-essential
#test
