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
  
  # Installing phpmyadmin
  phpmyadmin

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


### FUNCTIONS

# DDOS https://easyengine.io/tutorials/nginx/fail2ban/

#pabaigti mysql dump i S3 scripta, prideti i cron, kad runnintu weekly

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
    export domain=http://www.happybits.lt
    export SERVER_IP=178.62.83.46
    export HOME=/home/deployer


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
  
   # Protect su by limiting access only to admin group.
	  sudo groupadd admin
	  sudo usermod -a -G admin deployer
    # exec su -l deployer

	  # generate a key pair
	  ssh-keygen -t rsa -N "" -f /home/deployer/.ssh/id_rsa
	
      # https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys--2
      
	  cd /etc/ssh/
	  sed -i -e 's/Port 22/Port 25000/g' sshd_config
   	sed -i -e 's/PermitRootLogin yes/PermitRootLogin no/g' sshd_config
	  echo "DebianBanner no" >> sshd_config #Hides debian version on Ubuntu
	  echo "UseDNS no" >> sshd_config
	  echo "AllowUsers deployer" >> sshd_config

	  # Restart ssh

	  service ssh restart

    ssh-copy-id deployer@$SERVER_IP -p 25000
    chmod 400 /home/deployer/.ssh/authorized_keys
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
    apt-get install -y ${apt_package_install_list[@]}

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
    sudo cp /srv/initial/auth.json /home/deployer/.composer/
    sudo cp /srv/initial/auth.json /root/.config/composer
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
  sudo cp -f "/srv/config/nginx-config/sites/default" "/etc/nginx/sites-available/default"

  echo " * Copied /srv/config/nginx-config/nginx.conf to /etc/nginx/nginx.conf"
  echo " * Copied /srv/config/nginx-config/nginx-wp-common.conf to /etc/nginx/nginx-wp-common.conf"
  echo " * Copied /srv/config/nginx-config/sites/default.conf to /etc/nginx/sites-available/default.conf"
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

  echo " * Copied /srv/config/memcached-config/memcached.conf   to /etc/memcached.conf"
}

modify_php() {

if [[ -d "/etc/php5/fpm/" ]]; then
  cd /etc/php5/fpm
  sed -i -e 's/;opcache.enable=0/opcache.enable=1/g' php.ini
  sed -i -e 's/;opcache.memory_consumption=64/opcache.memory_consumption=128/g' php.ini
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
    mysql -u "root" -p < "/srv/config/database/init.sql"

    # Process each mysqldump SQL file in database/backups to import
    # an initial data set for MySQL.
    cd /srv/config/database/
    chmod +x import-sql.sh
    ./import-sql.sh

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
  /srv/www/phpcs/scripts/phpcs --config-set installed_paths ./CodeSniffer/Standards/WordPress/
  /srv/www/phpcs/scripts/phpcs --config-set default_standard WordPress-Core
  /srv/www/phpcs/scripts/phpcs -i
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

    #Securing PHPMyAdmin
    echo "Securing PHPMyAdmin"
    sudo echo "$cfg['Servers'][$i]['password'] = 'culturevulture'" >> /etc/phpmyadmin/config.inc.php
    sudo ln -s /usr/share/phpmyadmin/ /usr/share/nginx/html 
    sudo touch /etc/nginx/pma_pass
    sudo echo "admin:fFhrdb.xsk3UE" >> /etc/nginx/pma_pass
    sudo php5enmod mcrypt
    sudo service php5-fpm restart
}


