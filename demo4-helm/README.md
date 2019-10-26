https://github.com/helm/charts/tree/master/stable/tomcat

Initiate the helm 
helm delete my-releasehelm init

list all the available helm modules
helm search 

To install tomcat webserver please run
helm install --name my-release stable/tomcat
show tomcat installed,
show configuration options,
show templates used by chart
delete chart:
helm delete my-release

