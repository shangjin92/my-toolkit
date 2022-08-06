## PostgreSQL
### 1. 删除指定schema下所有的表
```sql
DO $$ DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'test-schema') LOOP
        EXECUTE 'DROP TABLE IF EXISTS "test-schema".' || quote_ident(r.tablename) || ' CASCADE';
    END LOOP;
END $$;
```

### 2. 删除指定schema下所有的sequence
```sql
SELECT 'drop sequence ' || sequence_name::text || ';'
FROM information_schema.sequences
WHERE sequence_schema = 'test-schema';
```

### 3. 删除function
```sql
drop function "add_index"(text, text, text);
```

### 4. 删除完全一样的记录
```sql
DELETE FROM dupes a
WHERE a.ctid <> (SELECT min(b.ctid)
                 FROM   dupes b
                 WHERE  a.key = b.key);
```

### 5. 解锁数据库
```sql
SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE datname='test-db' AND pid<>pg_backend_pid();
```

```sql
SELECT * FROM pg_stat_activity WHERE datname='死锁的数据库名';
--- 检索出来的字段中，【wating 】字段，数据为t的那条，就是死锁的进程，找到对应的【pid 】列的值。

--- 这种方式只能kill select查询，对update、delete 及DML不生效
SELECT pg_cancel_backend(PID);

--- 这种可以kill掉各种操作(select、update、delete、drop等)操作。
SELECT pg_terminate_backend(PID);
```

### 6. 清除PG XLog
https://github.com/digoal/blog/blob/master/201702/20170216_01.md?spm=ata.13261165.0.0.56fe2db0EZu9D8&file=20170216_01.md
```bash
# 找到 Latest checkpoint's REDO WAL file
pg_controldata $PGDATA 

pg_archivecleanup -d $PGDATA/pg_xlog 00000001000000010000000E  
```

### 7. 推荐内核参数
```bash
vi /etc/sysctl.conf  
         
fs.aio-max-nr = 1048576                
fs.file-max = 76724600                

# 可选：kernel.core_pattern = /data01/corefiles/core_%e_%u_%t_%s.%p                         
# /data01/corefiles 提前建好，权限777，如果是软链接，对应的目录修改为777。       

kernel.sem = 4096 2147483647 2147483646 512000                    
# 信号量, ipcs -l 或 -u 查看，每16个进程一组，每组信号量需要17个信号量。                

kernel.shmall = 107374182                      
# 所有共享内存段相加大小限制 (建议内存的80%)，单位为页。                
kernel.shmmax = 274877906944                   
# 最大单个共享内存段大小 (建议为内存一半), 大于9.2的版本已大幅降低共享内存的使用，单位为字节。                
kernel.shmmni = 819200                         
# 一共能生成多少共享内存段，每个PG数据库集群至少2个共享内存段。

net.core.netdev_max_backlog = 10000                
net.core.rmem_default = 262144                       
# The default setting of the socket receive buffer in bytes.                
net.core.rmem_max = 4194304                          
# The maximum receive socket buffer size in bytes                
net.core.wmem_default = 262144                       
# The default setting (in bytes) of the socket send buffer.                
net.core.wmem_max = 4194304                          
# The maximum send socket buffer size in bytes.                
net.core.somaxconn = 4096                
net.ipv4.tcp_max_syn_backlog = 4096                
net.ipv4.tcp_keepalive_intvl = 20                
net.ipv4.tcp_keepalive_probes = 3                
net.ipv4.tcp_keepalive_time = 60                
net.ipv4.tcp_mem = 8388608 12582912 16777216                
net.ipv4.tcp_fin_timeout = 5                
net.ipv4.tcp_synack_retries = 2                
net.ipv4.tcp_syncookies = 1                    
# 开启SYN Cookies。当出现SYN等待队列溢出时，启用cookie来处理，可防范少量的SYN攻击。                
net.ipv4.tcp_timestamps = 1                    
# 减少time_wait。
net.ipv4.tcp_tw_recycle = 0                    
# 如果=1则开启TCP连接中TIME-WAIT套接字的快速回收，但是NAT环境可能导致连接失败，建议服务端关闭它。
net.ipv4.tcp_tw_reuse = 1                      
# 开启重用。允许将TIME-WAIT套接字重新用于新的TCP连接。
net.ipv4.tcp_max_tw_buckets = 262144                
net.ipv4.tcp_rmem = 8192 87380 16777216                
net.ipv4.tcp_wmem = 8192 65536 16777216                

net.nf_conntrack_max = 1200000                
net.netfilter.nf_conntrack_max = 1200000                

vm.dirty_background_bytes = 409600000                       
#  系统脏页到达这个值，系统后台刷脏页调度进程 pdflush（或其他） 自动将(dirty_expire_centisecs/100）秒前的脏页刷到磁盘。                
#  默认为10%，大内存机器建议调整为直接指定多少字节。                

vm.dirty_expire_centisecs = 3000                             
#  大于这个值的脏页，将被刷到磁盘。3000表示30秒。                
vm.dirty_ratio = 95                                          
#  如果系统进程刷脏页太慢，使得系统脏页超过内存 95 % 时，则用户进程如果有写磁盘的操作（如fsync、fdatasync等调用），则需要主动把系统脏页刷出。                
#  有效防止用户进程刷脏页，在单机多实例，并且使用CGROUP限制单实例IOPS的情况下非常有效。                  

vm.dirty_writeback_centisecs = 100                            
#  pdflush（或其他）后台刷脏页进程的唤醒间隔， 100表示1秒。                

vm.swappiness = 0                
#  不使用交换分区。                

vm.mmap_min_addr = 65536                
vm.overcommit_memory = 0                     
#  在分配内存时，允许少量over malloc, 如果设置为 1, 则认为总是有足够的内存，内存较少的测试环境可以使用 1。

vm.overcommit_ratio = 90                     
#  当overcommit_memory = 2 时，用于参与计算允许指派的内存大小。                
vm.swappiness = 0                            
#  关闭交换分区。                
vm.zone_reclaim_mode = 0                     
# 禁用 numa, 或者在vmlinux中禁止。            
net.ipv4.ip_local_port_range = 40000 65535                    
# 本地自动分配的TCP, UDP端口号范围。                
fs.nr_open=20480000                
# 单个进程允许打开的文件句柄上限。                

# 以下参数请注意。            
#vm.extra_free_kbytes = 4096000   # 小内存机器不要设置这样大, 会无法开机。
#vm.min_free_kbytes = 6291456    # vm.min_free_kbytes 建议每32G内存分配1G vm.min_free_kbytes。     
# 如果是小内存机器，以上两个值不建议设置。                
# vm.nr_hugepages = 66536                    
#  建议shared buffer设置超过64GB时 使用大页，页大小 /proc/meminfo Hugepagesize。                
#vm.lowmem_reserve_ratio = 1 1 1                
# 对于内存大于64G时，建议设置，否则建议默认值 256 256 32。    
```

