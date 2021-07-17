





Service Startup
sudo su - informatica
/opt/Informatica/tomcat/bin/infaservice.sh startup
Service Shutdown
sudo su - informatica
/opt/Informatica/tomcat/bin/infaservice.sh shutdown
netstat -tanp | grep TIME  #until all informatica ports are no longer in use
top -u informatica # ensure nothing else for informatica is runinng

 
sudo su
#Verify the File Descriptor Limit (was told to do it this way instead of documentation)
sudo su -
echo "informatica soft nofile 65537" >> /etc/security/limits.conf
echo "informatica hard nofile 65537" >> /etc/security/limits.conf
 
exit


PostgreSQL 10 Install
See https://www.postgresql.org/download/linux/redhat/
 
sudo yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo yum install -y postgresql10-server
sudo /usr/pgsql-10/bin/postgresql-10-setup initdb
sudo systemctl enable postgresql-10
sudo systemctl start postgresql-10
 
sudo vi /var/lib/pgsql/10/data/postgresql.conf
update:
max_connections = 4000
shared_buffers = 8GB #(they want 16GB)
max_locks_per_transaction = 1024
 
sudo systemctl restart postgresql-10.service
 
sudo su postgres
createuser --interactive --pwprompt
Enter name of role to add: informatica
Enter password for new role: Password1
Enter it again:
Shall the new role be a superuser? (y/n) y
 
psql
CREATE DATABASE informatica;
GRANT ALL PRIVILEGES ON DATABASE informatica to "informatica";
ALTER USER informatica WITH SUPERUSER;
 
create database mrs_1040;
create user mrs_1040_user with encrypted password 'Password1';
grant all privileges on database mrs_1040 to mrs_1040_user;
create database pcrs_1040;
create user pcrs_1040_user with encrypted password 'Password1';
grant all privileges on database pcrs_1040 to pcrs_1040_user;
^D
^D
 
#Change all 'ident' to 'md5'
sudo vi /var/lib/pgsql/10/data/pg_hba.conf
 
sudo su
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
Setup informatica account environment
su informatica
 
# update .bashrc file in ~ (note the IMPORTANT part in the file)
# add the informatica environment setup to the end of the .bashrc file default contents
 
cd /home/informatica
vi .bashrc
 
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
-- EOF ---
 
# save file, exit vi
# exit
Install Informatica
sudo su - informatica
 
# copy license file and install tar file to informatica home directory
cp Informatica_Federal_Operations_Corporation-MultiOS-DEI-DEQ-v1041-SL-Prod_00015862_209202.key /home/informatica
cp informatica_1040_server_linux-x64.tar /home/informatica
 
# untar Informatica install file in /data/COTS/informatica
sudo mkdir -p /data/COTS/informatica
cd /data/COTS/informatica
sudo tar xvf /home/informatica/informatica_1040_server_linux-x64.tar
sudo chown informatica:informatica /data/COTS/informatica
chmod a+x Server/install.bin
 
mkdir /opt/Informatica/
sudo chown informatica:informatica /opt/Informatica/
 
modify SilentInput.properties (See SilentInstall.properties Notes, can get copy from demodata/sandbox/install/Informatica)
./silentinstall.sh
SilentInstall.properties Notes
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
Test Installation
Test by connecting to http://$DOMAIN_HOST_NAME:6008/administrator/
Post Install


Add PCRS_ODBC to odbc.ini
Add PCRS_ODBC section to /opt/informatica/ODBC7.1/odbc.ini
 
Copy [PostgreSQL Wire Protocol] section to create [PCRS_ODBC] section. Set fields as follows:
Driver=/opt/Informatica/ODBC7.1/lib/DWpsql27.so
Description=DataDirect 7.1 PostgreSQL Wire Protocol
Database=pcrs_1040
HostName=127.0.0.1
PortNumber=5432
Create Services using Administrator URL
http://<IP or hostname>:6008/administrator
Username: AdminUser
Password: Password1
 
Manage-> Services and Nodes
Actions-> Services -> New
 
