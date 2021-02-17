#!/bin/bash -x

# update config
OOD_CONF=/etc/ood/config/ood_portal.yml
sed -i "s/^servername: .*$/servername: ${OOD_SERVERNAME}/" ${OOD_CONF}
sed -i "s/^host_regex: .*$/host_regex: '${OOD_HOST_REGEX}'/" ${OOD_CONF}

# setup auth
OOD_AUTH_METHOD=${OOD_AUTH_METHOD:-htpasswd}

OIDC_CONFIG=/opt/rh/httpd24/root/etc/httpd/conf.d/auth_openidc.conf
OIDC_METADATA_DIR=/var/cache/httpd/mod_auth_openidc/metadata
OIDC_CRYPTO_PASSPHRASE=${OIDC_CRYPTO_PASSPHRASE:-$(openssl rand -hex 10)}

SHIB_CONFIG=${SHIB_CONFIG:-/etc/shibboleth/shibboleth2.xml}

case "$OOD_AUTH_METHOD" in
  oidc)

    # modify portal.yaml
    sed -i "s|^auth:|auth:\n- 'AuthType openid-connect'\n|" ${OOD_CONF}
    sed -i "s|^\#oidc_uri:.*|oidc_uri: /${OIDC_REDIRECT:-oidc}|" ${OOD_CONF}
    sed -i "s|^\#logout_redirect:.*|logout_redirect: '/${OIDC_REDIRECT:-oidc}?logout=https%3A%2F%2F${OOD_SERVERNAME}'|" ${OOD_CONF}

    # modify oidc conf
    sed -i "s|^\#OIDCProviderMetadataURL .*|OIDCProviderMetadataURL ${OIDC_PROVIDER_METADATA_URL:-https://cilogon.org/.well-known/openid-configuration}|" $OIDC_CONFIG
    sed -i "s|^\#OIDCRedirectURI .*|OIDCRedirectURI  \"https://${OOD_SERVERNAME}/${OIDC_REDIRECT:-oidc}\"|" $OIDC_CONFIG 
    sed -i "s|^\#OIDCClientID .*|OIDCClientID  \"${OIDC_CLIENT_ID//[$'\t\r\n']}\"|" $OIDC_CONFIG 
    sed -i "s|^\#OIDCClientSecret .*|OIDCClientSecret  \"${OIDC_CLIENT_SECRET//[$'\t\r\n']}\"|" $OIDC_CONFIG
    sed -i "s|^\#OIDCCryptoPassphrase .*|OIDCCryptoPassphrase  ${OIDC_CRYPTO_PASSPHRASE//[$'\t\r\n']}|" $OIDC_CONFIG
    sed -i "s|^\#OIDCSessionInactivityTimeout .*|OIDCSessionInactivityTimeout 28800|" $OIDC_CONFIG
    sed -i "s|^\#OIDCSessionMaxDuration .*|OIDCSessionMaxDuration 28800|" $OIDC_CONFIG
    sed -i "s|^\#OIDCCacheType .*|OIDCCacheType ${OIDC_CACHE_TYPE:-shm}|" $OIDC_CONFIG
    sed -i "s|^\#OIDCCacheDir .*|OIDCCacheDir ${OIDC_CACHE_DIR:-/tmp/}|" $OIDC_CONFIG
    sed -i "s|^\#OIDCRemoteUserClaim .*|OIDCRemoteUserClaim ${OIDC_REMOTE_USER_CLAIM:-'preferred_username'}|" $OIDC_CONFIG
    sed -i "s|^\#OIDCPassClaimsAs .*|OIDCPassClaimsAs environment|" $OIDC_CONFIG
    sed -i "s|^\#OIDCStripCookies .*|OIDCStripCookies mod_auth_openidc_session mod_auth_openidc_session_chunks mod_auth_openidc_session_0 mod_auth_openidc_session_1|" $OIDC_CONFIG
    sed -i "s|^\#OIDCProviderIssuer .*|OIDCProviderIssuer ${OIDC_PROVIDER_ISSUER:-https://cilogon.org}|" $OIDC_CONFIG
    sed -i "s|^\#OIDCProviderAuthorizationEndpoint .*|OIDCProviderAuthorizationEndpoint ${OIDC_PROVIDER_AUTHORIZATION_ENDPOINT:-https://cilogon.org/authorize}|" $OIDC_CONFIG
    sed -i "s|^\#OIDCProviderTokenEndpoint .*|OIDCProviderTokenEndpoint ${OIDC_PROVIDER_TOKEN_ENDPOINT:-https://cilogon.org/oauth2/token}|" $OIDC_CONFIG
    sed -i "s|^\#OIDCProviderTokenEndpointAuth .*|OIDCProviderTokenEndpointAuth ${OIDC_PROVIDER_TOKEN_ENDPOINT_AUTH:-client_secret_post}|" $OIDC_CONFIG
    sed -i "s|^\#OIDCProviderUserInfoEndpoint .*|OIDCProviderUserInfoEndpoint ${OIDC_PROVIDER_USER_INFO_ENDPOINT:-https://cilogon.org/oauth2/userinfo}|" $OIDC_CONFIG
    sed -i "s|^\#OIDCScope .*|OIDCScope \"${OIDC_SCOPE:-openid email profile org.cilogon.userinfo}\"|" $OIDC_CONFIG
    
    
    #sed -i "s|^\#OIDCMetadataDir.*|OIDCMetadataDir ${OIDC_METADATA_DIR}|" $OIDC_CONFIG
    echo "=== ${OIDC_CONFIG} ==="
    cat ${OIDC_CONFIG} | grep -vE '^\s*\#' | grep -vE '^$'
    echo '==='

    mkdir -p ${OIDC_METADATA_DIR}
    chmod go-rwx ${OIDC_METADATA_DIR}
    cat <<EOF > ${OIDC_METADATA_DIR}/cilogon.org.provider
{
  "issuer": "https://cilogon.org",
  "authorization_endpoint": "https://cilogon.org/authorize",
  "token_endpoint": "https://cilogon.org/oauth2/token",
  "userinfo_endpoint": "https://cilogon.org/oauth2/userinfo",
  "response_types_supported": [
    "code"
  ],
  "token_endpoint_auth_methods_supported": [
    "client_secret_post"
  ]
}
EOF
    cat <<EOF > ${OIDC_METADATA_DIR}/cilogon.org.client
{
  "client_id": "${OIDC_CLIENT_ID}",
  "client_secret": "${OIDC_CLIENT_SECRET}"
}
EOF
    cat <<EOF > ${OIDC_METADATA_DIR}/cilogon.org.conf
{
  "scope": "openid email profile org.cilogon.userinfo",
  "response_type": "code",
  "auth_request_params": "skin=default"
}
EOF

  ;;

  shib)

    sed -i "s|^auth:|auth:\n- 'AuthType shibboleth'\n-  'ShibRequestSetting requireSession 1'\n-  'RequestHeader edit* Cookie \"(^_shibsession_[^;]*(;\\s*)?|;\\s*_shibsession_[^;]*)\" \"\"'\n-  'RequestHeader unset Cookie \"expr=-z %{req:Cookie}\"'\n-  'Require valid-user'\n|" ${OOD_CONF}
    sed -i "s|^\#logout_redirect:.*|logout_redirect: '/Shibboleth.sso/Logout?return=https%3A%2F%2F${SHIB_SERVERNAME}%2Fidp%2Fprofile%2FLogout'|" ${OOD_CONF}

    sed -i "s|    xmlns:conf=\"urn:mace:shibboleth:3.0:native:sp:config\"|    xmlns:conf=\"urn:mace:shibboleth:3.0:native:sp:config\"\n  xmlns:saml=\"urn:oasis:names:tc:SAML:2.0:assertion\"  xmlns:samlp=\"urn:oasis:names:tc:SAML:2.0:protocol\"  xmlns:md=\"urn:oasis:names:tc:SAML:2.0:metadata\"|" ${SHIB_CONFIG}
    sed -i "s|    <ApplicationDefaults entityID=.*|    <ApplicationDefaults entityID=\"https://${OOD_SERVERNAME}/shibboleth\"|" ${SHIB_CONFIG}
    sed -i "s| relayState=\"ss:mem\"|  relayState=\"cookie\"|" ${SHIB_CONFIG}
    sed -i "s| checkAddress=.*|checkAddress=\"true\" consistentAddress=\"true\" handlerSSL=\"true\" cookieProps=\"; path=/; secure; HttpOnly\">|" ${SHIB_CONFIG}
    sed -i "s|redirectLimit=\"exact\">||" ${SHIB_CONFIG}
    sed -i "s|<SSO entityID=.*|<SSO entityID=\"https://${SHIB_SERVERNAME}/adfs/services/trust\"|" ${SHIB_CONFIG}
    sed -i "s|<Logout>SAML2 Local</Logout>|<Logout template=\"logout\">SAML2 Local</Logout>|" ${SHIB_CONFIG}
    sed -i "s|<Handler type=\"Session\"|<Handler type=\"Session\" Location=\"/Session\" showAttributeValues=\"true\"/>|"
    sed -i "s|key=\"sp-signing-key.pem\".*|key=\"certs/sp-key.pem\" certificate=\"certs/sp-cert.pem\"/>|" ${SHIB_CONFIG}
    sed -i "s|key=\"sp-encrypt-key.pem\".*|key=\"certs/sp-key.pem\" certificate=\"certs/sp-cert.pem\"/>|" ${SHIB_CONFIG}
    sed -i "s|<!-- Example of locally maintained metadata. -->|<MetadataProvider type=\"XML\" url=\"https://${SHIB_SERVERNAME}/FederationMetadata/2007-06/FederationMetadata.xml\" backingFilePath=\"FederationMetadata.xml\" reloadInterval=\"7200\" ></MetadataProvider>|" ${SHIB_CONFIG}

    echo "===== ${SHIB_CONFIG} ====="
    cat ${SHIB_CONFIG}
    echo "=========="

  ;;
  htpasswd)
    #rm -f ${OIDC_CONFIG}
    OOD_AUTH_PASSWD=/opt/rh/httpd24/root/etc/httpd/.htpasswd
    sed -i "s|^auth:|auth:\n- 'AuthType Basic'\n- AuthName 'private'\n- 'RequestHeader unset Authorization'\n- 'AuthUserFile ${OOD_AUTH_PASSWD}'|" ${OOD_CONF}
    cp /etc/ood/config/htpasswd/.htpasswd $OOD_AUTH_PASSWD
    chmod ugo+r $OOD_AUTH_PASSWD
  ;;
  ldap)
    [[ ! -z "$OOD_AUTH_LDAPBINDDN" && ! -z $OOD_AUTH_LDAPBINDPASSWORD ]] && sed -i  "s|^auth:|auth:\n- AuthLDAPBindDN '${OOD_AUTH_LDAPBINDDN}'\n- AuthLDAPBindPassword \'${OOD_AUTH_LDAPBINDPASSWORD%$'\n'}\'|" ${OOD_CONF}
    sed -i "s|^auth:|auth:\n- AuthType 'Basic'\n- AuthName 'private'\n- AuthBasicProvider 'ldap'\n- 'RequestHeader unset Authorization'\n- AuthLDAPURL '${OOD_AUTH_LDAPURL}'|" ${OOD_CONF}
    sed -i "s|^auth:|auth:\n- AuthLDAPGroupAttribute '${OOD_AUTH_LDAPGROUPATTR:-gidNumber}'\n- AuthLDAPGroupAttributeIsDN off|"  ${OOD_CONF}
    
    #rm -f ${OIDC_CONFIG}
  ;;
