# DPOD Setup

//add SOMA port to sts deployment
kubectl patch sts r284938edb5-dynamic-gateway-service --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/ports/-", "value": {"containerPort": 5550, "name": soma-port, "protocol" : TCP}}]' -n apic

//add SOMA port to service
kubectl patch service r284938edb5-dynamic-gateway-service-ingress --type='json' -p='[{"op": "add", "path": "/spec/ports/-", "value": {"name": "soma-mgmt", "port": 5550, "protocol": "TCP", "targetPort": 5550}}]' -n apic

//add ingress entry
kubectl apply -f /Users/ozairs/Apps/datapower/kubernetes/dp-soma-k8.yml

//add Web GUI port
kubectl patch sts r284938edb5-dynamic-gateway-service --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/ports/-", "value": {"containerPort": 5550, "name": soma-port, "protocol" : TCP}}]' -n apic

kubectl patch service r284938edb5-dynamic-gateway-service-ingress --type='json' -p='[{"op": "add", "path": "/spec/ports/-", "value": {"name": "web-mgmt", "port": 9090, "protocol": "TCP", "targetPort": 9090}}]' -n apic

kubectl apply -f /Users/ozairs/Apps/datapower/kubernetes/dp-webgui-k8.yml