#!/bin/bash -xe

# update config
OOD_CONFIG=/etc/ood/config/ood_portal.yml
sed -i "s/^servername: .*$/servername: ${OOD_SERVERNAME}/" ${OOD_CONFIG}
echo "=== $OOD_CONFIG ==="
cat ${OOD_CONFIG} | grep -vE '^\s*\#' | grep -vE '^$'
echo '==='

# generate configs
/opt/ood/ood-portal-generator/sbin/update_ood_portal

# modify logs to stderr/out
export OOD_PORTAL_CONF=/opt/rh/httpd24/root/etc/httpd/conf.d/ood-portal.conf
sed -i 's:ErrorLog .*:ErrorLog /dev/stderr:g' ${OOD_PORTAL_CONF}
sed -i 's:CustomLog .*:CustomLog /dev/stdout common:g' ${OOD_PORTAL_CONF}
echo "=== $OOD_PORTAL_CONF ==="
cat $OOD_PORTAL_CONF | grep -vE '^\s*\#' | grep -vE '^$'
echo '==='

# inject oidc settings
OOD_AUTH_METHOD=${OOD_AUTH_METHOD:-htpasswd}

OIDC_CONFIG=/opt/rh/httpd24/root/etc/httpd/conf.d/auth_openidc.conf
if [[ "$OOD_AUTH_METHOD" == "oidc" ]]; then
  sed -i "s|^OIDCClientID.*|OIDCClientID  \"${OIDC_CLIENT_ID}\"|" $OIDC_CONFIG 
  sed -i "s|^OIDCClientSecret.*|OIDCClientSecret  \"${OIDC_CLIENT_SECRET}\"|" $OIDC_CONFIG
  sed -i "s|^OIDCCryptoPassphrase.*|OIDCCryptoPassphrase  ${OIDC_CRYPTO_PASSPHRASE:-$(openssl rand -hex 10)}|" $OIDC_CONFIG
  sed -i "s|^OIDCRedirectURI.*|OIDCRedirectURI  https://${OOD_SERVERNAME}/${OIDC_REDIRECT:-oidc}|" $OIDC_CONFIG
  echo "=== ${OIDC_CONFIG} ==="
  cat ${OIDC_CONFIG} | grep -vE '^\s*\#' | grep -vE '^$'
  echo '==='
else
  rm -f ${OIDC_CONFIG}
  AUTH_PASSWD=/opt/rh/httpd24/root/etc/httpd/.htpasswd
  cp /etc/ood/config/htpasswd/.htpasswd $AUTH_PASSWD
  chmod ugo+r $AUTH_PASSWD
fi

# start apache
source /opt/rh/httpd24/enable || true
/opt/rh/httpd24/root/usr/sbin/apachectl -V

source /opt/rh/rh-nodejs6/enable || true
source /opt/rh/rh-ror50/enable  || true
source /opt/rh/rh-ruby24/enable || true

echo '=== env ==='
env
echo '==='

# set the default ssh host
echo "DEFAULT_SSHHOST=${OOD_DEFAULT_SSHHOST:-localhost}" > /etc/ood/config/apps/shell/env

# start the webserver
exec  /opt/rh/httpd24/root/usr/sbin/apachectl -DFOREGROUND
