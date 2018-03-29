#!/bin/bash
#
# Smaruki
# 2018
# Create dump files of MongoDB

# Hostname or list of hosts from replicaset
# HOSTS="127.0.0.1:27017,127.0.0.1:27018,127.0.0.1:27019"
HOSTS=$1

# Username and password to backup, keep empty to noauth
# roles: [ { role: "backup", db: "admin" }, {role:"restore", db: "admin" } ]})
BKP_USERNAME=""
BKP_PASSWORD=""

# Number of dumpfiles to keep in the directory
NUM_DUMPS=60

# Set where database backups will be stored
BACKUP_PATH="/backups"


# mongodump --host "127.0.0.1:27017" --readPreference secondaryPreferred --gzip --archive=localhost_2018-03-29-153400.gz
# mongorestore --host "127.0.0.1" --gzip --archive=localhost_2018-03-29-153400.gz

# First hostname from $HOSTS
# Ex: localhost:27017 returns localhost
HOSTNAME=$(echo $HOSTS | cut -d ':' -f 1)

##############################################################################
# Changing the variables below is not recommended.
##############################################################################

MONGODUMP="$(which mongodump)"
PIDFILE="/var/run/mongodump-manager-$HOSTNAME.pid"
LOGFILE="/var/log/mongodump-manager.log"

# Size in bytes - default 50MB
MAX_LOG_SIZE=52428800
DATE_NAME="$(date +%F-%H%M)"
DUMPFILE="$BACKUP_PATH/$HOSTNAME-$DATE_NAME.gz"

# Log
log() {
    echo "$(date +%FT%T) | $@" >> $LOGFILE
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
        $MONGODUMP --host=$HOSTS -u $BKP_USERNAME -p $BKP_PASSWORD --readPreference=secondaryPreferred --gzip --archive=$DUMPFILE --quiet
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
    if [ $(wc -c < "$LOGFILE") -ge $MAX_LOG_SIZE ]; then
        NEW_LOGFILE="$LOGFILE.$DATE_NAME"
        mv $LOGFILE $NEW_LOGFILE
        log "LOGFILE $NEW_LOGFILE rotation"
    fi
}


# Creating log directory
create_dir $BACKUP_PATH

# Rotate logfiles with more than MAX_LOG_SIZE
logrotate

# Creating pidfile
pidfile_create

# Executing mongodump
mongodump_replicaset

# Cleaning old files
dumpfile_cleanup

# Removing pidfile
pidfile_remove