install_ninja() {
 if [[ ! -d " /srv/www/ninja/" ]]; then
 	echo "Downloading Invoice Ninja"
 	cd /srv/www
 	git clone https://github.com/invoiceninja/invoiceninja.git ninja
  cd /srv/www/ninja
  composer install
  sudo chown -R www-data:www-data storage public
  sudo chmod -R 777 storage
  sudo chown -R www-data:www-data storage public/logo
  mv .env.example .env
  sudo chmod -R 777 .env
  sed -i -e 's/DB_USERNAME/DB_USERNAME=ninja/g' .env
  sed -i -e 's/DB_PASSWORD/DB_PASSWORD=culturevulture/g' .env
  sed -i -e 's/APP_DEBUG=false/APP_DEBUG=true/g' .env
  npm install

  touch /var/log/nginx/finance-error.log
 fi
}


install_staging() {  # our own site running on wordpress
  # Install and configure the latest stable version of WordPress
  if [[ ! -d "/srv/www/staging" ]]; then

    WP_ADMIN="happybits"
    WP_ADMIN_PASS="culturevulture"
    WP_ADMIN_NAME="Donatas"
    WP_ADMIN_EMAIL="donatas.stirbys@hotmail.com"
    WP_URL="http://www.happybits.lt"
 
    # echo to wp-config

    echo "define('AUTOSAVE_INTERVAL', 300);" >> /srv/www/staging/public/wp-config.php
    echo " define('WP_POST_REVISIONS', false);" >> /srv/www/staging/public/wp-config.php
    echo "define('EMPTY_TRASH_DAYS', 7);" >> /srv/www/staging/public/wp-config.php
    echo "define('DISALLOW_FILE_EDIT', true);" >> /srv/www/staging/public/wp-config.php
    echo "define('FORCE_SSL_ADMIN', true);" >> /srv/www/staging/public/wp-config.php

    echo "Downloading WordPress for Staging"
    cd /srv/www/
    git clone "https://github.com/ravaboard/suzie.git" "/srv/www/staging"
    cd /srv/www/staging
    mv .env.example .env
    composer install
    sed -i -e 's/DB_NAME=suzie/DB_NAME=staging/g' .env
    sed -i -e 's/DB_USER=root/DB_USER=happybits/g' .env
    sed -i -e 's/DB_PASSWORD=password/DB_PASSWORD=culturevulture/g' .env
    sed -i -e 's|SITE_URL=http://domain.com|SITE_URL=http://staging.happybits.lt|' .env

    cd /srv/www/staging/public
    
    #set WP salts
    perl -i -pe'
    BEGIN {
    @chars = ("a" .. "z", "A" .. "Z", 0 .. 9);
    push @chars, split //, "!@#$%^&*()-_ []{}<>~\`+=,.;:/?|";
    sub salt { join "", map $chars[ rand @chars ], 1 .. 64 }
    }
    s/put your unique phrase here/salt()/ge
    ' wp-config.php

    cd /srv/www/staging/public/wordpress/
    mkdir wp-content/uploads
    chmod 775 wp-content/uploads

    wget --post-data "weblog_title=Happybits&user_name=${WP_ADMIN}&admin_password=${WP_ADMIN_PASS}&admin_password2=${WP_ADMIN_PASS}&admin_email=${WP_ADMIN_EMAIL}" http://staging.happybits.lt/wordpress/wp-admin/install.php?step=2

  else
    echo "Updating WordPress for Staging..."
    cd /srv/www/staging
    git pull --rebase origin master
    composer update
  fi
}


