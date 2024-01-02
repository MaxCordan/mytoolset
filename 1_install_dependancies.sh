#!/bin/sh
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y git curl wget zsh unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install
rm -rf awscliv2.zip aws
