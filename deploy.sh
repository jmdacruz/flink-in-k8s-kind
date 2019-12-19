#!/bin/bash

function check(){
    if [ "$?" -ne "0" ]; then
        exit 1
    fi
}

echo -e "\e[34mCreating kind cluster\e[39m"
kind delete cluster
kind create cluster --config kind.yml
check $?
echo -e "\e[34mDeploying Kubernetes dashboard\e[39m"
kubectl apply -f kubernetes-dashboard.yml
check $?

TOKEN=$(kubectl get secret $(kubectl get sa kubernetes-dashboard -n kubernetes-dashboard -o jsonpath='{.secrets[0].name}') -n kubernetes-dashboard -o jsonpath='{.data.token}' | base64 -d)
check $?

echo -e "\e[34mStarting kubectl proxy\e[39m"
pkill kubectl
nohup kubectl proxy > /dev/null &


echo -e "\e[34mKubernetes dashboard running on http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy using the following token:\e[39m"
echo -e "\e[34m$TOKEN\e[39m"

echo -e "\e[34mDeploying Flink operator\e[39m"
kubectl create -f https://raw.githubusercontent.com/lyft/flinkk8soperator/v0.3.0/deploy/crd.yaml
check $?
kubectl create -f https://raw.githubusercontent.com/lyft/flinkk8soperator/v0.3.0/deploy/namespace.yaml
check $?
kubectl create -f https://raw.githubusercontent.com/lyft/flinkk8soperator/v0.3.0/deploy/role.yaml
check $?
kubectl create -f https://raw.githubusercontent.com/lyft/flinkk8soperator/v0.3.0/deploy/role-binding.yaml
check $?
kubectl create -f flink/config.yml
check $?
# kubectl create -f https://raw.githubusercontent.com/lyft/flinkk8soperator/v0.3.0/deploy/flinkk8soperator.yaml
kubectl create -f flink/flinkk8soperator.yaml
check $?

echo -e "\e[34mDeploying Kafka cluster\e[39m"
kubectl create -f kafka/kafka.yml
check $?

echo -e "\e[34mWaiting for Zookeeper pod #0\e[39m"
kubectl wait --for=condition=ready pods/zookeeper-0 -n kafka-ns --timeout=120s
check $?
echo -e "\e[34mWaiting for Kafka pod #0\e[39m"
kubectl wait --for=condition=ready pods/kafka-0 -n kafka-ns --timeout=120s
check $?

echo -e "\e[34mSending some messages to topic 'test'\e[39m"
kubectl exec -ti kafka-0 -n kafka-ns -- kafka-console-producer.sh --broker-list kafka-0.kafka-headless.kafka-ns.svc.cluster.local:9092 --topic test < kafka/test.txt
echo -e "\e[34mReading some messages to topic 'test'\e[39m"
kubectl exec kafka-0 -n kafka-ns -- kafka-console-consumer.sh --bootstrap-server kafka-0.kafka-headless.kafka-ns.svc.cluster.local:9092 --topic test --from-beginning --timeout-ms 2000

# deploy example
echo -e "\e[34mDeploying Flink word count example\e[39m"
kubectl create -f flink/flink-operator-custom-resource.yaml
check $?

echo -e "\e[34mApache Flink UI running on http://localhost:8001/api/v1/namespaces/flink-operator/services/wordcount-operator-example:8081/proxy\e[39m"