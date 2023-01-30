#!/bin/bash
# Site backup for CentOS SSH CLI
# HINT! This file contains DB access credentials and must be kept secure
# --- Backup config settings ---

# Source configuration 
BACKUPID="site.name"
BACKUPDIR="/home/public_html"
WORKDIR="/home/tmp"
DBNAME="database"
DBUSER="db_username"
DBPASS="SeCrEt_PaSsWoRd"

# Destination configuration
FTPHOST="ftp.hostname.org"
FTPPORT="21"
FTPUSER="ftp_username"
FTPPASS="FtP_PaSsWoRd"

# ---   Checking connection with FTP ---
ping -c 1 -t 60 $FTPHOST > /dev/null
if [ $? -eq 0 ]; then
    echo "$FTPHOST is online, proceeding with backup."
else 
    echo "$FTPHOST is down. Try again later."
	exit
fi

# --- Preparing local backup folder ---
# if folder exists, clean it from archives
# if folder does not exists - make folder with 666 chmod
if [ -d $WORKDIR ]; then
	rm -f $WORKDIR/*.tar
	rm -f $WORKDIR/*.tar.gz
	rm -f $WORKDIR/*.sql
else
	mkdir -m 777 $WORKDIR
fi

# dive into work folder
cd $WORKDIR


# ---   Executing backup actions  -----
# dumping database to working folder
BACKUPDATE=$(date +%Y.%m.%d)
DBFILE=$DBNAME-$BACKUPDATE.sql
echo "Dumping '$DBNAME' database to '$DBFILE'"

# dump MySQL database [default]
mysqldump -u$DBUSER -p$DBPASS $DBNAME > $DBFILE

# dump PostgreSQL database [optional]
# to use pg_dump set IPv4 auth method to 'password' in /var/lib/pgsql/data/pg_hba.conf
# and we use -h localhost to force network type connection.

# PGPASSWORD="$DBPASS" pg_dump -h 127.0.0.1 -U $DBUSER -F t $DBNAME > $DBFILE

# Packing files from given backup directory
DIRFILE=$BACKUPID-$BACKUPDATE.tar
echo "Packing files from '$BACKUPDIR' to '$DIRFILE'"
tar -cf $DIRFILE $BACKUPDIR
echo "Adding database dump '$DBFILE' to '$DIRFILE'"
tar -r --file=$DIRFILE $DBFILE

# Compressing and cleaning
echo "Compressing result with GZIP"
gzip -f -4 $DIRFILE
echo "Cleaning up temp files"
rm $DBFILE

# Uploading result to storage
lftp -u $FTPUSER,$FTPPASS $FTPHOST:$FTPPORT <<EOF
cd /
mput -E $DIRFILE.gz 
quit
EOF
