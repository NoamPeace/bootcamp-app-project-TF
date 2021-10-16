#!/bin/bash
PostgresDB_Username=$1
PostgresDB_Password=$2
sudo apt update -y
sudo apt upgrade -y
sudo snap install docker
sudo service docker start
sudo docker run --name postgres -p 5432:5432 -e POSTGRES_USER=$PostgresDB_Username -e POSTGRES_PASSWORD=$PostgresDB_Password -d --restart unless-stopped postgres