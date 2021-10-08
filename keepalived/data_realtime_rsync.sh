#!/bin/bash
# File name:data_realtime_sync.sh
# File path: /opt/data_realtime_sync.sh

 set -x

src_dir="/vecps/offline-resources/common"  # 需要同步的源路径
dest_dir="/vecps/offline-resources/common" # 目标服务器上的路径
src_ip="172.19.35.93"                      # 源服务器
dest_ip="172.19.35.94"                     # 目标服务器
rsync_user=root                            # 同步的用户
rsync_pass="/etc/rsyncd/offline-resource_client.pass"

. /etc/init.d/functions

cd ${src_dir}
#此方法中，由于rsync同步的特性，这里必须要先cd到源目录，inotify再监听 ./ 才能rsync同步后目录结构一致
inotifywait -mrq -e modify,attrib,close_write,move,create,delete --format '%e %w%f' ./ |while read file;
# 把监控到有发生更改的"文件路径列表"循环
do
    INO_EVENT=$(echo $file | awk '{print $1}')  # 把inotify输出切割 把事件类型部分赋值给INO_EVENT
    INO_FILE=$(echo $file  | awk '{print $2}')  # 把inotify输出切割 把文件路径部分赋值给INO_FILE
    echo "-------------------------------$(date)------------------------------------"
    echo $file
    #增加、修改、写入完成、移动进事件
    #增、改放在同一个判断，因为他们都肯定是针对文件的操作，即使是新建目录，要同步的也只是一个空目录，不会影响速度。
    if [[ $INO_EVENT =~ 'CREATE' ]] || [[ $INO_EVENT =~ 'MODIFY' ]] || [[ $INO_EVENT =~ 'CLOSE_WRITE' ]] || [[ $INO_EVENT =~ 'MOVED_TO' ]];then
    for ip in ${dest_ip};
    do
      rsync -avzcRe --password-file=${rsync_pass} -e ssh -p 22 $(dirname ${INO_FILE}) ${rsync_user}@${dest_ip}:${dest_dir}
      #上面的rsync同步命令，源是用了$(dirname ${INO_FILE})变量 即每次只针对性的同步发生改变的文件的目录(只同步目标文件的方法在生产环境的某些极端环境下会漏文件 现在可以在不漏文件下也有不错的速度 做到平衡) 
      #然后用-R参数把源的目录结构递归到目标后面 保证目录结构一致性
    done
    fi
    #修改属性事件 指 touch chgrp chmod chown等操作
    if [[ $INO_EVENT =~ 'ATTRIB' ]];then
        if [ ! -d "$INO_FILE" ];then  
        # 如果修改属性的是目录 则不同步，因为同步目录会发生递归扫描，等此目录下的文件发生同步时，rsync会顺带更新此目录。
            for ip in ${dest_ip};do
                rsync -avzcRe  --password-file=${rsync_pass} -e ssh -p 22 $(dirname ${INO_FILE}) ${rsync_user}@${dest_ip}:${dest_dir}
        done
        fi
    fi
    #删除、移动出事件
    if [[ $INO_EVENT =~ 'DELETE' ]] || [[ $INO_EVENT =~ 'MOVED_FROM' ]];then
        for ip in ${dest_ip};do
            rsync -avzcRe --delete --password-file=${rsync_pass} -e ssh -p 22 $(dirname ${INO_FILE}) ${rsync_user}@${dest_ip}:${dest_dir}
            #直接同步已删除的路径${INO_FILE}会报no such or directory错误 ，并加上--delete来删除目标上有而源中没有的文件。
        done
    fi
done