### 8. 推荐PG配置
```bash
listen_addresses = '0.0.0.0'      
port = 3433  # 监听端口      
max_connections = 2000  # 最大允许的连接数      
superuser_reserved_connections = 10      
unix_socket_directories = '.'      
unix_socket_permissions = 0700      
tcp_keepalives_idle = 60      
tcp_keepalives_interval = 60      
tcp_keepalives_count = 10      
shared_buffers = 16GB                  # 共享内存，建议设置为系统内存的1/4  .      
maintenance_work_mem = 512MB           # 系统内存超过32G时，建议设置为1GB。超过64GB时，建议设置为2GB。超过128GB时，建议设置为4GB。      
work_mem = 64MB                        # 1/4 主机内存 / 256 (假设256个并发同时使用work_mem)    
wal_buffers = 128MB                    # min( 2047MB, shared_buffers/32 )     
dynamic_shared_memory_type = posix      
vacuum_cost_delay = 0      
bgwriter_delay = 10ms      
bgwriter_lru_maxpages = 500      
bgwriter_lru_multiplier = 5.0      
effective_io_concurrency = 0      
max_worker_processes = 128                     
max_parallel_workers_per_gather = 16        # 建议设置为主机CPU核数的一半。      
max_parallel_workers = 16                   # 看业务AP和TP的比例，以及AP TP时间交错分配。实际情况调整。例如 主机CPU cores-2    
wal_level = replica      
fsync = on      
synchronous_commit = off      
full_page_writes = on                  # 支持原子写超过BLOCK_SIZE的块设备，在对齐后可以关闭。或者支持cow的文件系统可以关闭。    
wal_writer_delay = 10ms      
wal_writer_flush_after = 1MB      
checkpoint_timeout = 30min      
max_wal_size = 32GB                    # shared_buffers*2     
min_wal_size = 8GB                     # max_wal_size/4     
archive_mode = always      
archive_command = '/bin/date'      
hot_standby = on    
max_wal_senders = 10      
max_replication_slots = 10      
wal_receiver_status_interval = 1s      
max_logical_replication_workers = 4      
max_sync_workers_per_subscription = 2      
random_page_cost = 1.2      
parallel_tuple_cost = 0.1      
parallel_setup_cost = 1000.0      
min_parallel_table_scan_size = 8MB      
min_parallel_index_scan_size = 512kB      
effective_cache_size = 32GB                 # 建议设置为主机内存的5/8。         
log_destination = 'csvlog'      
logging_collector = on      
log_directory = 'log'      
log_filename = 'postgresql-%a.log'      
log_truncate_on_rotation = on      
log_rotation_age = 1d      
log_rotation_size = 0      
log_min_duration_statement = 5s      
log_checkpoints = on      
log_connections = on                            # 如果是短连接，并且不需要审计连接日志的话，建议OFF。    
log_disconnections = on                         # 如果是短连接，并且不需要审计连接日志的话，建议OFF。    
log_error_verbosity = verbose      
log_line_prefix = '%m [%p] '      
log_lock_waits = on      
log_statement = 'ddl'      
log_timezone = 'PRC'      
log_autovacuum_min_duration = 0       
autovacuum_max_workers = 5      
autovacuum_vacuum_scale_factor = 0.1      
autovacuum_analyze_scale_factor = 0.05      
autovacuum_freeze_max_age = 1000000000      
autovacuum_multixact_freeze_max_age = 1200000000      
autovacuum_vacuum_cost_delay = 0      
statement_timeout = 0                                # 单位ms, s, min, h, d.  表示语句的超时时间，0表示不限制。      
lock_timeout = 0                                     # 单位ms, s, min, h, d.  表示锁等待的超时时间，0表示不限制。      
idle_in_transaction_session_timeout = 2h             # 单位ms, s, min, h, d.  表示空闲事务的超时时间，0表示不限制。      
vacuum_freeze_min_age = 50000000      
vacuum_freeze_table_age = 800000000      
vacuum_multixact_freeze_min_age = 50000000      
vacuum_multixact_freeze_table_age = 800000000      
datestyle = 'iso, ymd'      
timezone = 'PRC'      
lc_messages = 'en_US.UTF8'      
lc_monetary = 'en_US.UTF8'      
lc_numeric = 'en_US.UTF8'      
lc_time = 'en_US.UTF8'      
default_text_search_config = 'pg_catalog.simple'      
shared_preload_libraries='pg_stat_statements,pg_pathman'      
```
