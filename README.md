# Running an Apache Flink pipeline in [kind](https://github.com/kubernetes-sigs/kind)

This example uses the Flink Kubernetes operator developed by Lyft. prerequisites:
* Install [kind](https://github.com/kubernetes-sigs/kind)
* Run `deploy.sh`. This will: 
    * Recreate a kind cluster
    * Install a basic Kubernetes dashboard
    * Start `kubectl proxy`
    * Deploy the Flink operator
    * Deploy the example application

The script will output the token required to access the Kubernetes dashboard, which will be running in http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy. The Apache Flink web UI for the example application will be running in http://localhost:8001/api/v1/namespaces/flink-operator/services/wordcount-operator-example:8081/proxy

Enjoy!