#!/bin/bash

# Variables
S3_BUCKET="your-s3-bucket-name"
S3_FILE="index.html"
DEST_DIR="/var/www/html"
HTML_FILE_PATH="$DEST_DIR/index.html"

# Detect OS version
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Unable to detect OS. Exiting."
    exit 1
fi

# Function to install httpd and configure
install_httpd() {
    echo "Installing Apache HTTP Server (httpd)..."
    if [[ $OS == "ubuntu" ]]; then
        sudo apt update && sudo apt install -y apache2
        sudo systemctl enable apache2 && sudo systemctl start apache2
    elif [[ $OS == "centos" || $OS == "rhel" ]]; then
        sudo yum install -y httpd
        sudo systemctl enable httpd && sudo systemctl start httpd
    else
        echo "Unsupported OS. Exiting."
        exit 1
    fi

    echo "Apache installed and running."
}

# Function to copy HTML file from S3
copy_from_s3() {
    echo "Copying $S3_FILE from S3 bucket $S3_BUCKET..."

    # Use a temporary location for download
    TEMP_PATH="/tmp/$S3_FILE"
    if aws s3 cp s3://$S3_BUCKET/$S3_FILE $TEMP_PATH; then
        echo "File downloaded successfully to $TEMP_PATH."

        # Move the file to the destination directory with sudo
        sudo mv $TEMP_PATH $HTML_FILE_PATH
    else
        echo "Failed to copy file from S3. Exiting."
        exit 1
    fi
}

# Execute functions
install_httpd
copy_from_s3

# Set permissions
echo "Setting permissions for $HTML_FILE_PATH..."
sudo chmod 644 $HTML_FILE_PATH
if [[ $OS == "ubuntu" ]]; then
    sudo chown www-data:www-data $HTML_FILE_PATH
elif [[ $OS == "centos" || $OS == "rhel" ]]; then
    sudo chown apache:apache $HTML_FILE_PATH
fi

# Restart web server
echo "Restarting web server..."
if [[ $OS == "ubuntu" ]]; then
    sudo systemctl restart apache2
elif [[ $OS == "centos" || $OS == "rhel" ]]; then
    sudo systemctl restart httpd
fi

echo "Setup complete. Access your web page at http://<your-server-ip>"
