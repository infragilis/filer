#!/bin/bash
# CDOT vol delete script (grabs top 5 volumes, deletes), boonstra@netapp.com 2015
# assumes ssh-keys are setup between host/storage
# Load config values for the environment
source config.cfg
# Define a timestamp function
read -r -p "Are you sure ? this will remove all data for $name and all local volume backups [y/N] " response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]
then

ssh $user@$filer "vol show -vserver $name" >vol.tmp
sed '1,2d' vol.tmp > vol1.tmp
wait
awk '!/display/' vol1.tmp > vol2.tmp
awk '!/root/' vol2.tmp > vol3.tmp
awk '{print $2}' vol3.tmp >vol.txt
rm *.tmp
set -- $(<vol.txt)
echo "deleting ...  $@"
ssh $user@$filer "set diag; volume offline -vserver $name -volume $1 -foreground true -force true"
ssh $user@$filer "set diag; volume offline -vserver $name -volume $2 -foreground true -force true"
ssh $user@$filer "set diag; volume offline -vserver $name -volume $3 -foreground true -force true"
ssh $user@$filer "set diag; volume offline -vserver $name -volume $4 -foreground true -force true"
ssh $user@$filer "set diag; volume offline -vserver $name -volume $5 -foreground true -force true"
wait
ssh $user@$filer "set diag; volume unmount -vserver $name -volume $1 "
ssh $user@$filer "set diag; volume unmount -vserver $name -volume $2 "
ssh $user@$filer "set diag; volume unmount -vserver $name -volume $3 "
ssh $user@$filer "set diag; volume unmount -vserver $name -volume $4 "
ssh $user@$filer "set diag; volume unmount -vserver $name -volume $5 "
wait
ssh $user@$filer "set diag; volume delete -vserver $name -volume $1 -foreground true"
ssh $user@$filer "set diag; volume delete -vserver $name -volume $2 -foreground true"
ssh $user@$filer "set diag; volume delete -vserver $name -volume $3 -foreground true"
ssh $user@$filer "set diag; volume delete -vserver $name -volume $4 -foreground true"
ssh $user@$filer "set diag; volume delete -vserver $name -volume $5 -foreground true"
wait
ssh $user@$filer "export-policy delete -vserver $name -policyname $1"
ssh $user@$filer "export-policy delete -vserver $name -policyname $2"
ssh $user@$filer "export-policy delete -vserver $name -policyname $3"
ssh $user@$filer "export-policy delete -vserver $name -policyname $4"
ssh $user@$filer "export-policy delete -vserver $name -policyname $5"
rm vol.txt
else
 echo "Aborting .......!"
fi
