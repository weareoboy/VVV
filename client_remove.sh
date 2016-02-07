#!/bin/bash

brand="$1"
email="$2"
site="$3"

remove_client() {  
  # Install and configure Client wordpress
  if [[ ! -d "/srv/www/clients/$brand" ]]; then
    echo "We do not want to remove the client yet"
    # sudo rm -rf /srv/www/clients/$brand

    # Remove coming soon if exists
    # sudo rm -rf /srv/www/clients/$brand/soon

    # Remove client nginx setup
    # cd /etc/nginx/sites-available/

    # We need a way to remove server config from default

    # service nginx restart

    # Removing client from Digital Ocean hosts

    # echo "Triggering Digital Ocean"
    # curl --data "brand=${brand}" -L http://www.happybits.lt/digital/remove.php

  else
    echo "Such client does not exist"
  fi
}

sending_client_email() {
 curl -L --data "email=${email}" --data "reason=thanks" --data "brand=${brand}" --data "site=${site}" http://www.happybits.lt/emailing/process.php

}

echo ''
echo 'Removing client from the server'
remove_client

echo ''
echo 'Sending client notification'



