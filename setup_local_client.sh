#!/usr/bin/env bash

brand="$1"
email="$2"
collect="$3"

setup_local_client() {  # our own site running on wordpress
  # Install and configure the latest stable version of WordPress


    echo "Set up database"

    mysql -u "root" -proot -Bse "CREATE DATABASE IF NOT EXISTS ${brand}";

    echo "Setting up database done"

    WP_ADMIN="happybits"
    WP_ADMIN_PASS="culturevulture"
    WP_ADMIN_NAME="Donatas"
    WP_ADMIN_EMAIL="donatas.stirbys@hotmail.com"
    WP_URL="${brand}.local.dev"

    echo "Triggering deployer"

    # add deployment info
    cd /srv/www/deploy/config/deploy

    echo "set :stage, :${brand}
    server '178.62.83.46', user: 'deployer', roles: %w{web app db}, port: 25000
    set :branch, \"dev\"
    set :deploy_to, \"/srv/www/${brand}\"
    set :local_temp, \"/srv/www/${brand}/temp\"

    set :repo_url, \"https://donatas_stirbys:Gembird20@bitbucket.org/donatas_stirbys/${brand}.git\"
    set :scm, :git

    databaseyml = YAML::load_file('config/database.yml')[fetch(:stage).to_s]
    set :db_database, databaseyml['database']
    set :db_username, databaseyml['username']
    set :db_password, databaseyml['password']

    set :ssh_options, {
    paranoid: false,
    user: 'deployer',
    keys: %w('/root/.ssh/id_rsa'),
    forward_agent: true,
    auth_methods: %w(publickey)
    }" >> ${brand}.rb


    cd /srv/www/deploy/config/

    echo " ${brand}:
      host: localhost
      database: ${brand}
      username: happybits
      password: 'culturevulture'
   " >> database.yml


     echo "Triggering Nginx"

     cd /etc/nginx/conf.d/

     echo "server {
        listen       80;
        server_name  ${brand}.local.dev;
        root         /srv/www/${brand}/public;
        include      /etc/nginx/nginx-wp-common.conf;
    }" >> default.conf

    sudo service nginx restart

    echo "Running composer"
    
    cd /srv/www/${brand}
    mv .env.example .env
    composer install

    echo "Installing packages with composer is done"
 
    # echo to wp-config

    echo "define('DISALLOW_FILE_EDIT', true);" >> /srv/www/${brand}/public/wp-config.php

    sed -i -e "s/DB_NAME=suzie/DB_NAME=${brand}/g" .env
    sed -i -e "s/DB_USER=root/DB_USER=happybits/g" .env
    sed -i -e "s/DB_PASSWORD=password/DB_PASSWORD=culturevulture/g" .env
    sed -i -e "s|SITE_URL=http://domain.com|SITE_URL=http://${brand}.local.dev|" .env

    cd /srv/www/${brand}/public
    
    #set WP salts
    perl -i -pe'
    BEGIN {
    @chars = ("a" .. "z", "A" .. "Z", 0 .. 9);
    push @chars, split //, "!@#$%^&*()-_ []{}<>~\`+=,.;:/?|";
    sub salt { join "", map $chars[ rand @chars ], 1 .. 64 }
    }
    s/put your unique phrase here/salt()/ge
    ' wp-config.php

    cd /srv/www/${brand}/public/wordpress/
    mkdir wp-content/uploads
    chmod 775 wp-content/uploads

    wget --post-data "weblog_title=Happybits&user_name=${WP_ADMIN}&admin_password=${WP_ADMIN_PASS}&admin_password2=${WP_ADMIN_PASS}&admin_email=${WP_ADMIN_EMAIL}" http://${brand}.local.dev/wordpress/wp-admin/install.php?step=2

    sudo mv /srv/www/${brand}/public/wordpress/wp-content/themes/twentyfifteen /srv/www/${brand}/public/content/themes #temporary

    echo "Setting up plugins"

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
    WP_PLUGINS+=( all-in-one-seo-pack )
    WP_PLUGINS+=( revision-control )
    WP_PLUGINS+=( simple-trackback-disabler )
    WP_PLUGINS+=( wp-super-cache )

    # Install and activate plugins.
    for WP_PLUGIN in "${WP_PLUGINS[@]}"; do
      wp plugin install ${WP_PLUGIN} --allow-root
    done

    cp -fr wp-content/plugins /srv/www/${brand}/public/content/ 

    rm -rf /srv/www/temp
    echo "Setting up wordpress plugins done"

    echo "Trigger remote script"

    ssh -t deployer@178.62.83.46 -p 25000 /srv/www/clients/trigger_from_local.sh ${brand} ${email} ${collect}

}


setup_local_client
