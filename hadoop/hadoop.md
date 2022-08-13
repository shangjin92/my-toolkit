## Hadoop
### 1. 按时间删除文件
```bash
hadoop fs -ls -R /tmp/test/ | \
  grep -i "/tmp/test/yyyy" | \
  awk -v tStart="2022-05-15 18:00" '(!/^d/) && (($6" "$7) >= tStart)' | \
  sort -k6,7 | \
  awk -F ' ' '{print $8}' |  xargs hadoop fs -rm -skipTrash
```

### 2. webport
```bash
curl http://172.1.1.0:50070/jmx\?qry\=Hadoop:service\=NameNode,name\=NameNodeStatus
```