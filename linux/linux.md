## Linux

### 1. Go 程序性能分析
* 通过go pprof 查看Go程序的调用性能分析 
* 通过 perf + FlameGraph 来抓取分析火焰图，找出来系统调用的瓶颈。 
* 通过 bpftrace 来抓取分析内核事件的调用次数，对应上一步定位出来的慢调用事件。 
* 通过 strace 来分析进程的行为

### 2. docker 开启 go pprof
1）编辑 `/etc/systemd/system/docker.service`，找到 `ExecStart=/usr/bin/dockerd`，在其后添加 `-D -H tcp://127.0.0.1:2375`。

2） 添加完后执行 `systemctl daemon-reload && systemctl restart docker`
Debug模式打开后，执行 `go tool pprof 127.0.0.1:2375`，此时pprof会采集30s的应用CPU指标，并会将本次采集到的数据保存一份在本地。

3） 直接用 `go tool pprof -http 127.0.0.1:1999 <pb.gz文件>` 在浏览器看问题。

### 3. 挂载数据盘
```bash
fdisk -l

fdisk mkfs.ext4
mkfs.ext4 /dev/vdb

vim /etc/fstab
/dev/vdb /home/tmp    ext4    defaults        1 1

mount -a
df -h
```

### 4. perf 火焰图
```bash
# 采集10s的数据后，会在当前目录下生成perf.data文件，抓到后还需要用下面命令将其转换一下。
perf record -F 99 -a -g -- sleep 10;
perf script > out.perf

git clone https://github.com/brendangregg/FlameGraph.git && cd FlameGraph

# 然后再用下面命令生成火焰图
./stackcollapse-perf.pl ../out.perf > ./out.folded \
      && ./flamegraph.pl ./out.folded > ./test.svg
```

### 5. tcpdump
```bash
tcpdump -i eth0 -n host xxx.xxx and port 80 -w test.cap
tcpdump -i eth0 -n src 192.168.1.13330 or src 192.168.9.39

tcpdump -A -nn -vvv -s0 host xxx > tmpfile

tcpdump -i eth0 tcp port 3003 -n -X -s 1500 -w test.pcap
tcpdump -i eth0 tcp port 3003 and ip host 172.16.251.77 -n -X -s 1500 -w test1.pcap

# 对抓取到的包进行rotate，最多可以写200个20 MB的.pcap文件
tcpdump -i any host <业务Pod IP或Ingress Pod IP> -C 20 -W 200 -w /tmp/ingress.pcap
```

### 6. Wireshark
```sql
--- 查找重传的包
tcp.analysis.retransmission

--- 过滤重传的包
tcp and !tcp.analysis.retransmission

--- 过滤来源
ip.src == 192.168.9.187 and ip.dst == 192.168.9.188

--- 过滤package number
frame.number == 17

--- 查找syn包
tcp.flags.syn == 1
--- 查找ack包
tcp.flags.ack == 1
--- 查找fin包
tcp.flags.fin == 1
--- 查找rst包
tcp.flags.reset == 1

--- 过滤端口
tcp.port == 80
tcp.port == 80 or udp.port == 80

--- 过滤协议
tcp
udp
arp
icmp
http
smtp
ftp
dns
msnms
ip
ssl
oicq
bootp

--- 排除arp包
!arp 或者 not arp

--- http模式过滤
http.request.method == "GET"
http.request.method == "POST"
http.request.uri == "/img/logo-edu.gif"
http contains "GET"
http contains "HTTP/1."
http.request.uri matches ".gif"

--- 显示包含TCP标志的封包
tcp.flags
--- 显示包含TCP SYN标志的封包
tcp.flags.syn == 0x02
tcp.window_size == 0 && tcp.flags.reset != 1

--- 过滤windows size为0的case
tcp.analysis.zero_window
    
--- TCP包中的“win=”代表接收窗口的大小，即表示这个包的发送方当前还有多少缓存区可以接收数据。
--- 当Wireshark在一个包中发现“win=0”时，就会给它打上“TCP zero window”的标志，
--- 表示缓存区已满，不能再接受数据了。

--- 查看自己接收缓冲区是否满
tcp.analysis.zero_window

--- 查看对方缓冲区是否满
tcp.analysis.window_full

--- 过滤重传数据包：
tcp.analysis.retransmission
tcp.analysis.fast_retransmission

--- wireshark把第一次重传包分类为out of order 类型,可以通过tcp.analysis.out_of_order过滤，如果第二次重传，分类为fast retransmission
--- 过滤出包，再用Follow TCP Streamy就可以把失败过程显示出来

--- 过滤出所有超过200毫秒的tcp连接确认
tcp.analysis.ack_rtt > 0.2 and tcp.len ==0

frame.number >= 10 && frame.number < 15

tcp.seq = xxx

--- 握手请求被对方拒绝
(tcp.flags.reset == 1) && (tcp.seq == 1)

--- 过滤出重传的握手请求
(tcp.flags.syn == 1) && (tcp.analysis.retransmission)

--- 查看SYN总数量的统计：Analyze -> Expert Info -> Chats
```

