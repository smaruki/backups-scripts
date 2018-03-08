#!/bin/bash

# Variables
MYSQLDUMP="/usr/bin/mysqldump"
HOST="$1"
#BKP_USERNAME='' ENVIRONMENT
#BKP_PASSWORD='' ENVIRONMENT
BKP_DIR="/backups"
BKP_TMP="$BKP_DIR/$HOST.sql"
BKP_NAME="$HOST-$(date +%F-%H%M%S)"
LOG_DIR="/var/log/mysqlBackup"
PID_FILE="/var/run/mysqlBackup-$HOST.pid"
NUM_DUMPS="50"
NUM_LOGS="60"

# Functions
log() {
    echo "$(date +%F) $(date +%H%M) | $@" >> $LOG_DIR/$(hostname).$(date +%F).log
}

log_begin() {
    log "--------------------- Backup Begin ---------------------"
}

log_end() {
    log "--------------------- Backup End ----------------------"
}

create_dir() {
    if [ ! -d "$1" ]; then
        mkdir -p $1
        log "$1 directory was created"
    fi
}

pidfile_check() {
    if [ -e $PID_FILE ]; then
        log "mysqlBackup $PID_FILE already running. Leaving."
        log_end
        exit
    fi
}

pidfile_create() {
    pidfile_check
    echo $$ > $PID_FILE
    log "Pidfile was created."
}

pidfile_remove() {
    rm -rf $PID_FILE
    log "Pidfile was removed."
}

dump_cleanup() {
    rm -rf $BKP_TMP
    log "Uncompressed dump was cleaned"
}

is_running() {
    if [ $(pgrep $1 | wc -l) -ne 0 ]; then
        dump_cleanup
        log "$1 is running. Leaving."
        pidfile_remove
        log_end
        exit
    fi
}

dump() {
    log "Running mysqldump"
    $MYSQLDUMP -h $HOST -u $BKP_USERNAME -p$BKP_PASSWORD --all-databases  > $BKP_TMP
    if [ $? -eq 0 ]; then
        log "mysqldump completed successfully"
    else
        dump_cleanup
        log "mysqldump failed"
        pidfile_remove
        log_end
        exit
    fi
}

dump_compress() {
    is_running tar
    tar czf $BKP_DIR/$BKP_NAME.tar.gz $BKP_TMP
    log "Dump compression completed successfully"
}

dump_cleanup_old() {
    if [ $(ls -d1rt $BKP_DIR/*.tar.gz | head -n -$NUM_DUMPS | wc -l) -gt 0 ]; then
        log "Old dumps files:"
        for i in $(ls -d1rt $BKP_DIR/*.tar.gz | head -n -$NUM_DUMPS); do
            log "$i"
        done
        ls -d1rt $BKP_DIR/*.tar.gz | head -n -$NUM_DUMPS | xargs rm
        log "Old dumps was cleaned successfully"
    else
        log "No old dumps found"
    fi
}

log_cleanup_old() {
    if [ $(ls -d1rt $LOG_DIR/*.log | head -n -$NUM_LOGS | wc -l) -gt 0 ]; then
        log "Old log files:"
        for i in $(ls -d1rt $LOG_DIR/*.log | head -n -$NUM_LOGS); do
            log "$i"
        done
        ls -d1rt $LOG_DIR/*.log | head -n -$NUM_LOGS | xargs rm
        log "Old logs was cleaned successfully"
    else
        log "No old logs found"
    fi
}

# Main
create_dir $LOG_DIR     # Create log directory
log_begin               # Begin log transaction
pidfile_create          # Creating Pidfile
create_dir $BKP_TMP     # Create backup directory
dump_cleanup            # Cleanup uncompressed dump (if exists)
dump                    # Begin mysqldump for all dbs
dump_compress           # Compressing dumped databases
dump_cleanup            # Cleanup uncompressed dump
#dump_cleanup_old       # Cleanup old compressed dump (1 Day Old)
log_cleanup_old         # Cleanup old logs
pidfile_remove          # Removing Pidfile
log_end                 # End log transaction
