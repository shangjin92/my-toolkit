#!/bin/sh

run() {
    echo
    echo "-----------------run $@------------------"
    timeout 10s $@
    if [ "$?" != "0" ]; then
        echo "failed to collect info: $@"
    fi
    echo "------------End of ${1}----------------"
}

while :
do
    # Memory usage: sudo top -b -p ${PID} -n1 | sed -n '8p' | awk '{printf $10}'
    cpu_usage=`top -b -n1 | sed -n '3p' | awk '{printf $2}'`
    cpu_usage=${cpu_usage//$'\n'}

    result=$(bc -l <<<"${cpu_usage} >= 40.1")
    if [[ $result == "1" ]];then
        current=`date "+%Y-%m-%d-%H:%M:%S"`
        log_path="/tmp"

        run top -b -n1 -c | tee -a ${log_path}/${current}.log
        run ps -ef | tee -a ${log_path}/${current}.log
        run netstat -apnt | tee -a ${log_path}/${current}.log
        run netstat -s | tee -a ${log_path}/${current}.log
        run sar -u 1 5 | tee -a ${log_path}/${current}.log
        run mpstat -P ALL | tee -a ${log_path}/${current}.log
        run sar -r 1 5 | tee -a ${log_path}/${current}.log
        run sar -n DEV 1 5 | tee -a ${log_path}/${current}.log
        run iostat -xm 1 5 | tee -a ${log_path}/${current}.log
    fi

    find ${log_path}/ -mtime +3 -type f -name "*.log" -exec rm -f {} \;

    sleep 15
done