### 7. 短连接性能优化
```bash
# 查看网络连接分布
netstat -n | awk '/^tcp/ {++state[$NF]} END {for(key in state) print key,"\t",state[key]}'   

# 如果存在大量的TIME_WAIT，检查reuse是否开启。
sysctl -a |grep reuse

# 使用短链接常用的调优内核参数
echo 20480 > /proc/sys/net/core/somaxconn; 
echo 204800 > /proc/sys/net/ipv4/tcp_max_syn_backlog; 
echo 30 > /proc/sys/net/ipv4/tcp_keepalive_time; 
echo '1024 60000' > /proc/sys/net/ipv4/ip_local_port_range; 
echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse; 
```

### 8. 判断端口是否被限制
```bash
yum -y install nmap
nc -l 6443

# 查看是否收到connect日志
nc -zv 192.168.1.23 6443
```

### 9. 通过ksniff在Pod内部抓包
```bash
kubectl krew install sniff
```

### 10. nethogs 查看进程占用带宽
```bash
yum -y install libpcap-devel gcc gcc-c++ ncurses-devel

wget https://github.com/raboof/nethogs/archive/refs/tags/v0.8.6.tar.gz
tar -zxvf v0.8.6.tar.gz
make && make install

./nethogs eth0
```

### 11. ab
```bash
yum install -y httpd-tools

# 在目标机器上，启动一个http服务
docker run -p 80:80 -itd nginx

# 在另一台机器上，运行 ab 命令
# -c 表示并发请求数为 1000，-n 表示总的请求数为 10000
$ ab -c 1000 -n 10000 http://192.168.1.1/
```

### 12. iperf
```bash
yum install iperf3

# 在目标机器上启动 iperf 服务端
# -s 表示启动服务端，-i 表示汇报间隔，-p 表示监听端口
iperf3 -s -i 1 -p 10000

# 在另一台机器上运行 iperf 客户端，运行测试
# -c 表示启动客户端，192.168.0.30 为目标服务器的 IP
# -b 表示目标带宽 (单位是 bits/s)
# -t 表示测试时间# -P 表示并发数，-p 表示目标服务器监听端口
$ iperf3 -c 192.168.77.131 -b 1G -t 15 -P 2 -p 10000
Connecting to host 192.168.77.131, port 10000
[  4] local 192.168.77.130 port 47044 connected to 192.168.77.131 port 10000
[  6] local 192.168.77.130 port 47046 connected to 192.168.77.131 port 10000
[ ID] Interval           Transfer     Bandwidth       Retr  Cwnd
[  4]   0.00-1.00   sec   117 MBytes   985 Mbits/sec  207    990 KBytes       
[  6]   0.00-1.00   sec   115 MBytes   965 Mbits/sec   99   1.11 MBytes       
[SUM]   0.00-1.00   sec   233 MBytes  1.95 Gbits/sec  306             
- - - - - - - - - - - - - - - - - - - - - - - - -
...
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-15.00  sec  1.74 GBytes   995 Mbits/sec  268             sender
[  4]   0.00-15.00  sec  1.74 GBytes   995 Mbits/sec                  receiver
[  6]   0.00-15.00  sec  1.74 GBytes   995 Mbits/sec  175             sender
[  6]   0.00-15.00  sec  1.74 GBytes   995 Mbits/sec                  receiver
[SUM]   0.00-15.00  sec  3.47 GBytes  1.99 Gbits/sec  443             sender
[SUM]   0.00-15.00  sec  3.47 GBytes  1.99 Gbits/sec                  receiver

iperf Done.

# 最后的 SUM 行就是测试的汇总结果，包括测试时间、数据传输量以及带宽等。按照发送和接收，这一部分又分为了 sender 和 receiver 两行。
```

