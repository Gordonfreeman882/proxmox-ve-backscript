#!/bin/bash

#Variablen
remotefolder=/var/lib/vz/dump
part=/your/local/folder
localfolder=/your/local/folder
ip=ip-address
logpath=/your/local/folderlogfile/logfile.txt
password=canbecleartext-orpathtofile
hashwertremote=0
hashwertlocal=1
dobackup=1
localspace=0
remotespace=1
#Funktionen
logfile () {
  cd /home/gordon/Test
  if [ -d /home/gordon/Test/logfile ]
  then
    echo "is here"
  else
    echo "no there"
    mkdir -p logfile
  fi
  echo "-------------------------" >> $logpath
  date >> $logpath
}

inettest() {
  inet=$(ping -c3 $ip | grep -i 0% >/dev/null && echo JA || echo Nein)
  if [ $inet = "JA" ]
  then
    echo "Host verfügbar" >> $logpath
  else
    echo "Ping nicht erfolgreich !WARN!" >> $logpath
  fi
}

needed() {
  echo "Pruefe Hashwertlokal" >> $logpath
  if [ -d $part ]
  then
    hashwertlocal=$(ls -a $part | md5sum)
    echo $hashwertlocal >> $logpath
  else
    echo "no there"
    mkdir -p $localfolder
  fi
  echo "Prüfe Hashwertremote" >> $logpath
  #sshpass -p $password ssh -o StrictHostKeyChecking=no root@$ip "cd $remotefolder && ls -a | md5sum"
  hashwertremote=$(sshpass -p $password ssh -o StrictHostKeyChecking=no root@$ip "cd $remotefolder && ls -a | md5sum")
  echo $hashwertremote >> $logpath
  hashwertremote=${hashwertremote%?}
  hashwertlocal=${hashwertlocal%?}
  if [ $hashwertlocal = $hashwertremote ]
  then
    dobackup=0
  else
    dobackup=1
  fi
}

backup () {
  if  [ $dobackup = 1 ]
  then
    date "+%x %X starte Backup" >> $logpath
    cd $part
    md5sum * > /tmp/filelist.txt
    ssh root@$ip "cd $remotefolder && md5sum * > /tmp/fileslist.txt"
    scp root@$ip:/tmp/fileslist.txt /tmp/
    diff /tmp/fileslist.txt /tmp/filelist.txt > /tmp/diff.txt
    cat /tmp/diff.txt | while read line; do echo ${line:34} >> /tmp/backup.txt; done;
    cat /tmp/backup.txt | while read line; do sshpass -p $password scp root@$ip:/var/lib/vz/dump/$line $localfolder; echo "Download" $line >> $logpath; done
    date "+%x %X beende Backup" >> $logpath
  else
    echo "Scheinbar alles auf dem neusten Stand" >> $logpath
  fi
}

harddrivespace(){
  localspace=$(df -h | grep RAID5 | awk '{ print $4 }')
  remotespace=$(sshpass -p $password ssh -o StrictHostKeyChecking=no root@$ip "du -sh $remotefolder" | awk '{print $1 }')
  echo $localspace >> $logpath
  echo $remotespace >> $logpath
  calcremotespace=$(sshpass -p $password ssh -o StrictHostKeyChecking=no root@$ip "du -sh $remotefolder" | awk '{print $1 }' | grep T >/dev/null && JA || echo Nein)
  if [ $calcremotespace = "JA" ]
  then
    remotespace=${remotespace%?}
    echo $remotespace
    remotespace=${remotespace*1000}
    echo $remotespace
  else
    echo "OK" >/dev/null
  fi
  if [ $localspace -lt $remotespace ]
  then
    echo "Speicherplatz auf NAS zu gering" >> $logpath
    exit 0
  else
    echo "Speicherplatz auf NAS ausreichend" >> $logpath
 fi
}
#Main
logfile
inettest
harddrivespace
needed
backup
