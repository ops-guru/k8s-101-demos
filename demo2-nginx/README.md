kubectl apply -f nginx.yaml
kubectl apply -f service.yaml

localhost:3001 in browser


> kubectl run nginx --image nginx
> kubectl describe pod nginx-<...>
> kubectl get deployment

Optional:
kubectl run kuard --image=levep79/kuar-demo
kubectl port-forward kuard-84f7dcd6cb-hfqkj 8080:8080

show them yaml/json under the hood:
kubectl get deployment nginx -o yaml

delete pod of nginx, show the student that new pod created - remind them about Deployment -> replicaSet
kubectl delete pod nginx-7db9fccd9b-w8hfj
kubectl scale deployment/nginx --replicas 5 # ANTON TODO
kubectl get pods
kubectl  get rs
kubectl describe rs

