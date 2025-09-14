#!/bin/sh
# Create an admin user for local dev if MYSQL_ADMIN_PASSWORD is provided
set -e

if [ -n "$MYSQL_ADMIN_PASSWORD" ]; then
  echo "Creating local admin user..."
  mysql -uroot -p"$MYSQL_ROOT_PASSWORD" <<SQL
CREATE USER IF NOT EXISTS 'admin'@'%' IDENTIFIED BY '${MYSQL_ADMIN_PASSWORD}';
GRANT ALL PRIVILEGES ON sparta_academy.* TO 'admin'@'%';
FLUSH PRIVILEGES;
SQL
else
  echo "MYSQL_ADMIN_PASSWORD not set; skipping admin user creation."
fi

