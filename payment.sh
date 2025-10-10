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

dnf install python3 gcc python3-devel -y &>>$LOG_FILE
VALIDATE $? "Installing python"


id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
     useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
     VALIDATE $? "Creating system user"
else
     echo -e "User already exits ....$Y SKIPPING $N"
fi     

mkdir -p /app
VALIDATE $? "Creating app directory"

curl -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading payment application"

cd  /app
VALIDATE $? "Changing the app directory"

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/payment.zip &>>$LOG_FILE
VALIDATE $? "unzip payment"
 
pip3 install -r requirements.txt &>>$LOG_FILE
VALIDATE $? "Download the dependencies "

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service

systemctl daemon-reload &>>$LOG_FILE
VALIDATE "Load the Service" 

systemctl enable payment &>>$LOG_FILE
VALIDATE "Enabling the payment  Service" 

systemctl start payment  &>>$LOG_FILE
VALIDATE "starting the payment  Service" 

