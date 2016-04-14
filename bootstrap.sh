#!/bin/bash

echo "This is bootstrap.sh"
echo "-----------------------------------------------------------------"

# Read configuration variables using technique documented at https://gist.github.com/pkuczynski/8665367
share=$1
cd $share
# include parse_yaml function
. parse_yaml.sh
# read yaml file
eval $(parse_yaml config.yaml)

hostname=$config_hostname
site=$config_site
PASSWORD=$config_password
PROJECTFOLDER=$config_drupal_dir

# Use single quotes instead of double quotes to make it work with special-character passwords
#PASSWORD='12345678'
#PROJECTFOLDER='drupal7'

# specify the Drupal document root
droot="/var/www/${PROJECTFOLDER}"

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
    DocumentRoot "${droot}"
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

# create the Drupal root folder if it does not already exist
if [ ! -d "${droot}" ]; then
  mkdir "${droot}"
fi

#fetch and install drupal 7 using drush IF it does NOT already exist
echo "Install Drupal 7 using drush"
if [ ! -f ${droot}/LICENSE.txt ]; then
  cd /tmp
  drush -y dl drupal --drupal-project-rename=drupal
  cp -fr drupal/* ${droot}
  chown -R vagrant:www-data ${droot}
fi

# create the Drupal /default site and any defined $site target
echo "Create the Drupal /default and /${site} sites"
cd ${droot}
drush -y site-install standard --db-url="mysql://root:${PASSWORD}@localhost/default" --site-name=${hostname} --account-mail="digital@grinnell.edu" --account-pass="${PASSWORD}"
drush -y site-install standard --db-url="mysql://root:${PASSWORD}@localhost/${site}" --sites-subdir=${site} --site-name=${site} --account-pass="${PASSWORD}"

# set /default and /site directory permissions
chmod 774 "${droot}/sites/default/files"
chmod 774 "${droot}/sites/${site}/files"

# set the site_name (title) variable
cd ${droot}/sites/${site}
drush -u 1 vset site_name ${config_site_name}

# fetch .htaccess
echo "Fetch and apply .htaccess"
if [ ! -f "${droot}/.htaccess" ]; then
  cp "${share}/resources/.htaccess" "${droot}/"
fi

# add site.hostname to the ../sites/sites.php file
echo "Adding ${site}.${hostname} to ../sites/sites.php"
cd "${droot}/sites"
if [ ! -f sites.php ]; then
  cp example.sites.php sites.php
  chmod 444 sites.php
  echo '' >> sites.php
  echo "\$sites['${site}.${hostname}'] = '${site}';" >> sites.php
  echo '' >> sites.php
  chmod 400 example.sites.php
fi

# Apply a custom theme!  Via Git (value begins with "http") or from Drupal?
theme=$config_theme
if [[ ${theme} == "http"* ]]
then
  git=1
  drupal=0
elif [[ ${theme} != "" ]]
then
  drupal=1
  git=0
else
  echo "No custom theme specified."
  exit
fi

if [ ! -d "${droot}"/sites/${site}/themes ]; then
  mkdir "${droot}"/sites/${site}/themes || exit
fi

# Apply a custom theme using Git if one is defined
# (if the value starts with "http").
if [[ ${git} -eq 1 ]]
then
  echo "Cloning custom theme using Git from ${theme}"
  cd "${droot}"/sites/${site}/themes || exit
  git clone ${theme}
  cd */ || exit
  git config core.filemode false
  info=`ls *.info`
  echo "The theme's .info file is: ${info}"
  filename=$(basename "${info}")
  dtheme="${filename%.*}"
  cd "${droot}"/sites/${site} || exit
  echo "The custom theme '${dtheme}' will be enabled and set as the default for site ${site}"
  drush -y -u 1 en ${dtheme}
  drush -u 1 vset theme_default ${dtheme}
fi

# Apply a custom Drupal.org theme if one is defined
# (if the value does not begin with "http").
if [[ ${drupal} -eq 1 ]]
then
  echo "Downloading and enabling Drupal theme '${theme}"
  cd "${droot}"/sites/${site}/themes || exit
  drush -y -u 1 dl ${theme}
  cd "${droot}"/sites/${site} || exit
  echo "The custom theme '${theme}' will be enabled and set as the default for site ${site}"
  drush -y -u 1 en ${theme}
  drush -u 1 vset theme_default ${theme}
fi

cd ${droot}
chown -R vagrant:www-data .







