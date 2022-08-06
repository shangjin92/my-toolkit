## Kubernetes
### 1. Aliyun ACK 网络异常排查
* DNS https://help.aliyun.com/document_detail/404754.html
* Nginx Ingress Controller https://help.aliyun.com/document_detail/405072.html
* LoadBalancer Service https://help.aliyun.com/document_detail/403618.html

### 2. nsenter 切换 namespace
```bash
# kubectl get pods coredns-79989b94b6-d8kqn -o wide -n kube-system
# docker ps |grep coredns-79989b94b6-d8kqn
# docker inspect -f {{.State.Pid}} 1285db52efdd
2606

# 切换ns的命令 nsenter 依赖 util-linux
# yum -y install util-linux.x86_64

# 进入到对应容器的network ns里面，并指向ip a查看ip
# nsenter --target 2606 -n
# ifconfig

# exit
logout
```

### 3. 扩容 etcd
https://help.aliyun.com/document_detail/151243.html
```bash
# 查看etcd状态
ETCDCTL_API=3 etcdctl --endpoints=https://192.168.1.138:2379,https://192.168.1.139:2379,https://192.168.1.140:2379 \
      --cacert=/var/lib/etcd/cert/ca.pem \
      --cert=/var/lib/etcd/cert/etcd-client.pem \
      --key=/var/lib/etcd/cert/etcd-client-key.pem endpoint health

# 查看etcd详细状态，表输出
ETCDCTL_API=3 etcdctl --endpoints=https://192.168.1.138:2379,https://192.168.1.139:2379,https://192.168.1.140:2379 \
      --cacert=/var/lib/etcd/cert/ca.pem \
      --cert=/var/lib/etcd/cert/etcd-client.pem \
      --key=/var/lib/etcd/cert/etcd-client-key.pem --write-out=table endpoint status      

# 查看etcd报警
ETCDCTL_API=3 etcdctl --endpoints=https://192.168.1.138:2379,https://192.168.1.139:2379,https://192.168.1.140:2379 \
      --cacert=/var/lib/etcd/cert/ca.pem \
      --cert=/var/lib/etcd/cert/etcd-client.pem \
      --key=/var/lib/etcd/cert/etcd-client-key.pem alarm list
```

### 4. 性能优化
https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/
* --kube-api-burst
* --kube-api-qps

https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/
* --max-mutating-requests-inflight
* --max-requests-inflight

### 5. Memory QOS
* https://cloud.tencent.com/developer/article/1846831
* https://github.com/kubernetes/enhancements/blob/master/keps/sig-node/2570-memory-qos/README.md

### 6. ApiServer 限流
https://kubernetes.io/zh/docs/concepts/cluster-administration/flow-control/

### 7. 设置节点不可调度
```bash
# 设置节点不可调度
kubectl cordon k8s-node1

# 设置节点可调度
kubectl uncordon k8s-node1
```

### 8. kubespray 安装集群
https://github.com/kubernetes-sigs/kubespray

### 9. coredns 过滤规则
```bash
template IN A xxx.service {
  match .*\.xxx.service
  answer "{{ .NAME }} 60 IN A 10.1.1.1"
  fallthrough
}

template ANY AAAA {
  rcode NXDOMAIN
}
```
### 10. 保留有问题的Pod进行Debug
```bash
kubectl label --overwrite pods xxx-deployment-56f7bb9889-c72zj "app=xxx-bak" -n my-namespace
```

### 11. 时区挂载
```yaml
spec:
  containers:
  - name: app
    volumeMounts:
    - name: host-time
      mountPath: /etc/localtime

    env:
    - name: TZ
      value: Asia/Shanghai

  volumes:
  - name: host-time
    hostPath:
      path: /etc/localtime
```

### 12. 清除Evicted Pod
```bash
kubectl get pods --all-namespaces -ojson | jq -r '.items[] | select(.status.reason!=null) | select(.status.reason | contains("Evicted")) | .metadata.name + " " + .metadata.namespace' | xargs -n2 -l bash -c 'kubectl delete pods $0 --namespace=$1'
```

### 13. 设置固定Pod IP
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
  labels:
    app: myapp
  annotations:
    cni.projectcalico.org/ipAddrs: "["10.1.1.1"]"
spec:
  containers:
  - name: myapp-container
    image: busybox
    command: ['sh', '-c', 'echo Hello Kubernetes! && sleep 3600']
```

### 14. 清除节点资源
```bash
kubeadm reset

systemctl stop kubelet
systemctl stop docker
rm -rf /var/lib/cni/
rm -rf /var/lib/kubelet/*
rm -rf /etc/cni/
ifconfig cni0 down
ifconfig flannel.1 down
ifconfig docker0 down
ip link delete cni0
ip link delete flannel.1

systemctl start docker
```

### 15. 开启和关闭Master调度
```bash
# 开启master调度
kubectl taint nodes --all node-role.kubernetes.io/master-

# 关闭master调度
kubectl taint nodes ${k8s-master-node-name} node-role.kubernetes.io/master=:NoSchedule
```

### 16. 获取安装镜像列表
```bash
kubeadm config images list --kubernetes-version=v1.15.3

#!/bin/sh
for image in `kubeadm config images list --kubernetes-version=$1`
do
  image_name=`echo ${image} | sed "s/k8s.gcr.io.//g"`
  docker pull "${image}"
  docker tag "${image}" "${image_name}"
  file_name="${image_name}.tgz"
  docker save "${image_name}" | gzip > "${file_name}"
  docker rmi "${image}"
  docker rmi "${image_name}"
done
```

### 17. 获取所有注册namespace scope资源
```bash
kubectl api-resources --namespaced=true --verbs=delete

kubectl get apiservice
```

### 18. 自动补齐命令
```
brew install yum install
yum install -y bash-completion

source /usr/share/bash-completion/bash_completion

echo "source <(kubectl completion bash)" >> ~/.bashrc
```

### 19. 更改默认namespace
```bash
kubectl config set-context --current --namespace=default
```
