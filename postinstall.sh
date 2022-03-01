#!/bin/bash
#Monitoring Stack Kurulumu

#Helm Kurulumu
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

#namespace olusturulmasi
kubectl create ns monitoring

#ingress controller ve prometheus monitoring stack için repo eklenmesi
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add nginx-stable https://helm.nginx.com/stable
helm repo update

#helm chart ile monitoring stack kurulumu
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring

#ingress controller için proje oluşturulması
kubectl create ingress-nginx

#helm ile ingress controller kurulumu, burada hostnetwork kullanılarak daemonset modeli ile ingress kurulumu sağlanır.
helm install ingress-nginx nginx-stable/nginx-ingress --set controller.kind=daemonset --set controller.hostNetwork=true --set controller.metrics.enabled=true --set controller.metrics.serviceMonitor.additionalLabels.release="prometheus" --set controller.metrics.serviceMonitor.enabled=true -n ingress-nginx

#Burada farklı kontroller konabilir, if ile ingress podların ready state de olduğu görülür gibi, basitce podlarin ayağa kalkması için 2 dk delay koyuyorum.
sleep 120

#prometheus için ingress  oluşturulması
#sonrasında dns ve ya hosts dosyasinda prometheus.example.com url in kubernetes worker node a gitmesi için tanım yapılması gerekir. 
cat <<EOF > ingress-prometheus-stack.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-prometheus
  namespace: monitoring
  annotations:
spec:
  ingressClassName: nginx
  rules:
  - host: prometheus.example.com
    http:
      paths:
      - pathType: Prefix
        path: "/"
        backend:
          service:
            name: prometheus-kube-prometheus-prometheus
            port:
              number: 9090
EOF


kubectl create -f ingress-prometheus-stack.yaml


