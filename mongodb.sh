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
SCRIPT_NAME="$(basename "$0")"
SCRIPT_NAME="${SCRIPT_NAME%%.*}"
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

# # Install packages passed as arguments
# for package in "$@"; do
#     # Check if the package is already installed
#     dnf list installed "$package" &>>"$LOG_FILE"
#     if [ "$?" -ne 0 ]; then
#         dnf install "$package" -y &>>"$LOG_FILE"
#         VALIDATE "$?" "$package"
#     else
#         echo -e "$package is already installed ....... ${Y}Skipping${N}" | tee -a "$LOG_FILE"
#     fi
# done

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Adding Mongo repo"

dnf install mongodb-org -y &>>$LOG_FILE
VALIDATE $? "installing MongoDB"

systemctl enable mongod &>>$LOG_FILE
VALIDATE $? "Enable MongoDB"

systemctl start mongod &>>$LOG_FILE
VALIDATE $? "Start MongoDB"

sed -i 's/127.0.0.0/0.0.0.0/g' /etc/mongodb.conf
VALIDATE $? "Allowing remote connections to MongoDB"

systemctl restart mongod
VALIDATE $? "Restarted MongoDB"