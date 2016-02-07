#!/bin/bash

chmod +x prod.sh
mv /srv/initial/config /srv/config
./prod.sh | tee log.txt