# BACKUP SCRIPTS

Script para backups

**CASSANDRA** <br>
cassandra_netbackup.sh

```
Variáveis de ambiente:
$BKP_USERNAME (username)
$BKP_PASSWORD  (password)
```
<br>


**MONGODB**<br>

mongodump-manager.sh

```
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
```

<br>
crontab:

```
0 0 * * * mongodump-manager.sh mongodb-host1:27017,mongodb-host2:27017,mongodb-host3:27017 >/dev/null 2>&1
```

<br>
mongo-backup.sh



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
