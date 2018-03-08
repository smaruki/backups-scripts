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
mongo-backup.sh

```
Variáveis de ambiente:
$BKP_USERNAME (username)
$BKP_PASSWORD  (password)

BKP_DIR (Diretório de backup)
LOG_DIR (Diretório de log)
NUM_DUMPS (Número de dumps mantidos)
NUM_LOGS (Número de logfiles mantidos)

Ex.:
mongo-backup.sh prd-mongodb-01 prd-mongodb-02 prd-mongodb-03
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
