#!/bin/bash

USER="root"
PASSWORD="PaSsWoRd"
OUTPUT="/var/www/backup"
GITDIR="OUTPUT/.git"
DBS=`mysql --user=$USER --password=$PASSWORD --skip-column-names -e "SHOW DATABASES;" | tr -d "| "`
SERVICES=( cron.d logrotate.d monit nginx)
EXCLUDES=( 'information_schema')
NUM_EXCLUDES=${#EXCLUDES[@]}
DATE=`date +%Y%m%d`

function chk-output-dir {
  if [ ! -d $OUTPUT/$outputdir ]; then
      mkdir -p $OUTPUT/$outputdir;
  fi
}

function chk-git-dir {
  if [ ! -d $GITDIR ]; then
      git=1
#      echo "Git exist"
    else
      git=0
#      echo "Git not exist"
  fi
}

function backup-mysql {
  for db in $DBS; do
    skip=0
    count=0
    while [ $count -lt $NUM_EXCLUDES ] ; do
      if [ "$db" = ${EXCLUDES[$count]} ] ; then
        skip=1
      fi
      count=$((count+1))
    done

    if [ $skip -eq 0 ] ; then
          mysqldump --force --opt --user=$USER --password=$PASSWORD --databases $db > $OUTPUT/mysql/$db.sql
    fi
  done
}

function backup-conf {
  for index in ${!SERVICES[*]}; do
    outputdir=/conf/${SERVICES[$index]}
    chk-output-dir
    mount --bind /etc/${SERVICES[$index]} $OUTPUT/$outputdir
  done
}

function umount-output {
  for index in ${!SERVICES[*]}; do
    umount $OUTPUT/conf/${SERVICES[$index]}
  done
}

function git-push {
  cd $OUTPUT
  git add *
  git commit -m "Commit date $DATE"
#  git push -u origin master
}

function main {
  outputdir=mysql
  chk-output-dir
  outputdir=conf
  chk-output-dir
  backup-mysql
  backup-conf
  chk-git-dir
  if [ $git ]; then
    git-push
  fi
  umount-output
}

main