Create Following Services:
 
PowerCenter Repository Service (see section below)
PowerCenter Integration Service (see section below)
Model Repository Service (see section below)
Data Integration Service (see section below)
PowerCenter Repository Service
Name: repo_pc
Location: DomainName
License: <select license>
Primary Node: NodeName
Database Type: PostgreSQL
Username: pcrs_1040_user
Password: Password1
Connection String: PCRS_ODBC
Creation Options: No content exists
Finish - Service will be created
 
Select repo_pc service
On Processes tab:
    - add environment variable POSTGRES_ODBC=Yes
On Properties tab:
    - Recycle (green arrow circle upper right)
    - Repository Properties, Change 'Normal' to "Exclusive'
 
Action -> Repository Contents -> Create (don’t click any checkboxes)
 
On Properties tab:
    - Repository Properties, Change 'Exclusive' back to 'Normal'
PowerCenter Integration Service
Name: int_pc_1040_informatica_poc
Location: DomainName
License: <select license>
Assign: Node
Primary Node: NodeName
PowerCenter Repository Service: repo_pc
Username: AdminUser
Password: Password1
Data Movement Mode: Unicode
Finish - Service will be created
 
Select int_pc_1040_informatica_poc service
On Processes tag:
    - General Properties
        - Codepage: Use Dropdown menu to select "ISO 8859-1 Western European"
        - Java SDK Minimum Memory: 512M
        - Java SDK Maximum Memory: 2048M (CD1 used 16G)
Model Repository Service
Name: mod_repo
Location: DomainName
License: <select license>
Node: NodeName
Database Type: POSTGRESQL
Username: mrs_1040_user
Password: Password1
Connection String: jdbc:informatica:postgresql://127.0.0.1:5432;Database=mrs_1040
Creation Options: no content exists
Finish - Service will be created
 
Actions -> Repository Content -> Create (don't click any checkboxes)
Data Integration Service
Name: data_int
Location: DomainName
License: <select license>
Assign: Node
Model Repository Service: mod_repo
Username: mrs_1040_user
Password: Password1
Finish - Service will be created
Restore previous repo backup file
Place your backup.rep file here: /opt/Informatica/servers/infa_shared/backup
 
On the Admin Console:
  Repo_pc  repository ->
     Properties -> 'Normal' --change to--> 'Exclusive'
     Action -> Repository Contents -> Delete
     Action -> Repository Contents -> Restore
        Select your backup.rep file from the dropdown list
            Use defaults (No need to check any checkboxes)
     Properties -> 'Exclusive' --change back to--> 'Normal'
 
On the client:
    Workflow Manager:
        Connect/Disconnect the repo until you see an additional integration service (restart PowerCenter also worked)
        Once you see an additional integration service
            Service -> Assign Integration Service ...
                (Check) Select all displayed workflows
                Choose Integration Service: (Select the top one)
                Assign
        Try to run a workflow, if this still fails, try again and select the other integration service from the drop down (they are named the same so keep track by order)
    
Informatica Client
System Requirements
Windows Instance
 
Download informatica_1040_client_winem-64t.zip from Artifactory titan_generic_external/Informatica/Windows/PowerCenterDesigner
 
Unzip and run install.bat
Install Informatica Developer
Install Informatica PowerCenter Client
Connect Client to Server
Server (Most Likely already completed from steps above):
   System_Services → Resource_Manager_Service → Actions → Enable
   Create and Configure the Model Repository Service
   Page 190 of the BD_1040_InstallationForPowerCenter_en.pdf
 
Client:: Repository Manager:
   Repository→Configure Domains →
   new repository → "informatica"
   right click on new 'informatica' repository → configure domains → 'add' button (the dotted box)
   Domain Name: (if not known just type 'fixme')
   Gateway Host: <Host IP>
   Gateway Port: 6005
      ok →
      if 'Unable to save information for domain fixme. Error: Cannot find the specified domain [fixme] from the domain [<your actual domain name is shown here>]'
         re-create using the given domain name