### 13. ss
```bash
ss -nlt
ss -ant

# 显示TCP连接
ss -t -a

#显示 Sockets 摘要
ss -s

#列出当前的established, closed, orphaned and waiting TCP sockets
ss -l

#查看进程使用的socket
ss - pl

#显示所有UDP Sockets
ss -u -a

# 显示所有状态为Established的HTTP连接
ss -o state established '( dport = :http or sport = :http )'

# 列举出处于 FIN-WAIT-1状态的源端口为 80或者 443，目标网络为 193.233.7/24所有 tcp套接字
ss -o state fin-wait-1 '( sport = :http or sport = :https )' dst 193.233.7/24

#用TCP 状态过滤Sockets
ss -4 state closing

#匹配远程地址和端口号
ss dst 192.168.119.113

#将本地或者远程端口和一个数比较
ss sport eq :22
ss dport \> :1024
```

### 14. sar
```bash
# sar命令在这里可以查看网络设备的吞吐率。
# 在排查性能问题时，可以通过网络设备的吞吐量，判断网络设备是否已经饱和。
sar -n DEV 1

# 显示 TCP 的统计数据
sar -n TCP,ETCP 1
```

### 15. traceroute
```bash
# traceroute是用来检测发出数据包的主机到目标主机之间所经过的网关数量的工具。
# traceroute的原理是试图以最小的TTL（存活时间）发出探测包来跟踪数据包到达目标主机所经过的网关，
# 然后监听一个来自网关ICMP的应答，发送数据包的大小默认为38个字节。
traceroute -w 1 www.baidu.com
```

### 16. iptables/ipvs
```bash
# 查看iptables规则
iptables-save 
iptables-save | uniq -c | sort -rg | head

# 查看iptables nat规则
iptables -t nat -nL

# iptables规则目的IP是外机时，需要设置 /proc/sys/net/ipv4/ip_forward = 1
```

```bash
# 查看ipvs规则
ipvsadm -Ln

# 查看指定的IP+Port的ipvs规则
ipvsadm -Ln -t 127.0.0.1:32116 --stats

# ipvs 的超时时间限制
ipvsadm -l --timeout
```

### 17. netstat
```bash
# 查看是否有丢包
netstat -s | grep -E 'overflow|drop'
# 查看丢包计数值
netstat -az | grep -E 'TcpExtListenOverflows|TcpExtListenDrops'

# 查看网络的内核事件
nstat -saz

# 查看是否阻塞
netstat -antup | awk '{if($2>100||$3>100){print $0}}'
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
tcp     2066     36 9.134.55.160:8000       10.35.16.97:63005       ESTABLISHED 1826655/nginx

# 查看是否有 UDP buffer 满导致丢包
# 使用 netstat 查看统计
$ netstat -s | grep "buffer errors"
    429469 receive buffer errors
    23568 send buffer errors
 
# 也可以用 nstat 查看计数器
$ nstat -az | grep -E 'UdpRcvbufErrors|UdpSndbufErrors'
UdpRcvbufErrors                 429469                 0.0
UdpSndbufErrors                 23568                  0.0

# 查看TCP
nstat -az | grep TcpExtTCPRcvQDrop
TcpExtTCPRcvQDrop               264324                  0.0
```
### 18. 格式化裸盘
```bash
dmsetup remove ceph--xxxxxx

mkfs /dev/sdx

dd if=/dev/zero of=/dev/sdx bs=1M status=progress
```

### 19. perf stat
```bash
perf stat -e branch-misses,bus-cycles,cache-misses,cache-references,cpu-cycles,instructions,L1-dcache-load-misses,L1-dcache-loads,L1-dcache-store-misses,L1-dcache-stores,L1-icache-load-misses,L1-icache-loads,branch-load-misses,branch-loads,dTLB-load-misses,iTLB-load-misses  -a -p 61238

# 采集10秒内所有CPU的运行状态
# IPC < 1.0 多半意味着访存密集型，IPC > 1.0 多半意味着计算密集型。
perf stat -a -- sleep 10
```

### 20. iptables forward
```bash
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -F
```