#!/usr/bin/env bash

#set -o errexit
#set -o pipefail
#set -o nounset
#set -o xtrace
#set -ex

# By storing the date now, we can calculate the duration of provisioning at the
# end of this script.

start_seconds="$(date +%s)"

# Updates the packages, upgrades the packages, removes unused packages, then removes old versions of packages.

apt-get --assume-yes update && apt-get upgrade -y && apt-get autoremove && apt-get autoclean

# PACKAGE INSTALLATION
#
# Build a bash array to pass all of the packages we want to install to a single
# apt-get command. This avoids doing all the leg work each time a package is
# set to install. It also allows us to easily comment out or add single
# packages. We set the array as empty to begin with so that we can append
# individual packages to it as required.
apt_package_install_list=()

# Start with a bash array containing all packages we want to install in the
# virtual machine. We'll then loop through each of these and check individual
# status before adding them to the apt_package_install_list array.
apt_package_check_list=(

  build-essential
  unattended-upgrades

  # PHP5
  #
  # Our base packages for php5. As long as php5-fpm and php5-cli are
  # installed, there is no need to install the general php5 package, which
  # can sometimes install apache as a requirement.
  php5-fpm
  php5-cli

  # Common and dev packages for php
  php5-common
  php5-dev

  # Extra PHP modules that we find useful
  php5-memcache
  php5-imagick
  php5-mcrypt
  php5-mysql
  php5-pspell
  php-apc
  php5-tidy
  php5-imap
  php5-curl
  php-pear
  php5-gd

  # nginx is installed as the default web server
  nginx

  # memcached is made available for object caching
  memcached

  # mysql is the default database
  mysql-server

  # other packages that come in handy
  imagemagick
  git-core
  zip
  unzip
  ngrep
  curl
  make
  vim
  colordiff
  postfix
  bundler
  mutt
  logwatch
  s3cmd 
  mysqltuner
  apache2-utils
  apache2
  redis-server 
  php5-redis

  # ntp service to keep clock current
  ntp

  # Req'd for i18n tools
  gettext

  # Req'd for Webgrind
  graphviz

  # dos2unix
  # Allows conversion of DOS style line endings to something we'll have less
  # trouble with in Linux.
  dos2unix

  # nodejs for use by grunt
  g++
  nodejs

  #Mailcatcher requirement
  libsqlite3-dev
  #Logwatch requirement
  libdate-manip-perl

  #Networking
  tmux 
  multitail 
  mailutils 
  nmap
  tree
  mc
  fish

  #Security
  apparmor 
  apparmor-profiles
  rkhunter 
  chkrootkit 
  tiger 
  aide
  fail2ban
)


inform_about_disk_space() {

MAX=20
EMAIL=donatas.stirbys@hotmail.com
PART=vda1

USE=`df -h |grep $PART | awk '{ print $5 }' | cut -d'%' -f1`
if [ $USE -gt $MAX ]; then
  echo "Percent used: $USE" | mail -s "Running out of disk space" $EMAIL
fi

}

make_swap() {
#enable swap
echo 'Making swap'
OUTPUT=$(grep MemTotal /proc/meminfo | awk '{print $2}')

if [ "$OUTPUT"  -gt "100000" ] &&  [[ $(free | awk '/^Swap:/ {print $2}') -eq "0"  ]] ; then
        sudo fallocate -l 1G /swapfile
        ls -lh /swapfile
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
        sudo swapon /swapfile
        sudo swapon -s
        echo "Swap was created"
        else
        echo -e "\nSwap already exists"
 fi
}

add_deployer_user() {

  # exporting some variables
    export ADMIN_MAIL=donatas.stirbys@hotmail.com
    export GMAIL_MAIL=donatas.stirbys@gmail.com
    export HOME=/home/deployer
    export DEBIAN_FRONTEND=noninteractive
	# Add new user
    if ! grep -c '^deployer:' /etc/passwd > /dev/null; then
      password="deployer"
      pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
      groupadd deployer
      useradd -g deployer -m deployer -p "$pass" 
	    mkdir /home/deployer/.ssh
      chmod 700 /home/deployer/.ssh
      echo 'deployer  ALL=(ALL:ALL) ALL' >> /etc/sudoers
      echo "User has been added to system!"
  	  sudo groupadd admin
  	  sudo usermod -a -G admin deployer
      chown deployer:deployer /home/deployer -R
    else
    echo -e "\nDeployment user is already created"
   fi
}

