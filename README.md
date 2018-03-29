# BACKUP SCRIPTS

Script para backups

**MONGODB**<br>

mongodump-manager.sh
<br>
Dump MongoDB database by saving to a specific directory.
It generates execution log and dump status log and can be integrated with monitoring tools like Zabbix or Grafana.

```
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
```

<br>
crontab:

```
0 0 * * * mongodump-manager.sh mongodb-host1:27017,mongodb-host2:27017,mongodb-host3:27017 >/tmp/host1.log
```

<br>
Restore archive file generated:

```
mongorestore --host "mongodb-host1:27017" --gzip --archive=mongodb-host1-2018-01-15-153400.gz
```

<br>
Check Dumps failed of the day
```
cat /var/log/mongodump-manager/mongodump-status.log | grep $(date +%F) | grep "FAILED"
```

<br>

**CASSANDRA** <br>
cassandra_netbackup.sh

```
Variáveis de ambiente:
$BKP_USERNAME (username)
$BKP_PASSWORD  (password)
```

<br>

**MYSQL / MARIADB**<br>
mysql-backup.sh

```
Variáveis de ambiente:
$BKP_USERNAME (username)
$BKP_PASSWORD  (password)

BKP_DIR (Diretório de backup)
LOG_DIR (Diretório de log)
NUM_DUMPS (Número de dumps mantidos)
NUM_LOGS (Número de logfiles mantidos)

Ex.:
mysql-backup.sh prd-mysqldb-01
```
<br>
