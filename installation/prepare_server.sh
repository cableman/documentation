#!/usr/bin/env bash

##################################################################
# This script is used to install the stack required to run the
# application.
#
# It assumes that you have a clean install Debian 8 server.
##################################################################

## Disable term blank
setterm -blank 0

## Define colors.
BOLD=$(tput bold)
UNDERLINE=$(tput sgr 0 1)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
RESET=$(tput sgr0)

##
# Update the OS packages.
##
function updateSystem {
	echo "${GREEN}Updating system packages...${RESET}"
  apt-get update > /dev/null || exit 1
  apt-get upgrade -y > /dev/null || exit 1
}

##
# Install MySQL server
##
function intallMySQL {
	echo "${GREEN}Configuring MySQL...${RESET}"
	echo -n "MySQL root password: "
	read -s PASSWORD
	echo " "

	debconf-set-selections <<< "mysql-server-5.5 mysql-server/root_password password ${PASSWORD}" > /dev/null || exit 1
	debconf-set-selections <<< "mysql-server-5.5 mysql-server/root_password_again password ${PASSWORD}" > /dev/null || exit 1

	echo "${GREEN}Installing MySQL...${RESET}"
	apt-get install -y mysql-server > /dev/null || exit 1
}

##
# Install PHP
##
function installPHP {
	echo "${GREEN}Installing PHP-5.x${RESET}"
	apt-get install -y php5 php5-cli php5-mysql php5-curl php5-mcrypt php5-gd php-pear php5-dev libapache2-mod-php5 > /dev/null || exit 1

	sed -i '/;date.timezone =/c date.timezone = Europe/Copenhagen' /etc/php5/apache2/php.ini
	sed -i '/;date.timezone =/c date.timezone = Europe/Copenhagen' /etc/php5/apache2/php.ini

	sed -i '/upload_max_filesize = 2M/cupload_max_filesize = 256M' /etc/php5/apache2/php.ini
	sed -i '/post_max_size = 8M/cpost_max_size = 300M' /etc/php5/apache2/php.ini

	# Set php memory limit to 256mb
	sed -i '/memory_limit = 128M/c memory_limit = 256M' /etc/php5/apache2/php.ini
}

##
# Install redis-server (use as cache).
##
function installCaches {
	echo "${GREEN}Installing redis server...${RESET}"
	apt-get install -y redis-server > /dev/null || exit 1
}

##
# Install Apache http server.
##
function installApache {
	echo "${GREEN}Installing Apache...${RESET}"
	apt-get install -y apache2 > /dev/null || exit 1

	echo "${GREEN}Enable Apache modules...${RESET}"
	a2enmod expires > /dev/null || exit 1
	a2enmod rewrite > /dev/null || exit 1
	a2enmod ssl > /dev/null || exit 1
	a2enmod proxy > /dev/null || exit 1
	a2enmod proxy_http > /dev/null || exit 1
	a2enmod proxy_wstunnel > /dev/null || exit 1
}

##
# Install NodeJs.
##
function installNodeJs {
	echo "${GREEN}Installing NodeJs...${RESET}"

	wget https://deb.nodesource.com/setup_6.x -O /tmp/node_install.sh
	chmod 700 /tmp/node_install.sh
	/tmp/node_install.sh
	unlink /tmp/node_install.sh

	apt-get update > /dev/null || exit 1
	apt-get install -y nodejs > /dev/null || exit 1
}

##
# Globally install composer.
##
function installComposer {
	echo "${GREEN}Installing composer...${RESET}"
	php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" > /dev/null || exit 1
	php composer-setup.php --install-dir=/usr/local/bin/ --filename=composer > /dev/null || exit 1
	php -r "unlink('composer-setup.php');" > /dev/null || exit 1
}

##
# Install drush
##
function installDrush {
	echo "${GREEN}Installing drush...${RESET}"
	git clone https://github.com/drush-ops/drush.git /opt/drush > /dev/null || exit 1
	cd /opt/drush > /dev/null || exit 1
	git checkout 8.1.15 > /dev/null || exit 1
	composer install > /dev/null || exit 1

	ln -s /opt/drush/drush /usr/local/bin
}

##
# Install elastic search.
##
function installEleasticSearch {
	echo "${GREEN}Installing java...${RESET}"
	apt-get install openjdk-7-jre -y > /dev/null || exit 1

	echo "${GREEN}Installing elasticsearch...${RESET}"
	cd /tmp
	wget https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-1.7.1.deb > /dev/null || exit 1
	dpkg -i elasticsearch-1.7.1.deb > /dev/null || exit 1
	unlink elasticsearch-1.7.1.deb
	update-rc.d elasticsearch defaults 95 10 > /dev/null || exit 1

	# Elasticsearch plugins
	/usr/share/elasticsearch/bin/plugin -install elasticsearch/elasticsearch-analysis-icu/2.5.0 > /dev/null || exit 1

	service elasticsearch restart
}

##
# Install supervisor.
#
# Used to automatically run nodejs applications.
##
function installSuperVisor {
	echo "${GREEN}Installing supervisor...${RESET}"
	apt-get install supervisor -y > /dev/null || exit 1
}

##
# Install tools need and that is nice to have on the server.
##
function installUtils {
	echo "${GREEN}Installing utils...${RESET}"
	apt-get install git bash-completion sudo nmap mc imagemagick git-core lynx rcconf build-essential automake autoconf pwgen jq curl wget sudo apt-utils -y > /dev/null || exit 1
}

updateSystem;
installUtils;
intallMySQL;
installApache;
installPHP;
installCaches;
installNodeJs;
installComposer;
installDrush;
installEleasticSearch;
installSuperVisor;
