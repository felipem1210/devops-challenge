#!/bin/bash
# Script to install apache and necessary software

set -e
apt-get update -y
apt-get install nginx -y
echo "Hello World!" > /usr/share/nginx/html/index.html