install_beta() {  # our own site running on wordpress
  # Install and configure the latest stable version of WordPress
  if [[ ! -d "/srv/www/beta" ]]; then

    WP_ADMIN="happybits"
    WP_ADMIN_PASS="culturevulture"
    WP_ADMIN_NAME="Donatas"
    WP_ADMIN_EMAIL="donatas.stirbys@hotmail.com"
    WP_URL="http://www.happybits.lt"
 
    # echo to wp-config

    echo "define('AUTOSAVE_INTERVAL', 300);" >> /srv/www/beta/public/wp-config.php
    echo " define('WP_POST_REVISIONS', false);" >> /srv/www/beta/public/wp-config.php
    echo "define('EMPTY_TRASH_DAYS', 7);" >> /srv/www/beta/public/wp-config.php
    echo "define('DISALLOW_FILE_EDIT', true);" >> /srv/www/beta/public/wp-config.php
    echo "define('FORCE_SSL_ADMIN', true);" >> /srv/www/beta/public/wp-config.php

    echo "Downloading WordPress for Beta"
    cd /srv/www/
    git clone "https://github.com/ravaboard/suzie.git" "/srv/www/beta"
    cd /srv/www/beta
    mv .env.example .env
    composer install
    sed -i -e 's/DB_NAME=suzie/DB_NAME=beta/g' .env
    sed -i -e 's/DB_USER=root/DB_USER=happybits/g' .env
    sed -i -e 's/DB_PASSWORD=password/DB_PASSWORD=culturevulture/g' .env
    sed -i -e 's|SITE_URL=http://domain.com|SITE_URL=http://beta.happybits.lt|' .env

    cd /srv/www/beta/public
    
    #set WP salts
    perl -i -pe'
    BEGIN {
    @chars = ("a" .. "z", "A" .. "Z", 0 .. 9);
    push @chars, split //, "!@#$%^&*()-_ []{}<>~\`+=,.;:/?|";
    sub salt { join "", map $chars[ rand @chars ], 1 .. 64 }
    }
    s/put your unique phrase here/salt()/ge
    ' wp-config.php

    cd /srv/www/beta/public/wordpress/
    mkdir wp-content/uploads
    chmod 775 wp-content/uploads

    wget --post-data "weblog_title=Happybits&user_name=${WP_ADMIN}&admin_password=${WP_ADMIN_PASS}&admin_password2=${WP_ADMIN_PASS}&admin_email=${WP_ADMIN_EMAIL}" http://beta.happybits.lt/wordpress/wp-admin/install.php?step=2

  else
    echo "Updating WordPress for Beta..."
    cd /srv/www/beta
    git pull --rebase origin master
    composer update
  fi
}


install_home() {  # our own site running on wordpress
  # Install and configure the latest stable version of WordPress
  if [[ ! -d "/srv/www/home" ]]; then

    WP_ADMIN="happybits"
    WP_ADMIN_PASS="culturevulture"
    WP_ADMIN_NAME="Donatas"
    WP_ADMIN_EMAIL="donatas.stirbys@hotmail.com"
    WP_URL="http://www.happybits.lt"
 
    # echo to wp-config

    echo "define('AUTOSAVE_INTERVAL', 300);" >> /srv/www/home/public/wp-config.php
    echo " define('WP_POST_REVISIONS', false);" >> /srv/www/home/public/wp-config.php
    echo "define('EMPTY_TRASH_DAYS', 7);" >> /srv/www/home/public/wp-config.php
    echo "define('DISALLOW_FILE_EDIT', true);" >> /srv/www/home/public/wp-config.php
    echo "define('FORCE_SSL_ADMIN', true);" >> /srv/www/home/public/wp-config.php

    echo "Downloading WordPress for Home"
    cd /srv/www/
    git clone "https://github.com/ravaboard/suzie.git" "/srv/www/home"
    cd /srv/www/home
    mv .env.example .env
    composer install
    sed -i -e 's/DB_NAME=suzie/DB_NAME=home/g' .env
    sed -i -e 's/DB_USER=root/DB_USER=happybits/g' .env
    sed -i -e 's/DB_PASSWORD=password/DB_PASSWORD=culturevulture/g' .env
    sed -i -e 's|SITE_URL=http://domain.com|SITE_URL=http://www.happybits.lt|' .env

    cd /srv/www/home/public
    
    #set WP salts
    perl -i -pe'
    BEGIN {
    @chars = ("a" .. "z", "A" .. "Z", 0 .. 9);
    push @chars, split //, "!@#$%^&*()-_ []{}<>~\`+=,.;:/?|";
    sub salt { join "", map $chars[ rand @chars ], 1 .. 64 }
    }
    s/put your unique phrase here/salt()/ge
    ' wp-config.php

    cd /srv/www/home/public/wordpress/
    mkdir wp-content/uploads
    chmod 775 wp-content/uploads

    wget --post-data "weblog_title=Happybits&user_name=${WP_ADMIN}&admin_password=${WP_ADMIN_PASS}&admin_password2=${WP_ADMIN_PASS}&admin_email=${WP_ADMIN_EMAIL}" http://www.happybits.lt/wordpress/wp-admin/install.php?step=2

    sudo mv /srv/www/home/public/wordpress/wp-content/themes/twentyfifteen /srv/www/home/public/content/themes #temporary

  else
    echo "Updating WordPress for Home..."
    cd /srv/www/home
    git pull --rebase origin master
    composer update
  fi
}

