#!/bin/sh

OOD_CONFIG=/etc/ood/config/ood_portal.yml

# modify values from env
#sed -i "s/^#servername: .*$/servername: ${OOD_SERVERNAME}/" ${OOD_CONFIG}

# update config
echo '=== ood ==='
cat ${OOD_CONFIG}
echo '==='

# generate configs
/opt/ood/ood-portal-generator/sbin/update_ood_portal

# modify logs to stderr/out
export OOD_PORTAL_CONF=/opt/rh/httpd24/root/etc/httpd/conf.d/ood-portal.conf
sed -i 's:ErrorLog .*:ErrorLog /dev/stderr:g' ${OOD_PORTAL_CONF}
sed -i 's:CustomLog .*:CustomLog /dev/stdout common:g' ${OOD_PORTAL_CONF}

echo '=== conf ==='
cat /opt/rh/httpd24/root/etc/httpd/conf.d/ood-portal.conf
echo '==='

# start apache
source /opt/rh/httpd24/enable
/opt/rh/httpd24/root/usr/sbin/apachectl -V

source /opt/rh/rh-nodejs6/enable 
source /opt/rh/rh-ror50/enable 
source /opt/rh/rh-ruby24/enable

echo '=== env ==='
env
echo '==='

# set the default ssh host
echo "DEFAULT_SSHHOST=${OOD_DEFAULT_SSHHOST:-localhost}" > /etc/ood/config/apps/shell/env

# start the webserver
exec  /opt/rh/httpd24/root/usr/sbin/apachectl -DFOREGROUND
