#!/bin/bash
#set -x
get_ip() {
        IP=`ifconfig | grep -w inet | grep -v "127.0.0.1" | awk '{ print $2}'| tr -d "addr" |awk  'NR==1'`
        echo ${IP#*:}
}

# Registry health_check
  echo "execution time: $(date "+%Y-%m-%d %H:%M:%S")"
  HTTP_ADDR="https://$(get_ip)/v2/"
  STATUS_CODE=$(curl -k --connect-timeout 5 --write-out "%{http_code}\n" --silent --output /dev/null ${HTTP_ADDR})
  [ $STATUS_CODE -ne 200 ] && echo "[ERROR]: http connection error: ${HTTP_ADDR} -1" || echo "[INFO]: http connection is ok: ${HTTP_ADDR} 0"