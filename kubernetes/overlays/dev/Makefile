SECRET_PATH=secret/tid/sdf/ondemand/ondemand-dev

secrets: 
	mkdir -p etc/.secrets
	set -e; for i in ondemand-dev.key ondemand-dev.crt ondemand-dev.intermediates; do vault kv get --field=$$i $(SECRET_PATH) > etc/.secrets/$$i ; done

clean-secrets:
	rm -rf etc/.secrets
    
run-apply:
	kubectl apply -k .

run-kustomize:
	kubectl kustomize .

dump: secrets run-kustomize clean-secrets

apply: secrets run-apply clean-secrets
