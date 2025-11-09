#!/usr/bin/env bash
set -e

echo "=== Installing MySQL ==="
sudo apt-get update -y
sudo apt-get install -y mysql-server

sudo systemctl enable mysql
sudo systemctl start mysql

sudo sed -i "s/bind-address.*/bind-address = 192.168.56.10/" /etc/mysql/mysql.conf.d/mysqld.cnf
sudo systemctl restart mysql

mysql -u root <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS ${DB_NAME};
CREATE USER IF NOT EXISTS '${DB_USER}'@'192.168.56.%' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'192.168.56.%';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

echo "✅ MySQL configured with ${DB_NAME}"

