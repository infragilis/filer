#!/bin/bash
# CDOT tenant SVM create script, boonstra@netapp.com 2015
#more info needs to go here
# Load config values for the environment
source config.cfg
timestamp() {
        date +"%Y-%m-%d_%H-%M-%S"
}
LOG_FILE=log/${name}_crlog.$(timestamp)

exec 3>&1 1>>${LOG_FILE} 2>&1
echo "########## $(timestamp) ##########" | tee /dev/fd/3
echo "Creating basic network stack" 1>&3
ssh $user@$filer "network ipspace create ${name}_ipspace"
wait
ssh $user@$filer "broadcast-domain create -broadcast-domain $name -mtu 9000 -ipspace ${name}_ipspace"
wait
ssh $user@$filer "subnet create -subnet-name $name -broadcast-domain $name -subnet $subnet -ipspace ${name}_ipspace -gateway $gateway"
echo "Creating SVM"
ssh $user@$filer "vserver create -vserver ${name} -subtype default -rootvolume ${name}_root -aggregate $aggr  -rootvolume-security-style unix -language C.UTF-8 -snapshot-policy default -is-repository false -comment name -ipspace ${name}_ipspace -quota-policy  $name"
wait
echo "Configuring SVM ${name}" 1>&3
ssh $user@$filer "vol modify -vserver $name -volume ${name}_root -autosize true"
ssh $user@$filer "vserver services dns create -vserver $name -domains $domain -name-servers $dnsip -state enabled -timeout 2 -attempts 1"
wait
ssh $user@$filer "vserver remove-protocols -vserver $name -protocols cifs,fcp,iscsi,ndmp"
wait
ssh $user@$filer "vserver nfs modify  -vserver $name -showmount enabled"
wait
ssh $user@$filer "vserver nfs on -vserver $name"
wait
#kb44598
ssh $user@filer "set diag; nfs modify -vserver $name -v3-fsid-change disabled"


echo "Attaching vlan $vlan to SVM ${name}" 1>&3
ssh $user@$filer "vlan create -node $node1 -vlan-name $lif-$vlan"
wait
ssh $user@$filer "vlan create -node $node2 -vlan-name $lif-$vlan"
wait
ssh $user@$filer "broadcast-domain add-ports -broadcast-domain $name -ports $node1:$lif-$vlan  -ipspace ${name}_ipspace"
wait
ssh $user@$filer "broadcast-domain add-ports -broadcast-domain $name -ports $node2:$lif-$vlan  -ipspace ${name}_ipspace"
wait
ssh $user@$filer "network interface create -vserver $name -lif $name-$vlan -role data -data-protocol nfs -home-node $node1 -home-port $lif-$vlan -address $svmip -netmask $netmask -status-admin up -failover-policy system-defined -firewall-policy data -auto-revert true  -force-subnet-association"
wait
echo "Creating snapshot policies" 1>&3
ssh $user@$filer "snapshot policy create -policy ${name}_daily_keep7 -enabled true -schedule1 daily -count1 7 -vserver $name"
ssh $user@$filer "snapshot policy create -policy ${name}_hourly_keep24 -enabled true -schedule1 hourly -count1 24 -vserver $name"
ssh $user@$filer "snapshot policy create -policy ${name}_daily_keep30 -enabled true -schedule1 daily -count1 30 -vserver $name"
# change the default export policy
ssh $user@$filer "export-policy rule modify -vserver $name -policyname default -ruleindex 1 -protocol nfs3 -clientmatch $subnet -rorule sys -rwrule sys -anon 65534 -superuser any -allow-suid true"
#create volume
echo "Creating volume/export ${volume}" 1>&3
ssh $user@$filer "export-policy create -vserver $name -policyname $volume"
wait
ssh $user@$filer "export-policy rule create -vserver $name -policyname $volume -clientmatch $subnet -rorule none -rwrule any -allow-suid true -allow-dev true -ruleindex 1 -protocol nfs3 -superuser sys"
wait
ssh $user@$filer "vol create -vserver $name -volume $volume -aggregate $aggr -size $size -state online -type RW -policy $volume -autosize true -space-guarantee none -snapshot-policy ${name}_daily_keep7"
wait
ssh $user@$filer "volume mount -vserver $name -volume $volume -junction-path /${volume} -active true"
#create another volume
echo "Creating volume/export ${volume1}" 1>&3
ssh $user@$filer "export-policy create -vserver $name -policyname $volume1"
wait
ssh $user@$filer "export-policy rule create -vserver $name -policyname $volume1 -clientmatch $subnet -rorule none -rwrule any -allow-suid true -allow-dev true -ruleindex 1 -protocol nfs3 -superuser sys"
wait
ssh $user@$filer "vol create -vserver $name -volume $volume1 -aggregate $aggr -size $size -state online -type RW -policy $volume1 -autosize true -space-guarantee none -snapshot-policy ${name}_hourly_keep24"
wait
ssh $user@$filer "volume mount -vserver $name -volume $volume1 -junction-path /${volume1} -active true "
#create another volume
echo "Creating volume/export ${volume2}" 1>&3
ssh $user@$filer "export-policy create -vserver $name -policyname $volume2"
wait
ssh $user@$filer "export-policy rule create -vserver $name -policyname $volume2 -clientmatch $subnet -rorule none -rwrule any -allow-suid true -allow-dev true -ruleindex 1 -protocol nfs3 -superuser sys"
wait
ssh $user@$filer "vol create -vserver $name -volume $volume2 -aggregate $aggr -size $size -state online -type RW -policy $volume2 -autosize true -space-guarantee none -snapshot-policy ${name}_hourly_keep24"
wait
ssh $user@$filer "volume mount -vserver $name -volume $volume2 -junction-path /${volume2} -active true"
wait
# set snap autodelete
echo "Configuring snapshot autodelete on volumes" 1>&3
ssh $user@$filer "snapshot autodelete modify -vserver $name -volume ${name}_root -enabled true"
ssh $user@$filer "snapshot autodelete modify -vserver $name -volume $volume -enabled true"
ssh $user@$filer "snapshot autodelete modify -vserver $name -volume $volume1 -enabled true"
ssh $user@$filer "snapshot autodelete modify -vserver $name -volume $volume2 -enabled true"
echo "Completed" 1>&3
echo "########## $(timestamp) ##########" | tee /dev/fd/3
echo "Any errors are listed below and in ${LOG_FILE}" 1>&3
cat $LOG_FILE |grep "failed"
