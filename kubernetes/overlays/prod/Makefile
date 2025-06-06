SECRET_PATH=secret/tid/sdf/ondemand/ondemand-dev
KUBECTL_DEPLOY_CONTEXT=ondemand

ensure-context:
	if [ '$(shell kubectl config current-context)' != $(KUBECTL_DEPLOY_CONTEXT) ]; then echo "Configured deployment context incorrect; expecting $(KUBECTL_DEPLOY_CONTEXT)."; exit 1; fi

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

apply: ensure-context secrets run-apply clean-secrets

enter-maintenance-mode:
	kubectl apply -f maintenance-mode-ingress.yaml

exit-maintenance-mode:
	kubectl apply -f ingress.yaml

diff: ensure-context secrets
	kubectl diff -k .
