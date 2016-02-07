#!/bin/bash


#we pass parameters like name of clients project and email - ./client_setup.sh ubisoft donatas.stirbys@hotmail.com


# ./client_setup.sh ubisoft cdonatas.stirbys@hotmail.com collect

brand="$1"
email="$2"
collect="$3"

install_client() {  # our own site running on wordpress
  # Install and configure the latest stable version of WordPress
  if [[ ! -d "/srv/www/clients/$brand" ]]; then

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

    echo "Downloading WordPress for Client ${brand}"
    cd /srv/www/client/
    git clone "https://github.com/ravaboard/suzie.git" "/srv/www/clients/$brand"
    cd /srv/www/clients/${brand}
    mv .env.example .env
    composer install
    sed -i -e 's/DB_NAME=suzie/DB_NAME=home/g' .env
    sed -i -e 's/DB_USER=root/DB_USER=happybits/g' .env
    sed -i -e 's/DB_PASSWORD=password/DB_PASSWORD=culturevulture/g' .env
    sed -i -e 's|SITE_URL=http://domain.com|SITE_URL=http://www.happybits.lt|' .env

    cd /srv/www/home/${brand}/public
    
    #set WP salts
    perl -i -pe'
    BEGIN {
    @chars = ("a" .. "z", "A" .. "Z", 0 .. 9);
    push @chars, split //, "!@#$%^&*()-_ []{}<>~\`+=,.;:/?|";
    sub salt { join "", map $chars[ rand @chars ], 1 .. 64 }
    }
    s/put your unique phrase here/salt()/ge
    ' wp-config.php

    cd /srv/www/client/${brand}/public/wordpress/
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

downloading_coming_soon() {
    echo "Downloading Coming Soon Page" 
    mkdir /srv/www/clients/$brand
    cd /srv/www/clients/$brand/
    git clone "https://donatas_stirbys:Gembird20@bitbucket.org/donatas_stirbys/comingsoon.git" "/srv/www/clients/$brand/soon"
    cd /srv/www/clients/$brand/soon
    sudo chmod 775 notify_emails.txt
}


downloading_collect() {
    echo "Downloading Collect Page" 
    cd /srv/www/clients/${brand}/soon
    git clone "https://donatas_stirbys:Gembird20@bitbucket.org/donatas_stirbys/collect.git" "/srv/www/clients/$brand/account" 
    cd /srv/www/clients/$brand/account
    composer install
}

setting_coming_soon_and_collect() {
 cd /etc/nginx/sites-available/
 touch $brand

 echo "server {
    listen       80;
    server_name  ${brand}.happybits.lt;
    root         /srv/www/clients/${brand}/soon;
" >> $brand

  echo 'index index.html index.htm index.php;

    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    access_log off;
    error_log  /var/log/nginx/finance-error.log error;

    sendfile off;

    client_max_body_size 100m;

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php5-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
    }

    location ~ /\.ht {
        deny all;
    }

 }' >> $brand


 ln -s /etc/nginx/sites-available/$brand /etc/nginx/sites-enabled/$brand

 sudo service nginx restart

 # Adding subdomain to Digital Ocean
 echo "Triggering Digital Ocean"
 curl -L --data "brand=${brand}" -L http://www.happybits.lt/digital/create.php
}

sending_client_email() {
 curl -L --data "email=${email}" --data "reason=greeting" --data "brand=${brand}" http://www.happybits.lt/emailing/process.php
}


collect_client_details() {
 curl -L --data "email=${email}" --data "reason=collect" --data "brand=${brand}" http://www.happybits.lt/emailing/process.php
}



echo "Installing client beta site"
# install_client
echo "Installing client done"

echo "Downloading coming soon page"
downloading_coming_soon
echo "Downloading coming soon page is done"

echo "Downloading collect"
downloading_collect
echo "Downloading collect page is done"


echo "Setting up coming soon page"
setting_coming_soon_and_collect
echo ""
echo "Setting coming soon page done"

echo "Sending client email"
sending_client_email

echo ""
echo "Sending client email done"


if [ -z "${collect}" ]; then
echo "collect is unset or set to the empty string"
else

echo ""
echo "Sending client email for account details"
 echo "Triggering Digital Ocean"
 curl -L --data "brand=${brand}-account" -L http://www.happybits.lt/digital/create.php
collect_client_details
fi