esac

# user mapping
sed -i "s|^\#user_map_cmd: .*|user_map_cmd: ${OOD_USER_MAP_CMD:-/opt/ood/ood_auth_map/bin/ood_auth_map.regex --regex=\'^(\w+)@slac.stanford.edu$\'} |"  ${OOD_CONF}


# generate configs
echo "=== $OOD_CONF ==="
cat ${OOD_CONF} | grep -vE '^\s*\#' | grep -vE '^$'
echo '==='

# update ood apache config
/opt/ood/ood-portal-generator/sbin/update_ood_portal -f

# modify logs to stderr/out
export OOD_PORTAL_CONF=/opt/rh/httpd24/root/etc/httpd/conf.d/ood-portal.conf
sed -i 's:ErrorLog .*:ErrorLog /dev/stderr:g' /opt/rh/httpd24/root/etc/httpd/conf/httpd.conf 
sed -i 's:CustomLog .*:CustomLog /dev/stdout combined:g' /opt/rh/httpd24/root/etc/httpd/conf/httpd.conf
sed -i 's:TransferLog .*:TransferLog /dev/stdout:g' /opt/rh/httpd24/root/etc/httpd/conf/httpd.conf
sed -i 's:ErrorLog .*:ErrorLog /dev/stderr:g' ${OOD_PORTAL_CONF}
sed -i 's:CustomLog .*:CustomLog /dev/stdout common:g' ${OOD_PORTAL_CONF}
sed -i 's:ErrorLog .*:ErrorLog /dev/stderr:g' /opt/rh/httpd24/root/etc/httpd/conf.d/ssl.conf
sed -i 's:CustomLog .*:CustomLog /dev/stdout \:g' /opt/rh/httpd24/root/etc/httpd/conf.d/ssl.conf
sed -i 's:TransferLog .*:TransferLog /dev/stdout:g' /opt/rh/httpd24/root/etc/httpd/conf.d/ssl.conf

