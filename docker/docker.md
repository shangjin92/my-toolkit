## Docker
### 1. 无需sudo运行docker
```bash
sudo setfacl -m user:$USER:rw /var/run/docker.ssock
```

### 2. insecure-registry
```bash
修改 /etc/docker/daemon.json
{
    "insecure-registries": ["registry.domain.com"]
}
```

### 3. 查看Docker子网网段
```bash
docker network inspect bridge
```

### 4. 查看Docker容量占用情况
```bash
docker system df
```