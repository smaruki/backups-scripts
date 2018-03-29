#!/bin/bash
#
# Smaruki
# 2018
# Dump MongoDB database by saving to a specific directory.
# It generates execution log and dump status log and can be integrated with monitoring tools.

# Username and password to backup, keep empty to noauth
# roles: [ { role: "backup", db: "admin" }, {role:"restore", db: "admin" } ]})
BKP_USERNAME=""
BKP_PASSWORD=""

# Number of dumpfiles to keep in the directory
NUM_DUMPS=60

# Set where database backups will be stored
BACKUP_PATH="/backups"

# Log path to logfiles
LOG_PATH="/var/log/mongodump-manager"

# Size in bytes - default 50MB
MAX_LOG_SIZE=52428800

# mongodump --host "127.0.0.1:27017" --readPreference secondaryPreferred --gzip --archive=localhost_2018-03-29-153400.gz
# mongorestore --host "127.0.0.1" --gzip --archive=localhost_2018-03-29-153400.gz

##############################################################################
# Changing the variables below is not recommended.
##############################################################################

# Hostname or list of hosts from replicaset
# HOSTS="127.0.0.1:27017,127.0.0.1:27018,127.0.0.1:27019"
HOSTS=$1

# First hostname from $HOSTS
# Ex: localhost:27017 returns localhost
HOSTNAME=$(echo $HOSTS | cut -d ':' -f 1)

MONGODUMP="$(which mongodump)"

# pid file
PIDFILE="/var/run/mongodump-manager-$HOSTNAME.pid"

# log files
LOGFILE="$LOG_PATH/mongodump-manager.log"
LOGFILE_HOST_DUMP="$LOG_PATH/$HOSTNAME.log"
LOGFILE_STATUS="$LOG_PATH/mongodump-status.log"

DATE_NAME="$(date +%F-%H%M)"
DUMPFILE="$BACKUP_PATH/$HOSTNAME-$DATE_NAME.gz"

# Log
log() {
    echo "$(date +%FT%T) | $@" >> $LOGFILE
}


catlog_status() {
    echo "$(date +%FT%T) $@" >> $LOGFILE_STATUS
}


create_dir() {
    if [ ! -d "$1" ]; then
        mkdir -p $1
        log "DIR $1 was created"
    fi
}


pidfile_create() {
    pidfile_check
    echo $$ > $PIDFILE
    log "PIDFILE $PIDFILE was created."
}


pidfile_check() {
    if [ -e $PIDFILE ]; then
        log "PIDFILE $PIDFILE already running. Leaving."
        exit
    fi
}


pidfile_remove() {
    rm -f $PIDFILE
    log "PIDFILE $PIDFILE was removed."
}


mongodump_replicaset() {
    log "MONGODUMP starting host $HOSTNAME to $DUMPFILE"

    if [ "$USERNAME" != "" -a "$PASSWORD" != "" ]; then
        $MONGODUMP --host=$HOSTS -u $BKP_USERNAME -p $BKP_PASSWORD --readPreference=secondaryPreferred --gzip --archive=$DUMPFILE
    else
        $MONGODUMP --host=$HOSTS --readPreference=secondaryPreferred --gzip --archive=$DUMPFILE
    fi

    if [ $? -eq 0 ]; then
        log "MONGODUMP done dumping $DUMPFILE successfully"
    else
        log "MONGODUMP $DUMPFILE failed"
        pidfile_remove
        exit
    fi
}


dumpfile_check() {
    if [ $(ls $DUMPFILE | wc -l) -gt 0 ]; then
        log "DUMPFILEFILE $DUMPFILE persisted"
        catlog_status "SUCCESS $HOSTNAME"
    else
        catlog_status "FAILED $HOSTNAME"
    fi
}


dumpfile_cleanup() {
    if [ $(ls -d1rt $BACKUP_PATH/*.gz | head -n -$NUM_DUMPS | wc -l) -gt 0 ]; then
        log "DUMPFILE cleanup"
        for i in $(ls -d1rt $BACKUP_PATH/*.gz | head -n -$NUM_DUMPS); do
            log "DUMPFILE old files $i"
        done
        ls -d1rt $BACKUP_PATH/*.gz | head -n -$NUM_DUMPS | xargs rm
        log "DUMPFILE was cleaned successfully"
    else
        log "DUMPFILE no old files"
    fi
}


logrotate() {
    if [ $(wc -c < "$1") -gt $MAX_LOG_SIZE ]; then
        NEW_FILENAME="$1.$DATE_NAME"
        mv $1 $NEW_FILENAME
        log "LOGFILE $NEW_FILENAME rotation"
    fi
}


# Creating log directory
create_dir $BACKUP_PATH
create_dir $LOG_PATH

# Rotate logfiles with more than MAX_LOG_SIZE
logrotate $LOGFILE
logrotate $LOGFILE_STATUS

# Creating pidfile
pidfile_create

# Executing mongodump
mongodump_replicaset

# Check dump persisted in disk and set catolog-status
dumpfile_check

# Cleaning old files
dumpfile_cleanup

# Removing pidfile
pidfile_remove