setup_wordpress_plugins() {
   
    echo "Installing temporary wordpress"

    cd /srv/www/
    mkdir temp
    cd temp

    wp core download --allow-root
    wp core config --allow-root --dbname=beta --dbuser=happybits --dbpass=culturevulture --quiet
    wp core install --allow-root --url=local.wordpress.dev --quiet --title="Local WordPress Dev" --admin_name=admin --admin_email="admin@local.dev" --admin_password="password"

    # Plugins to install and activate.
    WP_PLUGINS=()
    WP_PLUGINS+=( anti-spam )
    WP_PLUGINS+=( autoptimize )
    WP_PLUGINS+=( disable-comments )
    WP_PLUGINS+=( disable-search )
    WP_PLUGINS+=( easy-wp-smtp )
    WP_PLUGINS+=( w3-total-cache )
    WP_PLUGINS+=( vaultpress )
    WP_PLUGINS+=( akismet )
    WP_PLUGINS+=( wordpress-importer )
    WP_PLUGINS+=( google-sitemap-generator )
    WP_PLUGINS+=( limit-login-attempts )
    WP_PLUGINS+=( all-inone-seo-pack )
    WP_PLUGINS+=( revision-control )
    WP_PLUGINS+=( simple-trackback-disabler )
    WP_PLUGINS+=( wp-super-cache )

    # Install and activate plugins.
    for WP_PLUGIN in "${WP_PLUGINS[@]}"; do
      wp plugin install ${WP_PLUGIN} --allow-root
    done

    cp -fr wp-content/plugins /srv/www/home/public/content/ 
    cp -fr wp-content/plugins /srv/www/staging/public/content/ 
    cp -fr wp-content/plugins /srv/www/beta/public/content/ 

    rm -rf /srv/www/temp
    echo "Setting up wordpress plugins done"
}



install_varnish() {
  # we are not instaling it as varnish in front of nginx does not give big improvement
  apt-get install apt-transport-https
  curl https://repo.varnish-cache.org/GPG-key.txt | apt-key add -
  echo "deb https://repo.varnish-cache.org/ubuntu/ trusty varnish-4.0" >> /etc/apt/sources.list.d/varnish-cache.list
  apt-get update
  apt-get install varnish
  cd /etc/default/
  #might be a problem in here with the single quote
  echo   "DAEMON_OPTS='-a :80 \ 
            -T localhost:6082 \
            -f /etc/varnish/default.vcl \
            -S /etc/varnish/secret \
            -s malloc,256m" >> default
}


install_piwik() {
   cd /srv/www
   wget http://builds.piwik.org/latest.zip
   unzip latest.zip
   rm *html *zip
   chown -R www-data:www-data /srv/www/piwik
   touch /var/log/nginx/piwik-error.log
}     



