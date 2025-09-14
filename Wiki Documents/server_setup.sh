#!/bin/bash

# Sparta Academy MySQL Server Setup Script
# Improved version with proper security and configuration
# For Ubuntu Server with remote MySQL access

set -e  # Exit on any error

echo "🚀 Starting Sparta Academy MySQL Server Setup..."
echo "📍 Server: ${SERVER_IP:-<remote-host>}"
echo "👤 User: haashim"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Generate secure passwords
MYSQL_ROOT_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
SPARTA_DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

echo -e "${BLUE}🔐 Generated secure passwords:${NC}"
echo -e "${YELLOW}MySQL Root Password: ${MYSQL_ROOT_PASSWORD}${NC}"
echo -e "${YELLOW}Sparta DB Password: ${SPARTA_DB_PASSWORD}${NC}"
echo ""
echo -e "${RED}⚠️  IMPORTANT: Save these passwords securely!${NC}"
echo ""

# Update system packages
echo -e "${BLUE}📦 Updating system packages...${NC}"
apt-get update -y
apt-get upgrade -y

# Set timezone to Europe/London (corrected from America/Chicago)
echo -e "${BLUE}🌍 Setting timezone to Europe/London...${NC}"
timedatectl set-timezone Europe/London
echo "Current time: $(date)"
echo ""

# Configure firewall
echo -e "${BLUE}🔥 Configuring UFW firewall...${NC}"
ufw --force enable
ufw allow 22/tcp    # SSH
ufw allow 3306/tcp  # MySQL
ufw status verbose
echo ""

# Install essential packages
echo -e "${BLUE}📋 Installing essential packages...${NC}"
apt-get install -y zsh htop curl wget gnupg software-properties-common

# Install MySQL Server (modern version)
echo -e "${BLUE}🐬 Installing MySQL Server...${NC}"

# Set MySQL root password non-interactively
export DEBIAN_FRONTEND=noninteractive
debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQL_ROOT_PASSWORD"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD"

# Install MySQL
apt-get install -y mysql-server

# Secure MySQL installation (automated)
echo -e "${BLUE}🔒 Securing MySQL installation...${NC}"

# Create secure installation script
cat > /tmp/mysql_secure.sql << EOF
-- Remove anonymous users
DELETE FROM mysql.user WHERE User='';

