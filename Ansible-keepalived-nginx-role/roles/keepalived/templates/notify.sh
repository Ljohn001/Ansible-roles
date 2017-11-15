#!/bin/bash
#
vip=192.168.0.100
contact='root@localhost'

notify() {
        mailsubject="`hostname` to be $1: vip floating"
        mailbody="`date '+%F %H:%M:%S'`: vrrp transition, `hostname` changed to be $1"
        echo $mailbody | mail -s "$mailsubject" $contact
}

case "$1" in
        master)
                notify master
                exit 0
        ;;
        backup)
                notify backup
                exit 0
        ;;
        fault)
                notify fault
                exit 0
        ;;
        *)
                echo 'Usage: `basename $0` {master|backup|fault}'
                exit 1
        ;;
esac
