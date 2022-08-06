## Ceph
### 1. 推荐配置
```bash
    [global]
    rgw_override_bucket_index_max_shards = 64
    rgw_lifecycle_work_time = 00:01-23:59
    rgw_gc_max_objs = 1000
    rgw_gc_obj_min_wait = 600
    rgw_gc_processor_max_time = 600
    rgw_max_concurrent_requests = 1024
    rgw_thread_pool_size = 1024
    mon_clock_drift_allowed = 2
    mon_clock_drift_warn_backoff = 30
    osd_pool_default_size = 3
    osd_pool_default_min_size = 1
    osd_op_thread_timeout = 60
    [osd]
    bluestore_bluefs_min = 10737418240
    bluestore_bluefs_min_free = 10737418240
    bluestore_bluefs_min_ratio = 0.2
    journal_max_write_bytes = 1073714824
    journal_max_write_entries = 10000
    journal_queue_max_ops = 50000
    journal_queue_max_bytes = 10485760000
    osd_max_write_size = 512
    osd_client_message_size_cap = 21474836648
    osd_deep_scrub_stride = 131072
    osd_op_threads = 8
    osd_disk_threads = 4
    osd_map_cache_size = 1024
    osd_map_cache_bl_size = 128
    osd_recovery_op_priority = 4
    osd_recovery_max_active = 10
    osd_max_backfills = 4
    osd_recovery_thread_timeout = 60
    osd_op_thread_suicide_timeout = 1000
```

### 2. 集群状态查看
```bash
# 查看集群状态，实时更新
ceph -w
# 查看存储池状态信息
rados df
# 获取 OSD 当前布局
ceph osd tree
# 查看 Ceph 状态
ceph status -f json
# 查看 mon 状态
ceph mon_status
# 查看mon状态
ceph mon stat
# 查询存储池
rados lspools
```

### 3. 查看Bucket内部对象
```bash
radosgw-admin bucket stats --bucket=test-bucket
rados ls -p default.rgw.buckets.index | grep -i a6412e72-4eb3-4ffb-bf2c-4ee4e9110fb3.24099.4
rados listomapkeys .dir.a6412e72-4eb3-4ffb-bf2c-4ee4e9110fb3.24099.4.1 -p default.rgw.buckets.index

# 查看pool下面的pg
ceph pg ls-by-pool ${pool_name}
# 查看pg下面的object
rados -p ${pg_name} ls
# 查看object内部的omap
rados -p ${poolname} listomapkeys ${object_name} | wc -l
rados -p ${poolname} listomapvals ${object_name} | more
rados -p ${poolname} stat ${object_name}
# 查看index存放的位置
ceph osd map ${poolname} ${object_name}
# 查看 bucket 实例信息
radosgw-admin metadata list bucket.instance
```

### 4. 集群配置
```bash
# 配置、运行状态和计数器的报告
ceph report

# 查看默认ceph配置
ceph --show-config

# 查看现有OSD配置（Rook-OSD 先执行 unset CEPH_ARGS）
ceph daemon osd.0 config show
ceph daemon /var/run/ceph/4f86e68c-f03c-11ec-bfe2-00163e1ab553/ceph-osd.0.asok config show

# 查看mon配置
ceph daemon mon.ceph-node1 config show
# 更新配置
ceph daemon ${OSD_ADMIN_SOCKET} config set bluestore_cache_size_hdd 536870912

# 查看OSD内存占用
unset CEPH_ARGS
ceph daemon osd.0 dump_mempools
ceph daemon /var/run/ceph/4f86e68c-f03c-11ec-bfe2-00163e1ab553/ceph-osd.0.asok dump_mempools
```

### 5. OSD Full 
```bash
# 先解除osd full的限制，使集群恢复正常
ceph osd unset full

# 集群状态正常之后，再重新设置full ratio
ceph osd set-nearfull-ratio <float[0.0-1.0]>
ceph osd set-full-ratio <float[0.0-1.0]>
ceph osd set-backfillfull-ratio <float[0.0-1.0]>
```

### 6. 关闭rebalance
```bash
# 关闭rebalance
sudo ceph osd set noout
sudo ceph osd set norebalance

# 之后可以执行关机、下线节点等操作
sudo reboot

# 查看集群状态，看数据是否有rebalance
sudo ceph -s

# 等待节点重新上线

# 重新开启rebalance
sudo ceph osd unset noout
sudo ceph osd unset norebalance
```
