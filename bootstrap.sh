#!/usr/bin/env bash

hostname=$1
site=$2

hostname="drupal7vm.dev"
site="rootstalk"


# Use single quotes instead of double quotes to make it work with special-character passwords
PASSWORD='12345678'
PROJECTFOLDER='drupal7'

root="/var/www/${PROJECTFOLDER}"

# create project folder
if [ ! -d "${root}" ]; then
  mkdir "${root}"
fi

# update / upgrade
apt-get update
apt-get -y upgrade

# install apache 2.5 and php 5.5
apt-get install -y apache2
apt-get install -y php5

# install mysql and give password to installer
debconf-set-selections <<< "mysql-server mysql-server/root_password password $PASSWORD"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $PASSWORD"
apt-get -y install mysql-server
apt-get install php5-mysql

# install phpmyadmin and give password(s) to installer
# for simplicity I'm using the same password for mysql and phpmyadmin
debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password $PASSWORD"
debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password $PASSWORD"
debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password $PASSWORD"
debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2"
apt-get -y install phpmyadmin

# setup hosts file
VHOST=$(cat <<EOF
<VirtualHost *:80>
    DocumentRoot "${root}"
    ServerName ${hostname}
    ServerAlias ${hostname} *.${hostname}
    <Directory "${root}">
      AllowOverride All
      Require all granted
    </Directory>
</VirtualHost>
EOF
)
echo "${VHOST}" > /etc/apache2/sites-available/000-default.conf

# cat the .conf file to verify it is correct
echo "Contents of /etc/apache2/sites-available/000-default.conf follow:"
cat /etc/apache2/sites-available/000-default.conf

# enable mod_rewrite
echo "Enable Apache mod-rewrite"
a2enmod rewrite

# restart apache
echo "Restart Apache"
service apache2 restart

# install git
echo "Install git"
apt-get -y install git

# install Composer
echo "Install Composer"
curl -s https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# install drush
echo "Install drush"
apt-get -y install drush

#fetch and install drupal 7 using drush
echo "Install Drupal 7 using drush"
drush -y dl drupal --drupal-project-rename=drupal
cp -fr drupal/* /var/www/${PROJECTFOLDER}
cd /var/www/${PROJECTFOLDER}
chown -R vagrant:www-data .

# create the Drupal /default site and any defined $SITE target
echo "Create the Drupal /default and /${site} sites"
drush -y site-install standard --db-url="mysql://root:${PASSWORD}@localhost/default" --site-name=${hostname} --account-mail="digital@grinnell.edu" --account-pass="${PASSWORD}"
drush -y site-install standard --db-url="mysql://root:${PASSWORD}@localhost/${site}" --sites-subdir=${site} --site-name=${site} --account-pass="${PASSWORD}"

# set /default and /site directory permissions
chmod 774 "${root}/sites/default/files"
chmod 774 "${root}/sites/${site}/files"

# fetch .htaccess
echo "Fetch and apply .htaccess"
if [ ! -f "${root}/.htaccess" ]; then
  cp "${root}/lamp-bootstrap/resources/.htaccess" "${root}/"
fi

# add site.hostname to the ../sites/sites.php file
echo "Adding ${site}.${hostname} to ../sites/sites.php"
cd "${root}/sites"
if [ ! -f sites.php ]; then
  cp example.sites.php sites.php
  chmod 444 sites.php
  echo '' >> sites.php
  echo "\$sites['${site}.${hostname}'] = '${site}';" >> sites.php
  echo '' >> sites.php
  chmod 400 example.sites.php
fi

chown -R vagrant:www-data .







