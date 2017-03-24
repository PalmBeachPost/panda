#!/bin/bash

# PANDA Project server setup script for Ubuntu 16.04
# Must be executed with sudo!

set -x
exec 1> >(tee /var/log/panda-install.log) 2>&1

echo "PANDA installation beginning."

VERSION="1.2.0"
CONFIG_PATH="/opt/panda/setup_panda"

# Seems to help on command-line processing for 1604:
export VERSION="1.2.0"
export CONFIG_PATH="/opt/panda/setup_panda"

# Setup environment variables
echo "DEPLOYMENT_TARGET=\"deployed\"" >> /etc/environment
export DEPLOYMENT_TARGET="deployed"

# Install outstanding updates
apt-get --yes update
# 1604 change
# apt-get --yes upgrade
apt-get --yes dist-upgrade

# Install required packages
# 1604 change
# added solor-common and Java 8, rather than Java 7 or 6.
# added wget and curl, which may already be present
apt-get install --yes git openssh-server postgresql python2.7-dev libxml2-dev libxml2 libxslt1.1 libxslt1-dev nginx build-essential libpq-dev python-pip mercurial solr-common openjdk-8-jdk wget curl
pip install uwsgi

# HEY! Did we get dumped out of root here?

#1604 changes -- these are new
pip install --upgrade pip
apt-get --yes autoremove
apt-get --yes clean


#1604 changes -- let's drop systemd and stay with upstart for another four years
apt-get --yes install upstart-sysv
update-initramfs -u

echo MANUALLY RESTART HERE NOW. PICK UP THE REST WHEN YOU GET BACK.


## IS THIS RIGHT WITH SYSTEMD??????????????????????????????????????????????????????????????????????????????????
## Don't care, we're going back to upstart.

# Make sure SSH comes up on reboot
ln -s /etc/init.d/ssh /etc/rc2.d/S20ssh
ln -s /etc/init.d/ssh /etc/rc3.d/S20ssh
ln -s /etc/init.d/ssh /etc/rc4.d/S20ssh
ln -s /etc/init.d/ssh /etc/rc5.d/S20ssh

# Disabled for 1604
# # Setup Solr + Jetty
# wget -nv http://archive.apache.org/dist/lucene/solr/3.4.0/apache-solr-3.4.0.tgz -O /opt/apache-solr-3.4.0.tgz
# 
# cd /opt
# tar -xzf apache-solr-3.4.0.tgz
# mv apache-solr-3.4.0 solr
# cp -r solr/example solr/panda

# New for 1604:
ln -s /usr/share/solr /opt/solr
mkdir /opt/solr/panda


# Get PANDA code
# # # # # # # # # # # # # # # # ## # # git clone https://github.com/pandaproject/panda.git panda
################## HEY!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# Temporary 1604 change:
cd /opt
git clone https://github.com/PalmBeachPost/panda.git panda

cd /opt/panda
git checkout $VERSION

# Configure unattended upgrades


## IS THIS RIGHT WITH SYSTEMD??????????????????????????????????????????????????????????????????????????????????
## Don't care, we're going back to upstart.

cp $CONFIG_PATH/10periodic /etc/apt/apt.conf.d/10periodic
service unattended-upgrades restart

# New for 1604
mkdir /opt/solr/panda/solr

# Install Solr configuration
cp $CONFIG_PATH/solr.xml /opt/solr/panda/solr/solr.xml


mkdir /opt/solr/panda/solr/pandadata
mkdir /opt/solr/panda/solr/pandadata/conf
mkdir /opt/solr/panda/solr/pandadata/lib

cp $CONFIG_PATH/data_schema.xml /opt/solr/panda/solr/pandadata/conf/schema.xml
cp $CONFIG_PATH/english_names.txt /opt/solr/panda/solr/pandadata/conf/english_names.txt
cp $CONFIG_PATH/solrconfig.xml /opt/solr/panda/solr/pandadata/conf/solrconfig.xml
cp $CONFIG_PATH/panda.jar /opt/solr/panda/solr/pandadata/lib/panda.jar

mkdir /opt/solr/panda/solr/pandadata_test
mkdir /opt/solr/panda/solr/pandadata_test/conf
mkdir /opt/solr/panda/solr/pandadata_test/lib

