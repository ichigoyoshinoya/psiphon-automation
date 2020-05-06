#!/bin/bash

# Copyright (c) 2012, Psiphon Inc.
# All rights reserved.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

set -e -x

MAILDECRYPTOR_USER="maildecryptor"

if [ ! -f ./s3decryptor.service ]; then
  echo "This script must be run from the source directory."
  exit 1
fi

cut -d: -f1 /etc/passwd | grep $MAILDECRYPTOR_USER > /dev/null
if [ "$?" -ne "0" ]; then
    echo "You must already have created the user $MAILDECRYPTOR_USER, otherwise this script will fail. See the README for details."
    exit 1
fi

# Create the diagnostic data SQL DB.
mysql -u root --socket=/var/run/mysqld/mysqld.sock < sql_diagnostic_feedback_schema.sql

sed "s|fill-in-with-path-to-source|\"`pwd`\"|" s3decryptor.service > s3decryptor.service.configured
sed "s|fill-in-with-path-to-source|\"`pwd`\"|" mailsender.service > mailsender.service.configured
sed "s|fill-in-with-path-to-source|\"`pwd`\"|" statschecker.service > statschecker.service.configured
sed "s|fill-in-with-path-to-source|\"`pwd`\"|" autoresponder.service > autoresponder.service.configured

sudo cp s3decryptor.service.configured /etc/systemd/system/s3decryptor.service
sudo cp mailsender.service.configured /etc/systemd/system/mailsender.service
sudo cp statschecker.service.configured /etc/systemd/system/statschecker.service
sudo cp autoresponder.service.configured /etc/systemd/system/autoresponder.service
rm *.service.configured

sudo chmod 0400 *.pem conf.json
sudo chown $MAILDECRYPTOR_USER:$MAILDECRYPTOR_USER *.pem conf.json

sudo cp FeedbackDecryptor.cron /etc/cron.d

sudo systemctl stop s3decryptor
sudo systemctl stop mailsender
sudo systemctl stop statschecker
sudo systemctl stop autoresponder
sudo systemctl daemon-reload
sudo systemctl enable s3decryptor
sudo systemctl enable mailsender
sudo systemctl enable statschecker
sudo systemctl enable autoresponder

echo "Done."
echo ""
echo "To start the feedback processing daemons execute:"
echo " > sudo systemctl start s3decryptor"
echo " > sudo systemctl start mailsender"
echo " > sudo systemctl start statschecker"
echo " > sudo systemctl start autoresponder"
echo ""