configure_s3() {
    if [[ ! -d "/home/deployer/backups" ]]; then
    cd /home/deployer
    mkdir backups
    cp "/srv/config/backup-to-s3/.s3cfg" "/home/deployer/.s3cfg"
    cp "/srv/config/backup-to-s3/s3backup.sh" "/home/deployer/backups/s3backup.sh"
    cd /home/deployer/backups/
    chmod +x s3backup.sh
    echo "00 09 * * 7 root /home/deployer/backups/s3backup.sh" >> /etc/crontab
    else
        echo "Backup to S3 is already set"
    fi
}


configure_client_area() {
  mkdir /srv/www/clients
  cp "/srv/initial/client_setup.sh" "/srv/www/clients/"
  cd /srv/www/clients
  sudo chmod +x client_setup.sh

  cp "/srv/initial/client_remove.sh" "/srv/www/clients/"
  cd /srv/www/clients
  sudo chmod +x client_remove.sh
}

setup_digital_ocean_api() {
  cd /srv/www/home/public
  git clone https://donatas_stirbys:Gembird20@bitbucket.org/donatas_stirbys/digitalocean.git digital
  cd digital
  composer install
}

setup_email_templating() {
  cd /srv/www/home/public
  git clone https://donatas_stirbys@bitbucket.org/donatas_stirbys/emailing.git emailing
  cd emailing
  composer install
}

setup_encrypter() {
  cd /srv/www/home/public
  git clone https://donatas_stirbys@bitbucket.org/donatas_stirbys/encrypter.git encrypter
  cd encrypter
  composer install
}


get_set_remove() {

   echo "Working on passwords file"
   touch /home/deployer/.env
   sudo chown -R www-data:www-data /home/deployer/.env
   curl -L --data "service=dbuser" --data "pass=culturevulture" -L http://www.happybits.lt/encrypter/encrypter.php
   curl -L --data "service=dbpass" --data "pass=culturevulture@1000" -L http://www.happybits.lt/encrypter/encrypter.php
   curl -L --data "service=amazonkey" --data "pass=AKIAIWDGW3GY2TZ7PVYA" -L http://www.happybits.lt/encrypter/encrypter.php
   curl -L --data "service=amazonsecretkey" --data "pass=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" -L http://www.happybits.lt/encrypter/encrypter.php
   curl -L --data "service=bucket" --data "pass=s3://hpbuckets/" -L http://www.happybits.lt/encrypter/encrypter.php
   curl -L --data "service=digital" --data "pass=uoE7U99dulciJjsSYWZ1LByQ4dph5fZ1" -L http://www.happybits.lt/encrypter/encrypter.php
   curl -L --data "service=ninja" --data "pass=c16b819188bdf63929413ca1b5c15e78e192f7b15d9d96be0302957bfa3902a2" -L http://www.happybits.lt/encrypter/encrypter.php
   curl -L --data "service=gmail" --data "pass=Gembird20" -L http://www.happybits.lt/encrypter/encrypter.php
  echo "Setting timezone"
  sudo timedatectl set-timezone Europe/Vilnius

  echo "Sending emails"
  mutt -s "Install log" donatas.stirbys@hotmail.com < /srv/initial/log.txt
  mutt -s "SSH private key" donatas.stirbys@hotmail.com < /home/deployer/.ssh/id_rsa
  sudo logwatch --mailto donatas.stirbys@hotmail.com --output mail --format html --range 'between -7 days and today' 

  echo "Removing provisioning"
  rm -rf /srv/initial

  echo "Removing provisioning config"
  rm -rf /srv/config

  # Setting back root
  cd
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

# Time for WordPress!
echo " "
echo "Installing/updating WordPress Environments"

install_staging
install_beta
install_home

echo " "
echo "Installing piwik"

install_piwik

echo " "
echo "Performing further configuration"

setup_wordpress_plugins
configure_s3
configure_client_area
setup_digital_ocean_api
setup_email_templating
get_set_remove

# And it's done
end_seconds="$(date +%s)"
echo "-----------------------------"
echo "Provisioning complete in "$((${end_seconds} - ${start_seconds}))" seconds"

