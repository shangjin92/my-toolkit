## Etcd

《[提升ACK专有集群的etcd存储容量上限](https://help.aliyun.com/document_detail/151243.html)》

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

# 查询所有的Key
ETCDCTL_API=3 ./etcdctl --endpoints=https://172.20.0.15:2379,https://172.20.0.16:2379,https://172.20.0.8:2379 \
--cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
--key=/etc/kubernetes/pki/etcd/healthcheck-client.key \
--prefix --keys-only=true get /

# 性能压测
ETCDCTL_API=3 ./etcdctl --endpoints=https://172.20.0.15:2379,https://172.20.0.16:2379,https://172.20.0.8:2379 \
--cacert=/etc/kubernetes/pki/etcd/ca.crt \
--cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
--key=/etc/kubernetes/pki/etcd/healthcheck-client.key \
check perf --load="l"

# 清理磁盘碎片
ETCDCTL_API=3 ./etcdctl --endpoints=https://172.20.0.15:2379 \
--cacert=/etc/kubernetes/pki/etcd/ca.crt \
--cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
--key=/etc/kubernetes/pki/etcd/healthcheck-client.key \
defrag
```

```bash
# 提升Etcd IO调度优先级
ionice -c2 -n0 -p ${PID}
ionice -p ${PID}
```

```bash
# 获取 Etcd Metrics 指标数据
curl --cert /etc/kubernetes/pki/etcd/server.crt \
--key /etc/kubernetes/pki/etcd/server.key \
https://127.0.0.1:2379/metrics -k
```