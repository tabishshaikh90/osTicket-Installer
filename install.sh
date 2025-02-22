#!/bin/bash

# osTicket Automated Installation Script for Ubuntu
# Maintainer: ChatGPT
# Features: Dynamically fetch latest version, handle database setup, automate installation, and include APCu for better performance.

set -e  # Exit on error

# Define Variables
DB_NAME="osticket"
DB_USER="osticket"
DB_PASS="StrongPassword123"  # Replace with a strong password
WEB_DIR="/var/www/html"
OS_TICKET_DIR="$WEB_DIR/osticket"
GITHUB_API_URL="https://api.github.com/repos/osTicket/osTicket/releases/latest"
REQUIRED_PACKAGES=("apache2" "mariadb-server" "php" "php-mysql" "php-imap" "php-gd" "php-intl" "php-xml" "php-mbstring" "php-zip" "unzip" "curl" "jq" "php-apcu")

# Function to check if a package is installed
is_installed() {
    dpkg -l | grep -q "^ii  $1"
}

# Function to install required packages
install_packages() {
    echo "🛠️ Checking required packages..."
    for package in "${REQUIRED_PACKAGES[@]}"; do
        if is_installed "$package"; then
            echo "✅ $package is already installed. Skipping..."
        else
            echo "📦 Installing $package..."
            sudo apt install -y "$package" >/dev/null 2>&1 || {
                echo "❌ Failed to install $package. Check your internet connection."
                exit 1
            }
        fi
    done
}

# Function to fetch the latest osTicket version tag from GitHub
fetch_latest_version() {
    echo "🔍 Fetching the latest osTicket version..."
    LATEST_TAG=$(curl -s $GITHUB_API_URL | jq -r .tag_name)
    if [[ -z "$LATEST_TAG" || "$LATEST_TAG" == "null" ]]; then
        echo "❌ Failed to fetch the latest osTicket version."
        exit 1
    fi
    echo "ℹ️ Latest osTicket version: $LATEST_TAG"
}

# Function to construct the download URL for the latest release
construct_download_url() {
    OS_TICKET_ZIP="https://github.com/osTicket/osTicket/releases/download/$LATEST_TAG/osTicket-$LATEST_TAG.zip"
}

# Start Apache & MariaDB
start_services() {
    echo "🚀 Starting and enabling Apache & MariaDB..."
    sudo systemctl enable --now apache2 mariadb || {
        echo "❌ Failed to start Apache or MariaDB. Check for conflicts."
        exit 1
    }
}

# Secure MariaDB installation (manual interaction required)
secure_mysql() {
    echo "🔒 Securing MariaDB (Manual setup required)..."
    sudo mysql_secure_installation || {
        echo "❌ Failed to secure MariaDB. Ensure it's running."
        exit 1
    }
}

# Function to check and manage the database
check_database() {
    DB_EXISTS=$(sudo mysql -e "SHOW DATABASES LIKE '$DB_NAME';" | grep "$DB_NAME" || true)
    if [ -n "$DB_EXISTS" ]; then
        echo "⚠️ Database '$DB_NAME' already exists. Choose an option:"
        echo "1) Use existing database"
        echo "2) Delete and recreate database"
        echo "3) Clear all data in the existing database"
        echo "4) Exit installation"
        read -p "Enter your choice [1-4]: " DB_CHOICE

        case $DB_CHOICE in
            1) echo "✅ Using the existing database." ;;
            2)
                echo "🔥 Deleting and recreating the database..."
                sudo mysql -e "DROP DATABASE IF EXISTS $DB_NAME; DROP USER IF EXISTS '$DB_USER'@'localhost'; CREATE DATABASE $DB_NAME;" || {
                    echo "❌ Failed to recreate database."
                    exit 1
                }
                ;;
            3)
                echo "🧹 Clearing all data from the database..."
                TABLES=$(sudo mysql -Nse "SHOW TABLES FROM $DB_NAME")
                for table in $TABLES; do
                    sudo mysql -e "DROP TABLE $DB_NAME.$table"
                done
                ;;
            4)
                echo "❌ Installation aborted."
                exit 0
                ;;
            *)
                echo "❌ Invalid choice. Exiting."
                exit 1
                ;;
        esac
    else
        echo "📦 Creating new database '$DB_NAME'..."
        sudo mysql -e "CREATE DATABASE $DB_NAME;" || {
            echo "❌ Failed to create database."
            exit 1
        }
    fi
}

# Function to create MySQL user
create_database_user() {
    echo "👤 Checking if user '$DB_USER' exists..."
    USER_EXISTS=$(sudo mysql -e "SELECT User FROM mysql.user WHERE User='$DB_USER';" | grep "$DB_USER" || true)

    if [ -n "$USER_EXISTS" ]; then
        echo "⚠️ User '$DB_USER' exists. Recreating..."
        sudo mysql -e "DROP USER '$DB_USER'@'localhost';"
    fi

    echo "👤 Creating user '$DB_USER'..."
    sudo mysql -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS'; GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;" || {
        echo "❌ Failed to create database user."
        exit 1
    }
}

# Download osTicket (Hide Download Output)
download_osticket() {
    echo "📥 Downloading osTicket..."
    cd $WEB_DIR
    sudo wget -q -O osticket.zip $OS_TICKET_ZIP || {
        echo "❌ Failed to download osTicket."
        exit 1
    }

    # Verify ZIP file before extraction
    if ! file osticket.zip | grep -q "Zip archive"; then
        echo "❌ Download failed. Retrying..."
        sudo rm -f osticket.zip
        sudo wget -q -O osticket.zip $OS_TICKET_ZIP || {
            echo "❌ Download failed again."
            exit 1
        }
    fi
}

# Extract osTicket
extract_osticket() {
    echo "📂 Extracting osTicket..."
    sudo unzip -o osticket.zip -d osticket >/dev/null 2>&1 || {
        echo "❌ Failed to extract osTicket."
        exit 1
    }
}

# Set Permissions
set_permissions() {
    echo "🔧 Setting correct file permissions..."
    sudo chown -R www-data:www-data $OS_TICKET_DIR
    sudo chmod -R 755 $OS_TICKET_DIR || {
        echo "❌ Failed to set permissions."
        exit 1
    }
}

# Rename Configuration File
rename_config_file() {
    echo "🔄 Renaming osTicket configuration file..."
    if [ -f "$OS_TICKET_DIR/upload/include/ost-sampleconfig.php" ]; then
        sudo mv "$OS_TICKET_DIR/upload/include/ost-sampleconfig.php" "$OS_TICKET_DIR/upload/include/ost-config.php" || {
            echo "❌ Failed to rename configuration file."
            exit 1
        }
    else
        echo "⚠️ Configuration file not found, skipping rename."
    fi
}

# Enable Apache Rewrite Module
enable_apache_rewrite() {
    echo "🔄 Enabling Apache rewrite module..."
    sudo a2enmod rewrite
    sudo systemctl restart apache2 || {
        echo "❌ Failed to restart Apache."
        exit 1
    }
}

# Run all functions
echo "🚀 Starting osTicket Installation..."

install_packages
fetch_latest_version
construct_download_url
start_services
secure_mysql
check_database
create_database_user
download_osticket
extract_osticket
set_permissions
rename_config_file
enable_apache_rewrite

# Provide installation details
echo "✅ Installation Completed!"
echo "📌 Access osTicket: http://$(hostname -I | awk '{print $1}')/osticket/upload/setup/"
echo "🛠️ Database Credentials:"
echo "   - Database: $DB_NAME"
echo "   - User: $DB_USER"
echo "   - Password: $DB_PASS"

exit 0
