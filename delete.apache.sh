#!/bin/sh
systemctl stop apache2
systemctl disable apache2

apt-get remove --purge apache2 apache2-doc apache2-mpm-itk apache2-utils apache2.2-bin apache2.2-common libapache2-mod-php5 libapache2-mod-rpaf libapache2-modsecurity


apt-get autoremove
whereis apache2
rm -rf /etc/apache2
rm -rf /usr/lib/apache2
rm -rf /usr/share/apache2
rm -rf /usr/share/man/man8/apache2.8.gz