add_aliases() {
echo "Adding aliases in process"

if [[ -f  /home/deployer/.bashrc ]]; then
echo "Started adding aliases"
echo "alias nanok='nano -c'" >> /home/deployer/.bashrc
echo "alias ls='ls -F --color=always'" >> /home/deployer/.bashrc
echo "alias dir='dir -F --color=always'" >> /home/deployer/.bashrc
echo "alias cp='cp -iv'" >> /home/deployer/.bashrc
echo "alias rm='rm -i'" >> /home/deployer/.bashrc
echo "alias mv='mv -iv'" >> /home/deployer/.bashrc
echo "alias grep='grep --color=auto -i'" >> /home/deployer/.bashrc
echo "alias v='vim'" >> /home/deployer/.bashrc
echo "alias md='mkdir'" >> /home/deployer/.bashrc
echo "alias rd='rmdir'" >> /home/deployer/.bashrc
echo "alias la='ls -a'" >> /home/deployer/.bashrc
echo "alias ll='ls -l'" >> /home/deployer/.bashrc
echo "alias cu='composer update'" >> /home/deployer/.bashrc
echo "alias cda='composer dump-autoload -o'" >> /home/deployer/.bashrc
echo "alias port='netstat -tulanp'" >> /home/deployer/.bashrc
echo "alias findphp='find . -type f -name "*.php"'" >> /home/deployer/.bashrc
echo "alias findjson='find . -type f -name "*.json"'" >> /home/deployer/.bashrc
echo "alias check='find . -type f -name "*.php" -exec php -l {} \;'" >> /home/deployer/.bashrc
echo "alias ..='cd ..'" >> /home/deployer/.bashrc
echo "alias chmod_files='find -maxdepth 10 -type f -exec chmod 644 {} \;'" >> /home/deployer/.bashrc
echo "alias chmod_folders='find -maxdepth 10 -type d -exec chmod 755 {} \;'" >> /home/deployer/.bashrc
echo "alias apache_error='sudo tail -f  /var/log/apache2/error.log'" >> /home/deployer/.bashrc
echo "alias updg='sudo apt-get update && sudo apt-get upgrade'" >> /home/deployer/.bashrc
echo "alias ax='chmod a+x'" >> /home/deployer/.bashrc
echo "alias src='source ~/.bash_profile'" >> /home/deployer/.bashrc
echo "alias ..='cd ..'" >> /home/deployer/.bashrc
echo "alias ...='cd ../../../'" >> /home/deployer/.bashrc
echo "alias ....='cd ../../../../'" >> /home/deployer/.bashrc
echo "alias .....='cd ../../../../'" >> /home/deployer/.bashrc
echo "alias myip='curl -s 'http://checkip.dyndns.org' | sed 's/.*Current IP Address: \([0-9\.\.]*\).*/\1/g'" >> /home/deployer/.bashrc

echo "Adding aliases done!"
source /home/deployer/.bashrc
  else
    echo "No bashrc"
  fi
}

network_detection() {
  # Network Detection
  #
  # Make an HTTP request to google.com to determine if outside access is available
  # to us. If 3 attempts with a timeout of 5 seconds are not successful, then we'll
  # skip a few things further in provisioning rather than create a bunch of errors.
  if [[ "$(wget --tries=3 --timeout=5 --spider http://google.com 2>&1 | grep 'connected')" ]]; then
    echo "Network connection detected..."
    ping_result="Connected"
  else
    echo "Network connection not detected. Unable to reach google.com..."
    ping_result="Not Connected"
  fi
}

network_check() {
  network_detection
  if [[ ! "$ping_result" == "Connected" ]]; then
    echo -e "\nNo network connection available, skipping package installation"
    exit 0
  fi
}



