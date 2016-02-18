#!/bin/bash
# CDOT tenant SVM create script, boonstra@netapp.com 2015
# assumes ssh-keys are setup between host/storage
# assumes ssh-keys are setup between host/storage
# Load config values for the environment
source config.cfg
# Define a timestamp function
timestamp() {
        date +"%Y-%m-%d_%H-%M-%S"
}
LOG_FILE=log/${name}_rmlog.$(timestamp)
read -r -p "Are you sure ? this will remove all data for $name and all local backups [y/N] " response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]
then

exec 3>&1 1>>${LOG_FILE} 2>&1
echo "########## $(timestamp) ##########" | tee /dev/fd/3
echo "Removing Networking" 1>&3
ssh $user@$filer "subnet delete -subnet-name $name -ipspace ${name}_ipspace"
echo "Removing SVM" 1>&3
ssh $user@$filer "vserver stop -vserver $name"
wait
ssh $user@$filer "set diag; volume offline -vserver $name -volume ${name}_root -foreground true -force true"
wait
ssh $user@$filer "set diag; volume delete -vserver $name -volume ${name}_root -foreground true"
wait
ssh $user@$filer "set diag; vserver delete $name "
wait
ssh $user@$filer "broadcast-domain delete -broadcast-domain $name -ipspace ${name}_ipspace"
ssh $user@$filer "ipspace delete -ipspace ${name}_ipspace"
ssh $user@$filer "vlan delete -node $node1 -vlan-name $lif-$vlan"
ssh $user@$filer "vlan delete -node $node2 -vlan-name $lif-$vlan"
echo "Removal of ${name} Completed" 1>&3
echo "########## $(timestamp) ##########" | tee /dev/fd/3
echo "Any errors are listed below and in ${LOG_FILE}" 1>&3
cat $LOG_FILE |grep "failed" 1>&3

else
 echo "Aborting .......!"
fi
