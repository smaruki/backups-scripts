#!/bin/bash
NODETOOL=/bin/nodetool
CQLSH=/bin/cqlsh
BACKUP_DIR=/var/lib/cassandra/data

$CQLSH $(hostname) -u $BKP_USERNAME -p $BKP_PASSWORD -e "describe schema" > $BACKUP_DIR/schema.cqlsh

$NODETOOL ring -r | egrep -v 'Datacenter|Address|Warning|To|Note' | awk '{print $1 " " $8}' > $BACKUP_DIR/nodes_tokens.txt

$NODETOOL flush
