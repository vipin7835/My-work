#!/bin/bash

# Set variables
AMI_ID="$1"          # Replace with your AMI ID or pass it as the first argument
INSTANCE_TYPE="t2.micro"                # Instance type
KEY_NAME="demo1"                    # Name for the key pair
SECURITY_GROUP_NAME="demo1-sg"          # Name for the security group
TAG_NAME="vipin"                     # Name tag for the instance
SUBNET_ID="subnet-02366523a81290da3" # Replace with your Subnet ID
REGION="ap-south-1"                  # AWS Region

# Check if the key pair exists in AWS
echo "Checking if key pair $KEY_NAME exists in AWS..."
KEY_EXISTS=$(aws ec2 describe-key-pairs --key-names $KEY_NAME --query 'KeyPairs[0].KeyName' --output text 2>/dev/null)

if [ "$KEY_EXISTS" == "$KEY_NAME" ]; then
    echo "Key pair $KEY_NAME already exists in AWS. Skipping key pair creation."
else
    echo "Key pair $KEY_NAME does not exist. Creating key pair..."
    PEM_FILE="$KEY_NAME.pem"
    aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > "$PEM_FILE"
    chmod 400 "$PEM_FILE"
    echo "Key pair created and saved as $PEM_FILE"
fi

# Check if the security group exists
echo "Checking if security group $SECURITY_GROUP_NAME exists in AWS..."
SG_ID=$(aws ec2 describe-security-groups --group-names $SECURITY_GROUP_NAME --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null)

if [ "$SG_ID" != "None" ]; then
    echo "Security group $SECURITY_GROUP_NAME already exists with ID: $SG_ID"
else
    echo "Security group $SECURITY_GROUP_NAME does not exist. Creating security group..."
    SG_ID=$(aws ec2 create-security-group --group-name $SECURITY_GROUP_NAME --description "My security group" --query 'GroupId' --output text)
    echo "Security group created with ID: $SG_ID"

    # Add rules to the security group
    echo "Adding rules to security group: $SECURITY_GROUP_NAME"
    aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
    aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0
    echo "Rules added: SSH (port 22) and HTTP (port 80)"
fi

# Launch the EC2 instance
echo "Launching EC2 instance with AMI: $AMI_ID and Instance Type: $INSTANCE_TYPE"
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $SG_ID \
    --subnet-id $SUBNET_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$TAG_NAME}]" \
    --query 'Instances[0].InstanceId' \
    --output text)
echo "EC2 instance launched with ID: $INSTANCE_ID"

# Wait for the instance to be running
echo "Waiting for instance to reach running state..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID
echo "Instance is now running."

# Display instance details
echo "Fetching instance details:"
aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress,PrivateIpAddress]' --output table

echo "EC2 instance created successfully!"
