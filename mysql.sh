#!/bin/bash 
#Tells the system to execute the script using Bash.

#Color Codes for Output:
#Used for colored terminal output. Helps visually distinguish success/failure.
R="\e[31m"    # Red
G="\e[32m"    # Green
Y="\e[33m"    # Yellow
N="\e[0m"     # Reset

# Logging Setup:

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" # /var/log/shell-script/16-logs.log
SCRIPT_DIR=$PWD
START_TIME=$(date +%s)

#  LOGS_FOLDER: Where logs will be stored.
#  SCRIPT_NAME: Extracts the script name (without .sh) for naming the log file.
#  SCRIPT_DIR: Current working directory.
#  MONGODB_HOST: MongoDB hostname (used later).
#  LOG_FILE: Full path to the log file

#Create Log Folder + Start Log
mkdir -p $LOGS_FOLDER
echo "Script started executed at: $(date)" | tee -a $LOG_FILE

# Ensures the log folder exists.
# Logs the start time of the script.

#User ID Check:
USERID=$(id -u)  # Captures the current user's UID. UID 0 means root.
#Root Privilege Check
if [ $USERID -ne 0 ]; then
    echo "ERROR:: Please run this script with root privelege"
    exit 1 # failure is other than 0
fi

# If not run as root, exits with error.
# Prevents permission issues during installation or system changes.

# Validation Function
VALIDATE(){ # functions receive inputs through args just like shell script args
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOG_FILE
    fi
}

# Custom function to validate each command.
# $1: Exit status of the previous command.
# $2: Message describing the step.
# Logs success/failure with color and exits on failure.


dnf install mysql-server -y &>>$LOG_FILE
VALIDATE $? "Installing MySQL Server"

systemctl enable mysqld &>>$LOG_FILE
VALIDATE $? "Enabling MySQL Server"

systemctl start mysqld  &>>$LOG_FILE
VALIDATE "Starting MySQL Server"

mysql_secure_installation --set-root-pass RoboShop@1
VALIDATE $? "Setting up MySQL Server"


END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
  echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"