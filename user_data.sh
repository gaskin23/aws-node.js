#!/bin/bash
# Update and install required packages
sudo apt-get update -y
sudo wget http://nginx.org/keys/nginx_signing.key
sudo apt-get install git -y
sudo apt-key add nginx_signing.key
sudo apt-get update -y
sudo apt install nginx
sudo systemctl start nginx.service
sudo systemctl enable nginx.service
# Install Node.js using Node Version Manager (NVM)
sudo apt-get install -y git nodejs npm nginx
git clone https://github.com/contentful/the-example-app.nodejs.git
cd the-example-app.nodejs
# Install app dependencies
npm install
npm run start:dev