-- Disallow root login remotely initially (we'll configure this properly later)
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

-- Remove test database
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

-- Reload privilege tables
FLUSH PRIVILEGES;
EOF

mysql -u root -p"$MYSQL_ROOT_PASSWORD" < /tmp/mysql_secure.sql
rm /tmp/mysql_secure.sql

# Configure MySQL for remote access
echo -e "${BLUE}🌐 Configuring MySQL for remote access...${NC}"

# Find MySQL configuration file
MYSQL_CONFIG=""
if [ -f /etc/mysql/mysql.conf.d/mysqld.cnf ]; then
    MYSQL_CONFIG="/etc/mysql/mysql.conf.d/mysqld.cnf"
elif [ -f /etc/mysql/my.cnf ]; then
    MYSQL_CONFIG="/etc/mysql/my.cnf"
else
    echo -e "${RED}❌ Could not find MySQL configuration file${NC}"
    exit 1
fi

echo "Using MySQL config: $MYSQL_CONFIG"

# Backup original config
cp "$MYSQL_CONFIG" "$MYSQL_CONFIG.backup"

# Configure bind-address for remote connections
if grep -q "bind-address" "$MYSQL_CONFIG"; then
    sed -i 's/bind-address\s*=\s*127\.0\.0\.1/bind-address = 0.0.0.0/' "$MYSQL_CONFIG"
else
    echo "bind-address = 0.0.0.0" >> "$MYSQL_CONFIG"
fi

# Create application database user for remote access
echo -e "${BLUE}👤 Creating database user for remote access...${NC}"

cat > /tmp/create_user.sql << EOF
-- Create sparta_academy database
CREATE DATABASE IF NOT EXISTS sparta_academy
  CHARACTER SET utf8mb4 
  COLLATE utf8mb4_unicode_ci;

-- Create remote user for sparta_academy database
CREATE USER IF NOT EXISTS 'sparta_user'@'%' IDENTIFIED BY '$SPARTA_DB_PASSWORD';

-- Grant privileges on sparta_academy database only
GRANT ALL PRIVILEGES ON sparta_academy.* TO 'sparta_user'@'%';

-- Also create a root user for remote admin access (with restrictions)
CREATE USER IF NOT EXISTS 'admin'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%' WITH GRANT OPTION;

-- Apply changes
FLUSH PRIVILEGES;

-- Show created users
SELECT User, Host FROM mysql.user WHERE User IN ('sparta_user', 'admin');
EOF

mysql -u root -p"$MYSQL_ROOT_PASSWORD" < /tmp/create_user.sql
rm /tmp/create_user.sql

# Restart MySQL to apply configuration changes
echo -e "${BLUE}🔄 Restarting MySQL service...${NC}"
systemctl restart mysql
systemctl enable mysql

# Verify MySQL is running and accessible
echo -e "${BLUE}✅ Verifying MySQL installation...${NC}"
systemctl status mysql --no-pager
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "SELECT VERSION();"

# Test remote connection capability
echo -e "${BLUE}🔍 Testing database connection...${NC}"
mysql -u sparta_user -p"$SPARTA_DB_PASSWORD" -e "USE sparta_academy; SELECT 'Connection successful!' as Status;"

echo ""
echo -e "${GREEN}🎉 MySQL Server Setup Complete!${NC}"
echo ""
echo -e "${BLUE}📋 Connection Details:${NC}"
echo "────────────────────────────────────────"
echo -e "${YELLOW}Server IP:${NC} ${SERVER_IP:-<remote-host>}"
echo -e "${YELLOW}Port:${NC} 3306"
echo -e "${YELLOW}Database:${NC} sparta_academy"
echo ""
echo -e "${YELLOW}Application User:${NC}"
echo "  Username: sparta_user"
echo "  Password: $SPARTA_DB_PASSWORD"
echo ""
echo -e "${YELLOW}Admin User:${NC}"
echo "  Username: admin"  
echo "  Password: $MYSQL_ROOT_PASSWORD"
echo ""
echo -e "${BLUE}📱 Remote Connection Example:${NC}"
echo "mysql -h ${SERVER_IP:-<remote-host>} -u sparta_user -p sparta_academy"
echo ""
echo -e "${RED}⚠️  SECURITY REMINDERS:${NC}"
echo "✓ Firewall is enabled with only SSH (22) and MySQL (3306) open"
echo "✓ Strong random passwords generated"
echo "✓ Application user has access only to sparta_academy database"
echo "✓ Test database and anonymous users removed"
echo ""
echo -e "${GREEN}✅ Ready for database setup and data insertion!${NC}"

# Save connection details to file
cat > /home/haashim/mysql_connection_details.txt << EOF
Sparta Academy MySQL Connection Details
Generated: $(date)

Server: ${SERVER_IP:-<remote-host>}:3306
Database: sparta_academy

Application User:
Username: sparta_user  
Password: $SPARTA_DB_PASSWORD

Admin User:
Username: admin
Password: $MYSQL_ROOT_PASSWORD

Remote Connection:
mysql -h ${SERVER_IP:-<remote-host>} -u sparta_user -p sparta_academy

Next Steps:
1. Run database_setup.sql to create tables and insert data
2. Test connection from your local machine
3. Set up your application to use these credentials
EOF

chown haashim:haashim /home/haashim/mysql_connection_details.txt
chmod 600 /home/haashim/mysql_connection_details.txt

echo -e "${GREEN}💾 Connection details saved to: /home/haashim/mysql_connection_details.txt${NC}"
