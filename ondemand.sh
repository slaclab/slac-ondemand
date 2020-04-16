#!/bin/bash -x

# update config
OOD_CONF=/etc/ood/config/ood_portal.yml
sed -i "s/^servername: .*$/servername: ${OOD_SERVERNAME}/" ${OOD_CONF}

# modify logs to stderr/out
export OOD_PORTAL_CONF=/opt/rh/httpd24/root/etc/httpd/conf.d/ood-portal.conf
sed -i 's:ErrorLog .*:ErrorLog /dev/stderr:g' ${OOD_PORTAL_CONF}
sed -i 's:CustomLog .*:CustomLog /dev/stdout common:g' ${OOD_PORTAL_CONF}

# setup auth
OOD_AUTH_METHOD=${OOD_AUTH_METHOD:-htpasswd}
OIDC_CONFIG=/opt/rh/httpd24/root/etc/httpd/conf.d/auth_openidc.conf
case "$OOD_AUTH_METHOD" in
  oidc)

    # modify portal.yaml
    sed -i "s|^auth:|auth:\n- 'AuthType openid-connect'\n|" ${OOD_CONF}
    sed -i "s|^\#oidc_uri:.*|oidc_uri: /${OIDC_REDIRECT:-oidc}|" ${OOD_CONF}
    sed -i "s|^\#logout_redirect:.*|logout_redirect: '/${OIDC_REDIRECT:-oidc}?logout=https%3A%2F%2F${OOD_SERVERNAME}'|" ${OOD_CONF}

    # modify oidc conf
    sed -i "s|^\#OIDCProviderMetadataURL.*|OIDCProviderMetadataURL ${OIDC_PROVIDER_METADATA_URL:-https://cilogon.org/.well-known/openid-configuration}|" $OIDC_CONFIG
    sed -i "s|^\#OIDCClientSecret.*|OIDCClientSecret  \"${OIDC_CLIENT_SECRET}\"|" $OIDC_CONFIG
    sed -i "s|^\#OIDCRedirectURI.*|OIDCRedirectURI  \"https://${OOD_SERVERNAME}/${OIDC_REDIRECT:-oidc}\"|" $OIDC_CONFIG 
    sed -i "s|^\#OIDCClientID.*|OIDCClientID  \"${OIDC_CLIENT_ID}\"|" $OIDC_CONFIG 
    sed -i "s|^\#OIDCCryptoPassphrase.*|OIDCCryptoPassphrase  ${OIDC_CRYPTO_PASSPHRASE:-$(openssl rand -hex 10)}|" $OIDC_CONFIG
    sed -i "s|^\#OIDCSessionInactivityTimeout.*|OIDCSessionInactivityTimeout 28800|" $OIDC_CONFIG
    sed -i "s|^\#OIDCSessionMaxDuration.*|OIDCSessionMaxDuration 28800|" $OIDC_CONFIG
    sed -i "s|^\#OIDCRemoteUserClaim.*|OIDCRemoteUserClaim ${OIDC_REMOTE_USER_CLAIM:-'preferred_username'}|" $OIDC_CONFIG
    sed -i "s|^\#OIDCPassClaimsAs.*|OIDCPassClaimsAs environment|" $OIDC_CONFIG
    sed -i "s|^\#OIDCStripCookies.*|OIDCStripCookies mod_auth_openidc_session mod_auth_openidc_session_chunks mod_auth_openidc_session_0 mod_auth_openidc_session_1|" $OIDC_CONFIG
    echo "=== ${OIDC_CONFIG} ==="
    cat ${OIDC_CONFIG} | grep -vE '^\s*\#' | grep -vE '^$'
    echo '==='
  ;;
  htpasswd)
    #rm -f ${OIDC_CONFIG}
    OOD_AUTH_PASSWD=/opt/rh/httpd24/root/etc/httpd/.htpasswd
    sed -i "s|^auth:|auth:\n- 'AuthType Basic'\n- AuthName 'private'\n- 'RequestHeader unset Authorization'\n- 'AuthUserFile ${OOD_AUTH_PASSWD}'|" ${OOD_CONF}
    cp /etc/ood/config/htpasswd/.htpasswd $OOD_AUTH_PASSWD
    chmod ugo+r $OOD_AUTH_PASSWD
  ;;
  ldap)
    sed -i "s|^auth:|auth:\n- 'AuthType Basic'\n- AuthName 'private'\n- 'AuthBasicProvider ldap'\n- 'RequestHeader unset Authorization'\n- 'AuthLDAPURL ${OOD_AUTH_LDAPURL}'|" ${OOD_CONF}
    #rm -f ${OIDC_CONFIG}
  ;;
esac

# generate configs
echo "=== $OOD_CONF ==="
cat ${OOD_CONF} | grep -vE '^\s*\#' | grep -vE '^$'
echo '==='

echo "=== $OOD_PORTAL_CONF ==="
cat $OOD_PORTAL_CONF | grep -vE '^\s*\#' | grep -vE '^$'
echo '==='
/opt/ood/ood-portal-generator/sbin/update_ood_portal -f

# start apache
source /opt/rh/httpd24/enable || true
/opt/rh/httpd24/root/usr/sbin/apachectl -V

source /opt/rh/rh-nodejs10/enable || true
#source /opt/rh/rh-ror50/enable  || true
source /opt/rh/rh-ruby25/enable || true

echo '=== env ==='
env
echo '==='

# set the default ssh host
echo "DEFAULT_SSHHOST=${OOD_DEFAULT_SSHHOST:-localhost}" > /etc/ood/config/apps/shell/env

# start the webserver
if [ "${DEBUG}" == "1" ]; then
  while [ 1 ]; do
    /opt/rh/httpd24/root/usr/sbin/apachectl -DFOREGROUND
    echo "Apache HTTPD died..."
    sleep 60
  done
else
  exec  /opt/rh/httpd24/root/usr/sbin/apachectl -DFOREGROUND
fi
