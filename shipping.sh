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

dnf install maven -y &>>$LOG_FILE


id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
     useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
     VALIDATE $? "Creating system user"
else
     echo -e "User already exits ....$Y SKIPPING $N"
fi     

mkdir -p /app
VALIDATE $? "Creating app directory"

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading shipping application"

cd  /app
VALIDATE $? "Changing the app directory"

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "unzip shipping"

mvn clean package 
mv target/shipping-1.0.jar shipping.jar 

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service

systemctl daemon-reload &>>$LOG_FILE
VALIDATE "Load the Service" 

systemctl enable shipping
VALIDATE "Enabling the Shipping Service" 

# systemctl start shipping &>>$LOG_FILE
# VALIDATE "starting the Shipping Service" 

dnf install mysql -y &>>$LOG_FILE
VALIDATE "Install MySQL client" 

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities'
if [ $? -ne 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql 
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql
else 
    echo -e "Shipping data is already loaded... $Y SKIPPING $N"
fi

systemctl restart shipping &>>$LOG_FILE
VALIDATE "Restarting the Shipping Service"

