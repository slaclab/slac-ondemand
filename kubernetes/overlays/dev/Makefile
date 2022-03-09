SECRET_PATH=secret/sdf

.PHONY: etc

etc:
	mkdir -p etc/.secrets

secrets: etc
	# auth
	vault kv get --field=htpasswd -format=json $(SECRET_PATH)/ondemand-dev | sed -e 's/\"//g' > etc/.secrets/htpasswd
	vault kv get --field=ldap.password -format=json $(SECRET_PATH)/ondemand-dev | sed -e 's/\"//g' > etc/.secrets/ldap.password
	vault kv get --field=oidc_client_id -format=json $(SECRET_PATH)/ondemand-dev | sed -e 's/\"//g' > etc/.secrets/oidc_client_id
	vault kv get --field=oidc_client_secret -format=json $(SECRET_PATH)/ondemand-dev | sed -e 's/\"//g' > etc/.secrets/oidc_client_secret
	vault kv get --field=oidc_crypto_passphrase -format=json $(SECRET_PATH)/ondemand-dev | sed -e 's/\"//g' > etc/.secrets/oidc_crypto_passphrase
	vault kv get --field=sp-cert.pem -format=json $(SECRET_PATH)/ondemand-dev | sed -e 's/\"//g' > etc/.secrets/sp-cert.pem
	vault kv get --field=sp-key.pem -format=json $(SECRET_PATH)/ondemand-dev | sed -e 's/\"//g' > etc/.secrets/sp-key.pem
	# certs
	vault kv get --field=ondemand-dev.key -format=json $(SECRET_PATH)/ondemand-dev | sed -e 's/\"//g' > etc/.secrets/ondemand-dev.key
	vault kv get --field=ondemand-dev.crt -format=json $(SECRET_PATH)/ondemand-dev | sed -e 's/\"//g' > etc/.secrets/ondemand-dev.crt
	vault kv get --field=ondemand-dev.intermediates -format=json $(SECRET_PATH)/ondemand-dev | sed -e 's/\"//g' > etc/.secrets/ondemand-dev.intermediates

clean:
	rm -rf etc/.secrets
    
apply:
	kubectl apply -k .