# disable http2
sed -i "s|^LoadModule http2_module|\#LoadModule http2_module|" /opt/rh/httpd24/root/etc/httpd/conf.modules.d/00-base.conf

# enable docs pages
sed -i "s|RedirectMatch ^/$ .*|RedirectMatch ^/$ \"${HTTPD_TOPLEVEL:-/public/doc}\"|" ${OOD_PORTAL_CONF}

echo "=== $OOD_PORTAL_CONF ==="
cat $OOD_PORTAL_CONF | grep -vE '^\s*\#' | grep -vE '^$'
echo '==='

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
cat <<EOF > /etc/ood/config/apps/shell/env
DEFAULT_SSHHOST=${OOD_DEFAULT_SSHHOST:-localhost}
OOD_SHELL_ORIGIN_CHECK='off'
EOF



# add extra top level meny items
OOD_DASHBOARD_INIT_DIR=/etc/ood/config/apps/dashboard/initializers/
mkdir -p ${OOD_DASHBOARD_INIT_DIR}
cat <<EOF > ${OOD_DASHBOARD_INIT_DIR}/ood.rb
NavConfig.categories = [ 'Documentation', 'Files', 'Jobs', 'Clusters', 'Interactive Apps', 'Reports' ]
NavConfig.categories_whitelist = true
EOF

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