cp $CONFIG_PATH/data_schema.xml /opt/solr/panda/solr/pandadata_test/conf/schema.xml
cp $CONFIG_PATH/english_names.txt /opt/solr/panda/solr/pandadata_test/conf/english_names.txt
cp $CONFIG_PATH/solrconfig.xml /opt/solr/panda/solr/pandadata_test/conf/solrconfig.xml
cp $CONFIG_PATH/panda.jar /opt/solr/panda/solr/pandadata_test/lib/panda.jar

mkdir /opt/solr/panda/solr/pandadatasets
mkdir /opt/solr/panda/solr/pandadatasets/conf

cp $CONFIG_PATH/datasets_schema.xml /opt/solr/panda/solr/pandadatasets/conf/schema.xml
cp $CONFIG_PATH/solrconfig.xml /opt/solr/panda/solr/pandadatasets/conf/solrconfig.xml

mkdir /opt/solr/panda/solr/pandadatasets_test
mkdir /opt/solr/panda/solr/pandadatasets_test/conf

cp $CONFIG_PATH/datasets_schema.xml /opt/solr/panda/solr/pandadatasets_test/conf/schema.xml
cp $CONFIG_PATH/solrconfig.xml /opt/solr/panda/solr/pandadatasets_test/conf/solrconfig.xml

adduser --system --no-create-home --disabled-login --disabled-password --group solr
chown -R solr:solr /opt/solr

touch /var/log/solr.log
chown solr:solr /var/log/solr.log

## IS THIS RIGHT WITH SYSTEMD??????????????????????????????????????????????????????????????????????????????????
## Don't care, we're going back to upstart.

cp $CONFIG_PATH/solr.conf /etc/init/solr.conf


## Don't care, we're going back to upstart.
# Disabled for 1604. Upstart is not installed.
# initctl reload-configuration

# Re-enabled for 1604
# HEY!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! Dies here. May need to reboot?

initctl reload-configuration

# Disabled to go back to upstart
# # New for 1604
#systemctl daemon-reload
service solr start

# Setup uWSGI
adduser --system --no-create-home --disabled-login --disabled-password --group panda
## IS THIS RIGHT WITH SYSTEMD??????????????????????????????????????????????????????????????????????????????????
## Don't care, we're going back to upstart.

cp $CONFIG_PATH/uwsgi_jumpstart.conf /etc/init/uwsgi.conf
initctl reload-configuration

# Setup nginx
cp $CONFIG_PATH/nginx /etc/nginx/sites-available/panda
ln -s /etc/nginx/sites-available/panda /etc/nginx/sites-enabled/panda
rm /etc/nginx/sites-enabled/default
service nginx restart

# Setup Postgres
# Disabled for 1604
# cp $CONFIG_PATH/pg_hba.conf /etc/postgresql/9.1/main/pg_hba.conf

# New for 1604
cp $CONFIG_PATH/pg_hba.conf /etc/postgresql/9.5/main/pg_hba.conf

service postgresql restart

# Create database users
echo "CREATE USER panda WITH PASSWORD 'panda';" | sudo -u postgres psql postgres
sudo -u postgres createdb -O panda panda

# Install Python requirements
pip install -r requirements.txt

# Setup panda directories 
mkdir /var/log/panda
touch /var/log/panda/panda.log
chown -R panda:panda /var/log/panda

mkdir /var/lib/panda
mkdir /var/lib/panda/uploads
mkdir /var/lib/panda/exports
mkdir /var/lib/panda/media

chown -R panda:panda /var/lib/panda

# Synchronize the database
sudo -u panda -E python manage.py syncdb --noinput
sudo -u panda -E python manage.py migrate --noinput
sudo -u panda -E python manage.py loaddata panda/fixtures/init_panda.json

# Collect static assets
sudo -u panda -E python manage.py collectstatic --noinput

# Start serving
service uwsgi start

# Setup Celery
cp $CONFIG_PATH/celeryd.conf /etc/init/celeryd.conf
initctl reload-configuration
mkdir /var/celery
chown panda:panda /var/celery
service celeryd start

echo "PANDA installation complete."

