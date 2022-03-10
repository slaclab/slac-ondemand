SECRET_PATH=secret/sdf/ondemand-dev

.PHONY: etc

etc:
	mkdir -p etc/.secrets

secrets: etc
	# auth
	vault kv get --field=htpasswd $(SECRET_PATH) > etc/.secrets/htpasswd
	vault kv get --field=ldap.password $(SECRET_PATH) > etc/.secrets/ldap.password
	vault kv get --field=oidc_client_id $(SECRET_PATH) > etc/.secrets/oidc_client_id
	vault kv get --field=oidc_client_secret $(SECRET_PATH) > etc/.secrets/oidc_client_secret
	vault kv get --field=oidc_crypto_passphrase $(SECRET_PATH) > etc/.secrets/oidc_crypto_passphrase
	vault kv get --field=sp-cert.pem $(SECRET_PATH) > etc/.secrets/sp-cert.pem
	vault kv get --field=sp-key.pem $(SECRET_PATH) > etc/.secrets/sp-key.pem
	# certs
	vault kv get --field=ondemand-dev.key $(SECRET_PATH) > etc/.secrets.key
	vault kv get --field=ondemand-dev.crt $(SECRET_PATH) > etc/.secrets.crt
	vault kv get --field=ondemand-dev.intermediates $(SECRET_PATH) > etc/.secrets.intermediates

clean:
	rm -rf etc/.secrets
    
apply:
	kubectl apply -k .
