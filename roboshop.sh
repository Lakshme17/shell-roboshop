#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0789ef71317d7634f" #REPLACE WITH YOUR sg ID


for Instance in $@ #dynamically 
do
      INSTANCE=$*(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t3.micro --security-group-ids sg-0789ef71317d7634f --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query 'Instances[0].InstanceId' --output text)

      #get private ip
      if [ $instance != "frontend" ]: then
          IP=$(aws ec2 describe-instances --instance-ids i-0779ef4cb6dcd9c96 --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

      else 
          IP=$(aws ec2 describe-instances --instance-ids i-0779ef4cb6dcd9c96 --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

      fi

done 
