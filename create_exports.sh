#!/bin/bash
# CDOT tenant exports create script, boonstra@netapp.com 2015
# Load config values for the environment
source config.cfg
timestamp() {
        date +"%Y-%m-%d_%H-%M-%S"
}
LOG_FILE=log/${name}_crexplog.$(timestamp)
#fping -c1 -t300 $svmip 2>/dev/null 1>/dev/null
#if [ "$?" = 0 ]
#then
exec 3>&1 1>>${LOG_FILE} 2>&1
echo "########## $(timestamp) ##########" | tee /dev/fd/3
echo "SVM found creating volume ${volume} with size $size and export" 1>&3
ssh $user@$filer "export-policy create -vserver $name -policyname $volume"
wait
ssh $user@$filer "export-policy rule create -vserver $name -policyname $volume -clientmatch $gateway-255 -rorule none -rwrule any -allow-suid true -allow-dev true -ruleindex 1 -protocol nfs3 -superuser sys"
wait
ssh $user@$filer "vol create -vserver $name -volume $volume -aggregate $aggr -size $size -state online -type RW -policy $volume -unix-permissions 777"
#needs  -unix-permissions 777
wait
ssh $user@$filer "volume mount -vserver $name -volume ${volume} -junction-path /$volume -active true"
echo "Completed" 1>&3
echo "########## $(timestamp) ##########" | tee /dev/fd/3
echo "Any errors are listed below and in ${LOG_FILE}" 1>&3
cat $LOG_FILE |grep "failed" 1>&3
#else
#  echo "SVM not found, exit .....!"
#fi
