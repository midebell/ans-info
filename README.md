# ans-info

export PGHOME=/usr/pgsql-10/
export PATH="${PGHOME}bin:${PATH}":wq
export PGSERVICEFILE="$("${PGHOME}bin/pg_config" --sysconfdir)/pg_service.conf"
cp -i "${PGHOME}/share/pg_service.conf.sample" "${PGSERVICEFILE}"
 
vi /etc/sysconfig/pgsql/pg_service.conf
##IMPORTATNT!!! ADD the folloing to the file after copy:
[informatica]
host=127.0.0.1
port=5432
dbname=informatica


unset DISPLAY
export PGHOME=/usr/pgsql-10/
export PATH="${PGHOME}bin:${PATH}"
export PGSERVICEFILE="$("${PGHOME}bin/pg_config" --sysconfdir)/pg_service.conf"
export LD_LIBRARY_PATH="$PGHOME/lib:${LD_LIBRARY_PATH}"
  
#UNCOMMENT THESE AFTER INSTALL:
#export INFA_HOME=/opt/Informatica
#export PATH="${INFA_HOME}/server/bin:${PATH}"
#export LD_LIBRARY_PATH="${INFA_HOME}/server/bin:${LD_LIBRARY_PATH}"
  
# ODBC
export ODBCHOME=/opt/Informatica/ODBC7.1
export ODBCINI=$ODBCHOME/odbc.ini
export PATH=$PATH:$ODBCHOME/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ODBCHOME/lib
  
# DT env setup
#UNCOMMENT THESE AFTER INSTALL:
#export JAVA_HOME=/opt/Informatica/java
#source ${INFA_HOME}/DataTransformation/setEnv.sh
  
unset NO_PROXY
unset http_proxy
unset https_proxy
unset no_proxy
unset HTTP_PROXY
unset HTTPS_PROXY
  
export LANG=C
export LC_ALL=C


LICENSE_KEY_LOC=/home/informatica/Informatica_Federal_Operations_Corporation-MultiOS-DEI-DEQ-v1041-SL-Prod_00015862_209202.key
 
# This can be the IP or the FQDN of the host (if hostname ensure your /etc/hostname file has the same and your /etc/hosts is correct)
DOMAIN_HOST_NAME=<use the FQDN here or IP>
 
PASS_PHRASE_PASSWD=informaticaNode1
DB_TYPE=PostgreSQL
DB_UNAME=informatica
DB_PASSWD=Password1
DB_CUSTOM_STRING_SELECTION=1
DB_CUSTOM_STRING=jdbc:informatica:postgresql://127.0.0.1:5432;DatabaseName=informatica
DOMAIN_PSSWD=Password1
DOMAIN_CNFRM_PSSWD=Password1
 
USER_INSTALL_DIR=/opt/Informatica
KEY_DEST_LOCATION=/opt/Informatica
