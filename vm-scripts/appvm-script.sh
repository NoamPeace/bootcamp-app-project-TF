#!/bin/bash
appVM_IP_ADDR=$1
Okta_URL=$2
Okta_ClientID=$3
Okta_Secret=$4
dbVM_IP_ADDR=$5
PostgresDB_Username=$6
PostgresDB_Password=$7
Ubuntu_Username=$8

sudo apt update -y
curl -sL https://deb.nodesource.com/setup_14.x | sudo bash -
sudo apt install nodejs -y
sudo apt upgrade -y
cd /home/$Ubuntu_Username
git clone https://github.com/NoamPeace/bootcamp-app.git
cd /home/$Ubuntu_Username/bootcamp-app
touch /home/$Ubuntu_Username/bootcamp-app/.env
echo -e '# Host configuration\nPORT=8080\nHOST=0.0.0.0\nNODE_ENV=development\nHOST_URL=http://$appVM_IP_ADDR:8080\nCOOKIE_ENCRYPT_PWD=superAwesomePasswordStringThatIsAtLeast32CharactersLong!\n\n # Okta configuration\nOKTA_ORG_URL=$Okta_URL\nOKTA_CLIENT_ID=$Okta_ClientID\nOKTA_CLIENT_SECRET=$Okta_Secret\n\n# Postgres configuration\nPGHOST=$dbVM_IP_ADDR\nPGUSERNAME=$PostgresDB_Username\nPGDATABASE=postgres\nPGPASSWORD=$PostgresDB_Password\nPGPORT=5432\n' >> /home/$Ubuntu_Username/bootcamp-app/.env
sudo chown -R $Ubuntu_Username:$Ubuntu_Username /home/$Ubuntu_Username/bootcamp-app
npm init -y
npm install
npm audit fix
npm run initdb
sudo touch /etc/systemd/system/bootcamp-app.service
echo -e '[Unit]\nDescription=BootCamp App Weight Tracker\n\n[Service]\nWorkingDirectory=/home/$Ubuntu_Username/bootcamp-app\nExecStart=/usr/bin/npm run dev\nType=simple\nRestart=always\nRestartSec=10\n\n[Install]\nWantedBy=basic.target\n' | sudo tee -a /etc/systemd/system/bootcamp-app.service
sudo systemctl enable bootcamp-app.service
sudo systemctl start bootcamp-app.service
