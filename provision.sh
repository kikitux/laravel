#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
PACKAGES=(apache2 mariadb-client mariadb-server php5 php5-cli php5-mysql php5-gd php5-curl nodejs npm git)

apt-get update
apt-get install -y -q --no-install-recommends "${PACKAGES[@]}"

grep -q '<Directory /vagrant/app/public/>' '/etc/apache2/sites-enabled/000-default.conf' || {
	tee '/etc/apache2/sites-enabled/000-default.conf' >/dev/null <<-EOF
		<Directory /vagrant/app/public>
		    Options Indexes FollowSymLinks
		    AllowOverride All
		    Require all granted
		</Directory>
		<VirtualHost *:80>
		    DocumentRoot /vagrant/app/public
		    ErrorLog \${APACHE_LOG_DIR}/error.log
		    CustomLog \${APACHE_LOG_DIR}/access.log combined
		</VirtualHost>
		EOF
}

if [ ! -f "/usr/bin/composer" ]; then
	php -r "readfile('https://getcomposer.org/installer');" | php
	mv composer.phar /usr/bin/composer
	chown root:root /usr/bin/composer
	chmod 755 /usr/bin/composer
fi

if [ ! -d "/vagrant/app" ]; then
	composer create-project --prefer-dist laravel/laravel /vagrant/app
fi

mysqlshow laravel
RET=$?
if [ ${RET} -ne 0 ]; then
	mysql -u root -e "CREATE DATABASE laravel CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci;"
fi

a2enmod rewrite >/dev/null
service apache2 restart >/dev/null

grep bind /home/vagrant/.bash_profile || {
  echo "mkdir -p /vagrant/app/node_modules /home/vagrant/node_modules"| tee -a /home/vagrant/.bash_profile
  echo "sudo mount --bind /home/vagrant/node_modules /vagrant/app/node_modules" | tee -a /home/vagrant/.bash_profile
}
