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

### 5. moby-buildkit
docker 构建迁移到 [buildkit](https://github.com/moby/buildkit), 并发提速, 且支持更丰富的定制化能力。

### 6. 查看容器日志
```bash
docker logs ${ContainerId} > docker.log
```

如果上述方法无法持久化保存，采用下面方法：
```bash
docker logs ${ContainerId} >& docker.log
```

### 7. 容器无法启动
可能是无法识别启动命令，可以把双引号内的启动命令改成通过脚本启动。