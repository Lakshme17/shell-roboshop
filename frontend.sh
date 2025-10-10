#!/bin/bash

# Define color codes
R="\033[31m"
G="\033[32m"
Y="\033[33m"
N="\033[0m"

# Check if script is run as root
USERID=$(id -u)
if [ "$USERID" -ne 0 ]; then
    echo -e "${R}Error:${N} Please run this script with root privileges"
    exit 1
fi

# Setup logging
LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.lakshme.website
MYSQL_HOST=mysql.lakshme.website
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p "$LOGS_FOLDER"
echo "Script started at: $(date)" | tee -a "$LOG_FILE"

# Validation function
VALIDATE() {
    if [ "$1" -ne 0 ]; then
        echo -e "$2 ....... ${R}Failure${N}" | tee -a "$LOG_FILE"
        exit 1
    else
        echo -e "$2 ....... ${G}Success${N}" | tee -a "$LOG_FILE"
    fi        
}

dnf module disable nginx -y &>>$LOG_FILE
VALIDATE $? "Disabling default Nginx service"

dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE $? "Enabling Nginx service"

dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "Creating app directory"

systemctl enable nginx 
VALIDATE $? "Enabling Nginx service"

systemctl start nginx &>>$LOG_FILE
VALIDATE $? "Starting Nginx service"

rm -rf /usr/share/nginx/html/* 

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip

cd /usr/share/nginx/html 
unzip /tmp/frontend.zip

cp $SCRIPT_NAME/nginx.conf /etc/nginx/nginx.conf

systemctl restart nginx  &>>$LOG_FILE
VALIDATE $? "Restarting Nginx service"