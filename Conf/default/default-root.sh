#! /bin/bash

#Update and Upgrade.
apt-get update && upgrade -y

#dietpi-config
/boot/dietpi/dietpi-config

#dietpi-drive_manager
/boot/dietpi/dietpi-drive_manager

#dietpi-sync
/boot/dietpi/dietpi-sync

#dietpi-backup
/boot/dietpi/dietpi-backup

#Create directory and move Dietpi-NAS folder.
cd ../../../
mkdir /mnt/Cloud/Data
mv Dietpi-NAS /mnt/Cloud/Data

#Go to Cloud and create default folders.
cd /mnt/Cloud
mkdir Data/Commands Data/Keys_SSH Data/Keys_VPN Data/Docker Data/Docker/flaresolver Data/Docker/immich-app Data/Jellyfin Public Public/Downloads Users

#Define Umask.
umask 0022

#Add default users.
adduser --quiet --disabled-password --shell /bin/bash --home /home/$2 --gecos "User" "$2"
adduser --quiet --disabled-password --shell /bin/bash --home /home/$5 --gecos "User" "$5"
echo "$3:"$(echo "$3")"" | chpasswd
echo "$6:"$(echo "$6")"" | chpasswd

#Install Fail2Ban Dietpi-Dashboard PiVPN(Wireguard) Unbound AdGuard_Home Samba_server Docker Docker_Compose Transmission Sonarr Radarr Prowlarr Readarr Bazarr Jellyfin Kavita.
/boot/dietpi/dietpi-software install 73 200 117 182 126 96 134 162 44 144 145 151 180 203 178 212

#Add default users Samba password.
(echo "$(echo "$4")"; echo "$(echo "$4")") | smbpasswd -a -s $2
(echo "$(echo "$7")"; echo "$(echo "$7")") | smbpasswd -a -s $5

#Exclude dietpi user from Samba.
pdbedit -x dietpi

#Add default groups.
groupadd $1_Cloud
groupadd $1_BAK

#Add default users to default groups.
gpasswd -M $2,$5 $1_Cloud
gpasswd -M $2 $1_BAK

#Turn admin in SU without password.
echo -e "$2 ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

#Change terminal user of Dietpi-Dashboard to admin.
rm /opt/dietpi-dashboard/
echo -e 'terminal_user = "'$2'"' >> config.toml
chmod 644 config.toml

#Go to Samba folder.
cd /mnt/Cloud/Data/Dietpi-NAS/Conf/Samba

#Create default Samba share folders.
echo -e "        guest account = $5" >> smb.conf
echo -e "        valid users = $2" >> smb.conf

cat smb_temp.html >> smb.conf
mv Samba/smb.conf /etc/samba/smb.conf
chmod 644 /etc/samba/smb.conf
service samba restart

#Change Dietpi-Dashboard password.
hash=$(echo -n "$(echo "$8")" | sha512sum | mawk '{print $1}')
secret=$(openssl rand -hex 32)
echo -e "pass = true" >> /opt/dietpi-dashboard/config.toml
echo -e 'hash="'$hash'"' >> /opt/dietpi-dashboard/config.toml
echo -e 'secret="'$secret'"' >> /opt/dietpi-dashboard/config.toml
unset -v hash secret

#Restart Dietpi-Dashboard.
systemctl restart dietpi-dashboard

#Go to default folder.
cd /mnt/Cloud/Data/Dietpi-NAS/Conf/default

#Use /mnt/Cloud/Data/Commands/default.sh and reconfig folders permissions to default.
mv default.sh /mnt/Cloud/Data/Commands

#Use /mnt/Cloud/Data/Commands/default-user.sh to add some users.
mv default-user.sh /mnt/Cloud/Data/Commands

#Use /mnt/Cloud/Data/Commands/default-keys.sh to add some ssh keys.
mv default-keys.sh /mnt/Cloud/Data/Commands

#Use /mnt/Cloud/Data/subdomain.sh to add some subdomain.
mv subdomain.sh /mnt/Cloud/Data/Commands

#Use /mnt/Cloud/Data/subdomain.sh to add some subpath.
mv subpath.sh /mnt/Cloud/Data/Commands

#Create iptables_custom.sh.
echo -e "#! /bin/bash" >> iptables_custom.sh

#Use /mnt/Cloud/Data/iptables_custom.sh to add iptables.
mv iptables_custom.sh /mnt/Cloud/Data/Commands

#Create crontab to custom iptables.
echo -e "@reboot sleep 10 && /mnt/Cloud/Data/Commands/iptables_custom.sh" >> crontab
crontab crontab
rm crontab

#Install Access Control List.
apt install acl sshpass -y

#This code is to fix the reboot error message.
systemctl unmask systemd-logind
apt install dbus -y
systemctl start dbus systemd-logind

#Go to mount drives and delete unnecessary files.
cd /mnt
rm -rf ftp_client nfs_client samba

#Set Cloud default permissions.
setfacl -R -b Cloud
chmod -R 775 Cloud
chown -R $2:$1_Cloud Cloud
setfacl -R -d -m u::rwx Cloud
setfacl -R -d -m g::rwx Cloud
setfacl -R -d -m o::r-x Cloud
chmod -R g+s Cloud

#Set BAK_Cloud default permissions.
chmod 750 BAK_Cloud
chown $2:$1_BAK BAK_Cloud
setfacl -d -m u::rwx BAK_Cloud
setfacl -d -m g::r-x BAK_Cloud
setfacl -d -m o::--- BAK_Cloud
chmod g+s Cloud BAK_Cloud

#Set Data default permissions.
cd Cloud
chmod -R 750 Data
setfacl -R -d -m u::rwx Data
setfacl -R -d -m g::r-x Data
setfacl -R -d -m o::--- Data

#Turn admin the owner of Folder.
chown -R $2:$1_Cloud Data/Commands

#Turn jellyfin the owner of Folder.
chown -R jellyfin:$1_Cloud Data/Jellyfin

#Turn debian-transmission the owner of Public Downloads Folder.
chown -R debian-transmission:$1_Cloud Public/Downloads

#Create Flaresolver Docker directory.
cd /mnt/Cloud/Data/Docker/flaresolver

#Run Flaresolver on Docker.
docker run -d --name=flaresolverr   -p 8191:8191   -e LOG_LEVEL=info   --restart unless-stopped   ghcr.io/flaresolverr/flaresolverr:latest

#Go to Immich Docker directory.
cd /mnt/Cloud/Data/Docker/immich-app

#Import default files.
mv /mnt/Cloud/Data/Dietpi-NAS/Conf/Immich/docker-compose.yml /mnt/Cloud/Data/Docker/immich-app

#Change Data Base password.
echo -e "UPLOAD_LOCATION=/mnt/Cloud/Data/Docker/immich-app/immich-files\nDB_DATA_LOCATION=/mnt/Cloud/Data/Docker/immich-app/postgres\nIMMICH_VERSION=release\nDB_USERNAME=postgres\nDB_DATABASE_NAME=immich\nDB_PASSWORD=$9" >> .env

#Run Immich on Docker.
docker compose up -d
