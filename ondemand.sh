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
OIDC_PROVIDER_ISSUER=${OIDC_PROVIDER_ISSUER:-https://cilogon.org}
OIDC_SCOPE=${OIDC_SCOPE:-openid email profile org.cilogon.userinfo}

CORS_ORIGIN=${CORS_ORIGIN:-${OIDC_PROVIDER_ISSUER}}

SHIB_CONFIG=${SHIB_CONFIG:-/etc/shibboleth/shibboleth2.xml}

case "$OOD_AUTH_METHOD" in
  oidc)

    # modify portal.yaml
    sed -i "s|^auth:|auth:\n- 'AuthType openid-connect'\n|" ${OOD_CONF}
    sed -i "s|^\#oidc_uri:.*|oidc_uri: /${OIDC_REDIRECT:-oidc}|" ${OOD_CONF}
    sed -i "s|^\#logout_redirect:.*|logout_redirect: '/${OIDC_REDIRECT:-oidc}?logout=https%3A%2F%2F${OOD_SERVERNAME}'|" ${OOD_CONF}

    # modify oidc conf
    sed -i "s|^\#OIDCProviderMetadataURL .*|OIDCProviderMetadataURL ${OIDC_PROVIDER_METADATA_URL:-${OIDC_PROVIDER_ISSUER}/.well-known/openid-configuration}|" $OIDC_CONFIG
    sed -i "s|^\#OIDCRedirectURI .*|OIDCRedirectURI  \"https://${OOD_SERVERNAME}/${OIDC_REDIRECT:-oidc}\"|" $OIDC_CONFIG 
    sed -i "s|^\#OIDCClientID .*|OIDCClientID  \"${OIDC_CLIENT_ID//[$'\t\r\n']}\"|" $OIDC_CONFIG 
    sed -i "s|^\#OIDCClientSecret .*|OIDCClientSecret  \"${OIDC_CLIENT_SECRET//[$'\t\r\n']}\"|" $OIDC_CONFIG
    sed -i "s|^\#OIDCCryptoPassphrase .*|OIDCCryptoPassphrase  ${OIDC_CRYPTO_PASSPHRASE//[$'\t\r\n']}|" $OIDC_CONFIG
    sed -i "s|^\#OIDCStateMaxNumberOfCookies .*|OIDCStateMaxNumberOfCookies ${OIDC_MAX_COOKIES:-10} true|" $OIDC_CONFIG
    sed -i "s|^\#OIDCSessionInactivityTimeout .*|OIDCSessionInactivityTimeout ${OIDC_INACTIVITY_TIMEOUT:-300}|" $OIDC_CONFIG
    sed -i "s|^\#OIDCSessionMaxDuration .*|OIDCSessionMaxDuration ${OIDC_SESSION_MAX_DURATION:-0}|" $OIDC_CONFIG
    sed -i "s|^\#OIDCCacheType .*|OIDCCacheType ${OIDC_CACHE_TYPE:-shm}|" $OIDC_CONFIG
    sed -i "s|^\#OIDCCacheDir .*|OIDCCacheDir ${OIDC_CACHE_DIR:-/tmp/}|" $OIDC_CONFIG
    sed -i "s|^\#OIDCRemoteUserClaim .*|OIDCRemoteUserClaim ${OIDC_REMOTE_USER_CLAIM:-'preferred_username'}|" $OIDC_CONFIG
    sed -i "s|^\#OIDCPassClaimsAs .*|OIDCPassClaimsAs environment|" $OIDC_CONFIG
    sed -i "s|^\#OIDCStripCookies .*|OIDCStripCookies mod_auth_openidc_session mod_auth_openidc_session_chunks mod_auth_openidc_session_0 mod_auth_openidc_session_1|" $OIDC_CONFIG
    sed -i "s|^\#OIDCSessionType .*|OIDCSessionType ${OIDC_SESSION_TYPE:-server-cache:persistent}|" $OIDC_CONFIG
    sed -i "s|^\#OIDCSessionCacheFallbackToCookie .*|OIDCSessionCacheFallbackToCookie On|" $OIDC_CONFIG
    sed -i "s|^\#OIDCPassRefreshToken .*|OIDCPassRefreshToken On|" $OIDC_CONFIG
    sed -i "s|^\#OIDCPassIDTokenAs .*|OIDCPassIDTokenAs serialized|" $OIDC_CONFIG
    sed -i "s|^\#OIDCRefreshAccessTokenBeforeExpiry .*|OIDCRefreshAccessTokenBeforeExpiry 60|" $OIDC_CONFIG
    sed -i "s|^\#OIDCProviderIssuer .*|OIDCProviderIssuer ${OIDC_PROVIDER_ISSUER}|" $OIDC_CONFIG
    sed -i "s|^\#OIDCProviderAuthorizationEndpoint .*|OIDCProviderAuthorizationEndpoint ${OIDC_PROVIDER_AUTHORIZATION_ENDPOINT:-${OIDC_PROVIDER_ISSUER}/authorize}|" $OIDC_CONFIG
    sed -i "s|^\#OIDCProviderTokenEndpoint .*|OIDCProviderTokenEndpoint ${OIDC_PROVIDER_TOKEN_ENDPOINT:-${OIDC_PROVIDER_ISSUER}/oauth2/token}|" $OIDC_CONFIG
    sed -i "s|^\#OIDCProviderTokenEndpointAuth .*|OIDCProviderTokenEndpointAuth ${OIDC_PROVIDER_TOKEN_ENDPOINT_AUTH:-client_secret_post}|" $OIDC_CONFIG
    sed -i "s|^\#OIDCProviderUserInfoEndpoint .*|OIDCProviderUserInfoEndpoint ${OIDC_PROVIDER_USER_INFO_ENDPOINT:-${OIDC_PROVIDER_ISSUER}/oauth2/userinfo}|" $OIDC_CONFIG
    sed -i "s|^\#OIDCScope .*|OIDCScope \"${OIDC_SCOPE}\"|" $OIDC_CONFIG
    
    
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
  "scope": "${OIDC_SCOPE}",
  "response_type": "code",
  "auth_request_params": "skin=default"
}
EOF

  ;;

  shib)

    sed -i 's|^auth:|auth:\n- "AuthType shibboleth"\n- "ShibRequestSetting requireSession 1"\n- "RequestHeader edit* Cookie \\\"(^_shibsession_[^;]*(;\\\\s*)?\|;\\\\s*_shibsession_[^;]*)\\\" \\\"\\\""\n- "RequestHeader unset Cookie \\\"expr=-z %{req:Cookie}\\\""|' /etc/ood/config/ood_portal.yml
    sed -i "s|^\#logout_redirect:.*|logout_redirect: '/Shibboleth.sso/Logout?return=https%3A%2F%2F${SHIB_SERVERNAME}%2Fidp%2Fprofile%2FLogout'|" ${OOD_CONF}

    sed -i "s|ShibCompatValidUser .*|ShibCompatValidUser On|" /opt/rh/httpd24/root/etc/httpd/conf.d/10-auth_shib.conf

    sed -i "s|    xmlns:conf=\"urn:mace:shibboleth:3.0:native:sp:config\"|    xmlns:conf=\"urn:mace:shibboleth:3.0:native:sp:config\"\n  xmlns:saml=\"urn:oasis:names:tc:SAML:2.0:assertion\"  xmlns:samlp=\"urn:oasis:names:tc:SAML:2.0:protocol\"  xmlns:md=\"urn:oasis:names:tc:SAML:2.0:metadata\"|" ${SHIB_CONFIG}
    sed -i "s|    <ApplicationDefaults entityID=.*|    <ApplicationDefaults entityID=\"https://${OOD_SERVERNAME}/shibboleth\"|" ${SHIB_CONFIG}
    sed -i "s| relayState=\"ss:mem\"|  relayState=\"cookie\"|" ${SHIB_CONFIG}
    sed -i "s| checkAddress=.*|checkAddress=\"true\" consistentAddress=\"true\" handlerSSL=\"true\" cookieProps=\"; path=/; secure; HttpOnly\">|" ${SHIB_CONFIG}
    sed -i "s|redirectLimit=\"exact\">||" ${SHIB_CONFIG}
    sed -i "s|<SSO entityID=.*|<SSO entityID=\"https://${SHIB_SERVERNAME}/adfs/services/trust\"|" ${SHIB_CONFIG}
    sed -i "s|  discoveryProtocol=\"SAMLDS\".*|  >|" ${SHIB_CONFIG}
    sed -i "s|<Logout>SAML2 Local</Logout>|<Logout template=\"logout\" asynchronous=\"false\">SAML2 Local</Logout>|" ${SHIB_CONFIG}
    sed -i "s|<Handler type=\"Session\" Location=\"/Session\" showAttributeValues=.*|<Handler type=\"Session\" Location=\"/Session\" showAttributeValues=\"true\"/>|" ${SHIB_CONFIG}
    sed -i "s|REMOTE_USER=\"eppn subject-id pairwise-id persistent-id\"|REMOTE_USER=\"eppn subject-id pairwise-id persistent-id\" signing=\"true\" encryption=\"true\"|" ${SHIB_CONFIG}
    sed -i "s|    <CredentialResolver |  <!-- <CredentialResolver |" ${SHIB_CONFIG}
    sed -i "s| certificate=\"sp-signing-cert.pem\"/>| certificate=\"sp-signing-cert.pem\"/> -->|" ${SHIB_CONFIG}
    sed -i "s| certificate=\"sp-encrypt-cert.pem\"/>| certificate=\"sp-encrypt-cert.pem\"/> -->|" ${SHIB_CONFIG}
    sed -i "s|    </ApplicationDefaults>|        <CredentialResolver type=\"File\" key=\"/var/cache/shibboleth/sp-key.pem\" certificate=\"certs/sp-cert.pem\"/>\n    </ApplicationDefaults>|" ${SHIB_CONFIG} 
    sed -i "s|<!-- Example of locally maintained metadata. -->|<MetadataProvider type=\"XML\" url=\"https://${SHIB_SERVERNAME}/FederationMetadata/2007-06/FederationMetadata.xml\" id=\"SLAC National Accelerator Laboratory\" backingFilePath=\"/var/cache/shibboleth/slacadfs-metadata.xml\" reloadInterval=\"7200\"></MetadataProvider>|" ${SHIB_CONFIG}

    # slac adfs not supplying correctly scoped attrs
    sed -i "s|<Rule xsi:type=\"ScopeMatchesShibMDScope\"/>|<!-- <Rule xsi:type=\"ScopeMatchesShibMDScope\"/> -->|" /etc/shibboleth/attribute-policy.xml

    # need to cp the key over
    SHIDB_SP_KEY_FILE=/var/cache/shibboleth/sp-key.pem
    cat /etc/shibboleth/certs/sp-key.pem > $SHIDB_SP_KEY_FILE && chown shibd:shibd $SHIDB_SP_KEY_FILE && chmod 0600 $SHIDB_SP_KEY_FILE     

    # can't log directly to stdout for some reason
    ln -sf /dev/stdout /var/log/shibboleth/shibd.log 
    ln -sf /dev/null /var/log/shibboleth/shibd_warn.log
    ln -sf /dev/stdout /var/log/shibboleth/signature.log 
    ln -sf /dev/stdout /var/log/shibboleth/transaction.log
    cp -rp /etc/shibboleth/shibd.logger.dist /etc/shibboleth/shibd.logger


    if [ ! -z ${DEBUG} ]; then
      sed -i "s/INFO/DEBUG/g" /etc/shibboleth/shibd.logger
    fi

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

# allow CORS for cilogon
sed -i "s|Header Set Cache-Control \"max-age=0, no-store\"|Header Set Cache-Control \"max-age=0, no-store\"\n  Header always Set Access-Control-Allow-Origin \"${OIDC_PROVIDER_ISSUER}\"\n  Header always Set Access-Control-Allow-Methods \"PUT, GET, POST, OPTIONS\"|" ${OOD_PORTAL_CONF}
#sed -i "s|AuthType openid-connect|  AuthType openid-connect\n    Header Set Access-Control-Allow-Origin \"*\"|g" ${OOD_PORTAL_CONF}

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
