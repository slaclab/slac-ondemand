SECRET_PATH=secret/sdf/

etc:
	mkdir -p etc

passwords: etc
	# auth
	vault kv get --field=htpasswd -format=json $(SECRET_PATH)/ondemand-prod | sed -e 's/\"//g' > etc/htpassword
	vault kv get --field=ldap.password -format=json $(SECRET_PATH)/ondemand-prod | sed -e 's/\"//g' > etc/ldap.password
	vault kv get --field=oidc_client_id -format=json $(SECRET_PATH)/ondemand-prod | sed -e 's/\"//g' > etc/oidc_client_id
	vault kv get --field=oidc_client_secret -format=json $(SECRET_PATH)/ondemand-prod | sed -e 's/\"//g' > etc/oidc_client_secret
	vault kv get --field=oidc_crypto_passphrase -format=json $(SECRET_PATH)/ondemand-prod | sed -e 's/\"//g' > etc/oidc_crypto_passphrase
	vault kv get --field=sp-cert.pem -format=json $(SECRET_PATH)/ondemand-prod | sed -e 's/\"//g' > etc/sp-cert.pem
	vault kv get --field=sp-key.pem -format=json $(SECRET_PATH)/ondemand-prod | sed -e 's/\"//g' > etc/sp-key.pem
	# certs
	vault kv get --field=ondemand-dev.key -format=json $(SECRET_PATH)/ondemand-prod | sed -e 's/\"//g' > etc/ondemand-prod.key
	vault kv get --field=ondemand-dev.crt -format=json $(SECRET_PATH)/ondemand-prod | sed -e 's/\"//g' > etc/ondemand-prod.crt
	vault kv get --field=ondemand-dev.intermediates -format=json $(SECRET_PATH)/ondemand-prod | sed -e 's/\"//g' > etc/ondemand-prod.intermediates
    
apply:
	kubectl apply -k .