package_check() {
  # Loop through each of our packages that should be installed on the system. If
  # not yet installed, it should be added to the array of packages to install.
  local pkg
  local package_version

  for pkg in "${apt_package_check_list[@]}"; do
    package_version=$(dpkg -s "${pkg}" 2>&1 | grep 'Version:' | cut -d " " -f 2)
    if [[ -n "${package_version}" ]]; then
      space_count="$(expr 20 - "${#pkg}")" #11
      pack_space_count="$(expr 30 - "${#package_version}")"
      real_space="$(expr ${space_count} + ${pack_space_count} + ${#package_version})"
      printf " * $pkg %${real_space}.${#package_version}s ${package_version}\n"
    else
      echo " *" $pkg [not installed]
      apt_package_install_list+=($pkg)
    fi
  done
}

package_install() {
  package_check

  # MySQL
  #
  # Use debconf-set-selections to specify the default password for the root MySQL
  # account. This runs on every provision, even if MySQL has been installed. If
  # MySQL is already installed, it will not affect anything.
  echo mysql-server mysql-server/root_password password "root" | debconf-set-selections
  echo mysql-server mysql-server/root_password_again password "root" | debconf-set-selections

  # Postfix
  #
  # Use debconf-set-selections to specify the selections in the postfix setup. Set
  # up as an 'Internet Site' with the host name 'vvv'. Note that if your current
  # Internet connection does not allow communication over port 25, you will not be
  # able to send mail, even with postfix installed.
  echo postfix postfix/main_mailer_type select Internet Site | debconf-set-selections
  echo postfix postfix/mailname string vvv | debconf-set-selections

  #Install mysql tuning tool

  cd /usr/local/bin
  wget https://launchpadlibrarian.net/78745738/tuning-primer.sh
  chmod u+x tuning-primer.sh
  tuning-primer.sh

  # Disable ipv6 as some ISPs/mail servers have problems with it
  echo "inet_protocols = ipv4" >> "/etc/postfix/main.cf"

  if [[ ${#apt_package_install_list[@]} = 0 ]]; then
    echo -e "No apt packages to install.\n"
  else
    # Before running `apt-get update`, we should add the public keys for
    # the packages that we are installing from non standard sources via
    # our appended apt source.list

    # Retrieve the Nginx signing key from nginx.org
    echo "Applying Nginx signing key..."
    wget --quiet "http://nginx.org/keys/nginx_signing.key" -O- | apt-key add -

    # Apply the nodejs assigning key
    apt-key adv --quiet --keyserver "hkp://keyserver.ubuntu.com:80" --recv-key C7917B12 2>&1 | grep "gpg:"
    apt-key export C7917B12 | apt-key add -

    # Update all of the package references before installing anything
    echo "Running apt-get update..."
    apt-get update -y

    # Install required packages
    echo "Installing apt-get packages..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -q -y ${apt_package_install_list[@]}

    # Clean up apt caches
    apt-get clean
  fi
}

tools_install() {
  # npm
  #
  # Make sure we have the latest npm version and the update checker module

  curl -o /home/deployer/nvm.sh https://raw.githubusercontent.com/creationix/nvm/v0.11.1/install.sh | bash
  cd /home/deployer 
  chmod +x nvm.sh
  ./nvm.sh
  # echo "[[ -s $HOME/.nvm/nvm.sh ]] && . $HOME/.nvm/nvm.sh" >> /home/deployer/.profile
  source /home/deployer/.profile
  # source ~/.nvm/nvm.sh
  nvm install v0.12.9
  nvm use v0.12.9
  nvm alias default v0.12.9

  curl -L https://npmjs.org/install.sh | sh
  npm install -g npm-check-updates

  # xdebug
  #
  # XDebug 2.2.3 is provided with the Ubuntu install by default. The PECL
  # installation allows us to use a later version. Not specifying a version
  # will load the latest stable.
  pecl install xdebug

  # ack-grep
  #
  # Install ack-rep directory from the version hosted at beyondgrep.com as the
  # PPAs for Ubuntu Precise are not available yet.
  if [[ -f /usr/bin/ack ]]; then
    echo "ack-grep already installed"
  else
    echo "Installing ack-grep as ack"
    curl -s http://beyondgrep.com/ack-2.14-single-file > "/usr/bin/ack" && chmod +x "/usr/bin/ack"
  fi

  # COMPOSER
  #
  # Install Composer if it is not yet available.
  if [[ ! -n "$(composer --version --no-ansi | grep 'Composer version')" ]]; then
    echo "Installing Composer..."
    curl -sS "https://getcomposer.org/installer" | php
    chmod +x "composer.phar"
    mv "composer.phar" "/usr/local/bin/composer"

    echo "Moving Github token"
    sudo mkdir -p /home/deployer/.composer/   
    sudo mkdir -p /root/.config/composer
    sudo cp auth.json /home/deployer/.composer/
    sudo cp auth.json /root/.config/composer
  fi

	# Set up git

	git config --global user.name "Donatas Stirbys"
	git config --global user.email $ADMIN_MAIL


  # Grunt
  #
  # Install or Update Grunt based on current state.  Updates are direct
  # from NPM
  if [[ "$(grunt --version)" ]]; then
    echo "Updating Grunt CLI"
    npm update -g grunt-cli &>/dev/null
    npm update -g grunt-sass &>/dev/null
    npm update -g grunt-cssjanus &>/dev/null
    npm update -g grunt-rtlcss &>/dev/null
  else
    echo "Installing Grunt CLI"
    npm install -g grunt-cli &>/dev/null
    npm install -g grunt-sass &>/dev/null
    npm install -g grunt-cssjanus &>/dev/null
    npm install -g grunt-rtlcss &>/dev/null
  fi

  # Graphviz
  #
  # Set up a symlink between the Graphviz path defined in the default Webgrind
  # config and actual path.
  echo "Adding graphviz symlink for Webgrind..."
  ln -sf "/usr/bin/dot" "/usr/local/bin/dot"
}

nginx_setup() {
  # Create an SSL key and certificate for HTTPS support.

  echo -e "\nSetup configuration files..."

  # Copy nginx configuration from local
  sudo cp -f "/srv/config/nginx-config/nginx.conf" "/etc/nginx/nginx.conf"
  sudo cp -f "/srv/config/nginx-config/nginx-wp-common.conf" "/etc/nginx/nginx-wp-common.conf"
  sudo cp -f "/srv/config/nginx-config/sites/default" "/etc/nginx/conf.d/default.conf"

  echo " * Copied /srv/config/nginx-config/nginx.conf to /etc/nginx/nginx.conf"
  echo " * Copied /srv/config/nginx-config/nginx-wp-common.conf to /etc/nginx/nginx-wp-common.conf"
  echo " * Copied /srv/config/nginx-config/sites/default.conf to /etc/nginx/conf.d/default.conf"
}

phpfpm_setup() {
  # Copy php-fpm configuration from local
  sudo cp -f "/srv/config/php5-fpm-config/php5-fpm.conf" "/etc/php5/fpm/php5-fpm.conf"
  sudo cp -f "/srv/config/php5-fpm-config/www.conf" "/etc/php5/fpm/pool.d/www.conf"
  sudo cp -f "/srv/config/php5-fpm-config/php-custom.ini" "/etc/php5/fpm/conf.d/php-custom.ini"
  sudo cp -f "/srv/config/php5-fpm-config/opcache.ini" "/etc/php5/fpm/conf.d/opcache.ini"
  sudo cp -f "/srv/config/php5-fpm-config/xdebug.ini" "/etc/php5/mods-available/xdebug.ini"

  # Find the path to Xdebug and prepend it to xdebug.ini
  XDEBUG_PATH=$( find /usr -name 'xdebug.so' | head -1 )
  sed -i "1izend_extension=\"$XDEBUG_PATH\"" "/etc/php5/mods-available/xdebug.ini"

  echo " * Copied /srv/config/php5-fpm-config/php5-fpm.conf     to /etc/php5/fpm/php5-fpm.conf"
  echo " * Copied /srv/config/php5-fpm-config/www.conf          to /etc/php5/fpm/pool.d/www.conf"
  echo " * Copied /srv/config/php5-fpm-config/php-custom.ini    to /etc/php5/fpm/conf.d/php-custom.ini"
  echo " * Copied /srv/config/php5-fpm-config/opcache.ini       to /etc/php5/fpm/conf.d/opcache.ini"
  echo " * Copied /srv/config/php5-fpm-config/xdebug.ini        to /etc/php5/mods-available/xdebug.ini"

  # Copy memcached configuration from local
  cp "/srv/config/memcached-config/memcached.conf" "/etc/memcached.conf"

  echo " * Copied /config/memcached-config/memcached.conf   to /etc/memcached.conf"
}

modify_php() {

if [[ -d "/etc/php5/fpm/" ]]; then
  cd /etc/php5/fpm
  sed -i -e 's/;opcache.enable=0/opcache.enable=1/g' php.ini
  sed -i -e 's/;opcache.memory_consumption=64/opcache.memory_consumption=128/g' php.ini
  sed -i -e 's/max_execution_time = 30/max_execution_time = 300/g' php.ini
  sed -i -e 's/;opcache.max_accelerated_files=2000/opcache.max_accelerated_files=4000/g' php.ini
  sed -i -e 's/;opcache_revalidate_freq = 2/opcache_revalidate_freq = 240/g' php.ini
  sed -i -e 's/disable_functions = pcntl_alarm,pcntl_fork,pcntl_waitpid,pcntl_wait,pcntl_wifexited,pcntl_wifstopped,pcntl_wifsignaled,pcntl_wexitstatus,pcntl_wtermsig,pcntl_wstopsig,pcntl_signal,pcntl_signal_dispatch,pcntl_get_last_error,pcntl_strerror,pcntl_sigprocmask,pcntl_sigwaitinfo,pcntl_sigtimedwait,pcntl_exec,pcntl_getpriority,pcntl_setpriority,/disable_functions = pcntl_alarm,pcntl_fork,pcntl_waitpid,pcntl_wait,pcntl_wifexited,pcntl_wifstopped,pcntl_wifsignaled,pcntl_wexitstatus,pcntl_wtermsig,pcntl_wstopsig,pcntl_signal,pcntl_signal_dispatch,pcntl_get_last_error,pcntl_strerror,pcntl_sigprocmask,pcntl_sigwaitinfo,pcntl_sigtimedwait,pcntl_exec,pcntl_getpriority,pcntl_setpriority,exec,system,shell_exec,passthru,/g' php.ini
  sed -i -e 's/html_errors = On/html_errors = Off/g' php.ini
  sed -i -e 's/;always_populate_raw_post_data = -1/always_populate_raw_post_data=-1/g' php.ini #this is needed for piwik, but is it not deprecated?
  sudo echo "register_globals = Off" >> php.ini
  sudo echo "magic_quotes_gpc = Off" >> php.ini
  sudo php5enmod opcache
else
    echo -e "\nPHP is already configured"
fi
}

mysql_setup() {
  # If MySQL is installed, go through the various imports and service tasks.
  local exists_mysql

  exists_mysql="$(service mysql status)"
  if [[ "mysql: unrecognized service" != "${exists_mysql}" ]]; then
    echo -e "\nSetup MySQL configuration file links..."

    # Copy mysql configuration from local
    cp "/srv/config/mysql-config/my.cnf" "/etc/mysql/my.cnf"
    echo " * Copied /srv/config/mysql-config/my.cnf to /etc/mysql/my.cnf"

    # Setup MySQL by importing an init file
    # mysql -u "root" -p < "/config/database/init.sql"

    mysql -u "root" -proot -Bse "DELETE FROM mysql.user WHERE User='';CREATE USER happybits@'localhost' IDENTIFIED BY 'culturevulture';GRANT GRANT OPTION ON *.* TO happybits@'%';GRANT GRANT OPTION ON *.* TO happybits@'localhost';GRANT ALL PRIVILEGES ON * . * TO happybits@'localhost';CREATE SCHEMA ninja DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;GRANT ALL PRIVILEGES ON happybits.* TO ninja@'localhost';FLUSH PRIVILEGES;CREATE DATABASE IF NOT EXISTS piwik;GRANT ALL PRIVILEGES ON piwik.* TO happybits@'localhost' IDENTIFIED BY 'culturevulture';"

    service mysql restart

    #You can enable slow-log by un-commenting following lines in /etc/mysql/my.cnf

    #slow-query-log = 1
    #slow-query-log-file = /var/log/mysql/mysql-slow.log
    #long_query_time = 1
    #log-queries-not-using-indexes
   
  else
    echo -e "\nMySQL is not installed. No databases imported."
  fi
}


memcached_admin() {
  # Download and extract phpMemcachedAdmin to provide a dashboard view and
  # admin interface to the goings on of memcached when running
  if [[ ! -d "/srv/www/default/" ]] && [[ ! -d "/srv/www/default/memcached-admin" ]]; then
    echo -e "\nDownloading phpMemcachedAdmin, see https://github.com/wp-cloud/phpmemcacheadmin"
    mkdir /srv/www/default
    cd /srv/www/default
    wget -q -O phpmemcachedadmin.tar.gz "https://github.com/wp-cloud/phpmemcacheadmin/archive/1.2.2.1.tar.gz"
    tar -xf phpmemcachedadmin.tar.gz
    mv phpmemcacheadmin* memcached-admin
    rm phpmemcachedadmin.tar.gz
  else
    echo "phpMemcachedAdmin already installed."
  fi
}

opcached_status(){
  # Checkout Opcache Status to provide a dashboard for viewing statistics
  # about PHP's built in opcache.
  if [[ ! -d "/srv/www/default/opcache-status" ]]; then
    echo -e "\nDownloading Opcache Status, see https://github.com/rlerdorf/opcache-status/"
    cd /srv/www/default
    git clone "https://github.com/rlerdorf/opcache-status.git" opcache-status
  else
    echo -e "\nUpdating Opcache Status"
    cd /srv/www/default/opcache-status
    git pull --rebase origin master
  fi
}

webgrind_install() {
  # Webgrind install (for viewing callgrind/cachegrind files produced by
  # xdebug profiler)
  if [[ ! -d "/srv/www/default/webgrind" ]]; then
    echo -e "\nDownloading webgrind, see https://github.com/michaelschiller/webgrind.git"
    git clone "https://github.com/michaelschiller/webgrind.git" "/srv/www/default/webgrind"
  else
    echo -e "\nUpdating webgrind..."
    cd /srv/www/default/webgrind
    git pull --rebase origin master
  fi
}


wp_cli() {
  # WP-CLI Install
  if [[ ! -d "/srv/www/wp-cli" ]]; then
    echo -e "\nDownloading wp-cli, see http://wp-cli.org"
    git clone "https://github.com/wp-cli/wp-cli.git" "/srv/www/wp-cli"
    cd /srv/www/wp-cli
    composer install
  else
    echo -e "\nUpdating wp-cli..."
    cd /srv/www/wp-cli
    git pull --rebase origin master
    composer update
  fi
  # Link `wp` to the `/usr/local/bin` directory
  ln -sf "/srv/www/wp-cli/bin/wp" "/usr/local/bin/wp"
}


php_codesniff() {
  # PHP_CodeSniffer (for running WordPress-Coding-Standards)
  if [[ ! -d "/srv/www/phpcs" ]]; then
    echo -e "\nDownloading PHP_CodeSniffer (phpcs), see https://github.com/squizlabs/PHP_CodeSniffer"
    git clone -b master "https://github.com/squizlabs/PHP_CodeSniffer.git" "/srv/www/phpcs"
  else
    cd /srv/www/phpcs
    if [[ $(git rev-parse --abbrev-ref HEAD) == 'master' ]]; then
      echo -e "\nUpdating PHP_CodeSniffer (phpcs)..."
      git pull --no-edit origin master
    else
      echo -e "\nSkipped updating PHP_CodeSniffer since not on master branch"
    fi
  fi

  # Sniffs WordPress Coding Standards
  if [[ ! -d "/srv/www/phpcs/CodeSniffer/Standards/WordPress" ]]; then
    echo -e "\nDownloading WordPress-Coding-Standards, sniffs for PHP_CodeSniffer, see https://github.com/WordPress-Coding-Standards/WordPress-Coding-Standards"
    git clone -b master "https://github.com/WordPress-Coding-Standards/WordPress-Coding-Standards.git" "/srv/www/phpcs/CodeSniffer/Standards/WordPress"
  else
    cd /srv/www/phpcs/CodeSniffer/Standards/WordPress
    if [[ $(git rev-parse --abbrev-ref HEAD) == 'master' ]]; then
      echo -e "\nUpdating PHP_CodeSniffer WordPress Coding Standards..."
      git pull --no-edit origin master
    else
      echo -e "\nSkipped updating PHPCS WordPress Coding Standards since not on master branch"
    fi
  fi

  # Install the standards in PHPCS
  /www/phpcs/scripts/phpcs --config-set installed_paths ./CodeSniffer/Standards/WordPress/
  /www/phpcs/scripts/phpcs --config-set default_standard WordPress-Core
  /www/phpcs/scripts/phpcs -i
}


services_restart() {
  # RESTART SERVICES
  # Make sure the services we expect to be running are running.
  echo -e "\nRestart services..."
  service nginx restart
  service memcached restart

  # Disable PHP Xdebug module by default
  php5dismod xdebug

  # Enable PHP mcrypt module by default
  php5enmod mcrypt

  service php5-fpm restart

  # Add the deployer user to the www-data group so that it has better access
  # to PHP and Nginx related files.
  usermod -a -G www-data deployer
}

add_security() {

# prevent IP spoofing

if [ -f /etc/host.conf ]; then
    cd /etc/
    echo 'nospoof on' >> host.conf
fi

# add these to cron to run weekly

	echo "0 0 * * 0 root sudo rkhunter --update --propupd --check" >> /etc/crontab
	echo "0 0 * * 0 root sudo chkrootkit" >> /etc/crontab
	echo "0 0 * * 0 root sudo tiger" >> /etc/crontab

  sed -i -e 's/#MAIL-ON-WARNING=root/MAIL-ON-WARNING=donatas.stirbys@adform.com/g' /etc/rkhunter.conf
  sed -i -e 's/#MAIL_CMD=mail -s "[rkhunter] Warnings found for ${HOST_NAME}"/ MAIL_CMD=mail -s "[rkhunter] Warnings found for ${HOST_NAME}/g' /etc/rkhunter.conf


#Disable telnet

  if [[ -d "/etc/xinetd.d" ]]; then
  	echo -e "\nDisabling telnet"
  	cd /etc/xinetd.d
  	sed -i -e 's/disable = no/disable = yes/g' telnet
  	/etc/init.d/xinetd restart
  else
    echo -e "\nNo telnet client"
  fi

  #Disable Open DNS Recursion and Remove Version Info  - BIND DNS Server.

  if [[ -d "/etc/bind" ]]; then
  	echo -e "\nDisabling bind"
  	cd /etc/bind
  	echo "recursion no;" >> named.conf.options
  	echo "version 'Not Disclosed';" >> named.conf.options
  	sudo /etc/init.d/bind9 restart
  else
    echo -e "\nNo bind client"
  fi

  #Work on Sysctl
  echo "Working on Sysctl parameters"

    # IP Spoofing protection
    cd /etc
    sed -i -e 's/#net.ipv4.conf.all.rp_filter = 1/net.ipv4.conf.all.rp_filter = 1/g' sysctl.conf
    sed -i -e 's/#net.ipv4.conf.default.rp_filter = 1/net.ipv4.conf.default.rp_filter = 1/g' sysctl.conf

    # Ignore ICMP broadcast requests
    sudo echo "net.ipv4.icmp_echo_ignore_broadcasts = 1" >> sysctl.conf

    # Disable source packet routing

    sed -i -e 's/#net.ipv4.conf.all.accept_source_route = 0/net.ipv4.conf.all.accept_source_route = 0/g' sysctl.conf
    sed -i -e 's/#net.ipv6.conf.all.accept_source_route = 0/net.ipv6.conf.all.accept_source_route = 0/g' sysctl.conf
    sudo echo "net.ipv4.conf.default.accept_source_route = 0" >> sysctl.conf
    sudo echo "net.ipv6.conf.default.accept_source_route = 0" >> sysctl.conf

    # Ignore send redirects
  
    sed -i -e 's/#net.ipv4.conf.all.send_redirects = 0/net.ipv4.conf.all.send_redirects = 0/g' sysctl.conf

    # Block SYN attacks

    sed -i -e 's/#net.ipv4.tcp_syncookies = 1/net.ipv4.tcp_syncookies = 1/g' sysctl.conf
    sudo echo "net.ipv4.tcp_max_syn_backlog = 2048" >> sysctl.conf
    sudo echo "net.ipv4.tcp_synack_retries = 2" >> sysctl.conf
    sudo echo "net.ipv4.tcp_syn_retries = 5" >> sysctl.conf

    # Log Martians

    sed -i -e 's/#net.ipv4.conf.all.log_martians = 1/net.ipv4.conf.all.log_martians = 1/g' sysctl.conf

    # Ignore ICMP redirects
    sed -i -e 's/#net.ipv4.conf.all.accept_redirects = 0/net.ipv4.conf.all.accept_redirects = 0/g' sysctl.conf
    sed -i -e 's/#net.ipv6.conf.all.accept_redirects = 0/net.ipv6.conf.all.accept_redirects = 0/g' sysctl.conf
    
    # Reload sysctl
    sudo sysctl -p 

    echo "Done amending sysctl"

    # Not sute if this works, but should be against Brute Force
    echo "Installing BFD"
    cd /home/deployer
    wget http://www.rfxnetworks.com/downloads/bfd-current.tar.gz
    tar -xvzf bfd-current.tar.gz
    cd bfd*
    ./install.sh
    sed -i -e 's/EMAIL_ALERTS="0"/EMAIL_ALERTS="1"/g' /usr/local/bfd/conf.bfd
    sed -i -e 's/EMAIL_ADDRESS="root"/EMAIL_ADDRESS="donatas.stirbys@hotmail.com"/g' /usr/local/bfd/conf.bfd
    /usr/local/sbin/bfd –s
    echo "BFD installed"
}


install_ninja() {
 if [[ ! -d " /srv/www/ninja/" ]]; then
 	echo "Downloading Invoice Ninja"
 	cd /srv/www
 	git clone https://donatas_stirbys:Gembird20@bitbucket.org/donatas_stirbys/invoiceninja.git ninja
  cd /srv/www/ninja
  composer install
  sudo chown -R www-data:www-data storage public
  sudo chmod -R 777 storage
  mv .env.example .env
  sudo chmod -R 777 .env
  sed -i -e 's/DB_USERNAME/DB_USERNAME=ninja/g' .env
  sed -i -e 's/DB_PASSWORD/DB_PASSWORD=culturevulture/g' .env
  sed -i -e 's/APP_DEBUG=false/APP_DEBUG=true/g' .env
  npm install

  touch /var/log/nginx/finance-error.log
 fi
}

install_piwik() {
   cd /srv/www
   wget http://builds.piwik.org/latest.zip
   unzip latest.zip
   rm *html *zip
   chown -R www-data:www-data /srv/www/piwik
   touch /var/log/nginx/piwik-error.log
}     


setup_digital_ocean_api() {
  cd /srv/www/home/public
  git clone https://donatas_stirbys:Gembird20@bitbucket.org/donatas_stirbys/digitalocean.git digital
  cd digital
  composer install
}

setup_email_templating() {
  cd /srv/www/home/public
  git clone https://donatas_stirbys:Gembird20@bitbucket.org/donatas_stirbys/emailing.git emailing
  cd emailing
  composer install
}

setup_encrypter() {
  cd /srv/www/home/public
  git clone https://donatas_stirbys:Gembird20@bitbucket.org/donatas_stirbys/encrypter.git encrypter
}

get_set_remove() {

   echo "Working on passwords file"
   touch /home/deployer/.env
   sudo chown -R www-data:www-data /home/deployer/.env
   curl -L --data "service=dbuser" --data "pass=happybits" -L http://www.happybits.lt/encrypter/encrypter.php
   curl -L --data "service=dbpass" --data "pass=culturevulture" -L http://www.happybits.lt/encrypter/encrypter.php
   curl -L --data "service=amazonkey" --data "pass=AKIAIWDGW3GY2TZ7PVYA" -L http://www.happybits.lt/encrypter/encrypter.php
   curl -L --data "service=amazonsecretkey" --data "pass=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" -L http://www.happybits.lt/encrypter/encrypter.php
   curl -L --data "service=bucket" --data "pass=s3://hpbuckets/" -L http://www.happybits.lt/encrypter/encrypter.php
   curl -L --data "service=digital" --data "pass=c16b819188bdf63929413ca1b5c15e78e192f7b15d9d96be0302957bfa3902a2" -L http://www.happybits.lt/encrypter/encrypter.php
   curl -L --data "service=ninja" --data "pass=uoE7U99dulciJjsSYWZ1LByQ4dph5fZ1" -L http://www.happybits.lt/encrypter/encrypter.php
   curl -L --data "service=gmail" --data "pass=Gembird20" -L http://www.happybits.lt/encrypter/encrypter.php
  echo "Setting timezone"
  sudo timedatectl set-timezone Europe/Vilnius
}


# vagrant related

mailcatcher_setup() {
  # Mailcatcher
  #
  # Installs mailcatcher using RVM. RVM allows us to install the
  # current version of ruby and all mailcatcher dependencies reliably.
  local pkg

  rvm_version="$(/usr/bin/env rvm --silent --version 2>&1 | grep 'rvm ' | cut -d " " -f 2)"
  if [[ -n "${rvm_version}" ]]; then
    pkg="RVM"
    space_count="$(( 20 - ${#pkg}))" #11
    pack_space_count="$(( 30 - ${#rvm_version}))"
    real_space="$(( ${space_count} + ${pack_space_count} + ${#rvm_version}))"
    printf " * $pkg %${real_space}.${#rvm_version}s ${rvm_version}\n"
  else
    # RVM key D39DC0E3
    # Signatures introduced in 1.26.0
    gpg -q --no-tty --batch --keyserver "hkp://keyserver.ubuntu.com:80" --recv-keys D39DC0E3
    gpg -q --no-tty --batch --keyserver "hkp://keyserver.ubuntu.com:80" --recv-keys BF04FF17

    printf " * RVM [not installed]\n Installing from source"
    curl --silent -L "https://get.rvm.io" | sudo bash -s stable --ruby
    source "/usr/local/rvm/scripts/rvm"
  fi

  mailcatcher_version="$(/usr/bin/env mailcatcher --version 2>&1 | grep 'mailcatcher ' | cut -d " " -f 2)"
  if [[ -n "${mailcatcher_version}" ]]; then
    pkg="Mailcatcher"
    space_count="$(( 20 - ${#pkg}))" #11
    pack_space_count="$(( 30 - ${#mailcatcher_version}))"
    real_space="$(( ${space_count} + ${pack_space_count} + ${#mailcatcher_version}))"
    printf " * $pkg %${real_space}.${#mailcatcher_version}s ${mailcatcher_version}\n"
  else
    echo " * Mailcatcher [not installed]"
    /usr/bin/env rvm default@mailcatcher --create do gem install mailcatcher --no-rdoc --no-ri
    /usr/bin/env rvm wrapper default@mailcatcher --no-prefix mailcatcher catchmail
  fi

  if [[ -f "/etc/init/mailcatcher.conf" ]]; then
    echo " *" Mailcatcher upstart already configured.
  else
    cp "/srv/config/init/mailcatcher.conf"  "/etc/init/mailcatcher.conf"
    echo " * Copied /srv/config/init/mailcatcher.conf    to /etc/init/mailcatcher.conf"
  fi

  if [[ -f "/etc/php5/mods-available/mailcatcher.ini" ]]; then
    echo " *" Mailcatcher php5 fpm already configured.
  else
    cp "/srv/config/php5-fpm-config/mailcatcher.ini" "/etc/php5/mods-available/mailcatcher.ini"
    echo " * Copied /srv/config/php5-fpm-config/mailcatcher.ini    to /etc/php5/mods-available/mailcatcher.ini"
  fi
}


capistrano_install() {
    echo -e "\nDownloading capistrano and it's plugins"
    sudo gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
    curl -L get.rvm.io | bash -s stable
    source /etc/profile.d/rvm.sh
    rvm reload
    rvm install 2.1.0
    ruby --version 
    gem install capistrano
    gem install railsless-deploy
    gem install capistrano-ext
    gem install capistrano-slackify
}


wpdeploy_install() {
   # Install and configure the latest stable version of WordPress
  if [[ ! -d "/srv/www/wpdeloy" ]]; then
   cd /srv/www/
   echo "Installing wp deploy"
   git clone "https://github.com/weareoboy/wp-deploy.git" wpdeploy
   cd /srv/www/deploy
   bundle install
  else
    echo "WP Deploy is already installed"
  fi
}


### SCRIPT

network_check

# Profile_setup

make_swap

echo "Bash profile setup and directories."

add_deployer_user
add_aliases

network_check

echo " "
echo "Main packages check and install."

package_install
tools_install
nginx_setup
phpfpm_setup
modify_php
services_restart
mysql_setup

network_check

echo " "
echo "Install some tools."

memcached_admin
opcached_status
webgrind_install
wp_cli
php_codesniff

# We think about security
echo " "
echo "Adding some security precautions"

add_security

# Install Invoice Ninja

echo " "
echo "Installing/updating Invoice Ninja"

install_ninja
install_piwik

echo " "
echo "Performing further configuration"

setup_digital_ocean_api
setup_email_templating
get_set_remove

# vagrant related

mailcatcher_setup
capistrano_install
wpdeploy_install

# And it's done
end_seconds="$(date +%s)"
echo "-----------------------------"
echo "Provisioning complete in "$((${end_seconds} - ${start_seconds}))" seconds"

