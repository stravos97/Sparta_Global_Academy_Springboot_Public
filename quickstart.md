# Quick Start Guide - Sparta Global Academy API

## Fastest Way to Start (Using Docker)

### Step 1: Clone & Setup
```bash
git clone https://github.com/stravos97/Sparta_Global_Academy_Springboot_Public.git
cd Sparta_Global_Academy_Springboot_Public
cp .env.example .env
# Edit .env and set APP_DB_USERNAME, APP_DB_PASSWORD, and local MySQL passwords
make print-env   # optional: verify sanitized values
```

Important: All credentials for Docker Compose and local runs are read from `.env`. Without a correctly populated `.env`, the stacks will not be able to connect to MySQL.

### Step 2a: Start with Local Database (mirrors schema/data)
```bash
make up-local
# Wait 30 seconds for MySQL to initialize
make verify-seed
make health-local
```

### Step 3: Access Application
- API (port 8091): http://localhost:8091
- Swagger (port 8091): http://localhost:8091/swagger-ui/index.html

### Step 4: Stop Everything
```bash
make down-local
```

### Step 2b: Start Against Remote Database
```bash
make up-remote
make health-remote

# View logs and stop when done
make logs-remote
make down-remote
```

Note: The API reads DB credentials from `.env` (`APP_DB_USERNAME`, `APP_DB_PASSWORD`). Do not hardcode passwords in compose files.

---

## Running Without Docker

### Step 1: Set Environment Variables

Use your `.env` values for credentials. Keep `.env` private and never commit it.

**macOS/Linux:**
```bash
export DB_URL=jdbc:mysql://localhost:3306/sparta_academy
export DB_USERNAME=$APP_DB_USERNAME
export DB_PASSWORD=$APP_DB_PASSWORD
```

**Windows (CMD):**
```cmd
set DB_URL=jdbc:mysql://localhost:3306/sparta_academy
set DB_USERNAME=%APP_DB_USERNAME%
set DB_PASSWORD=%APP_DB_PASSWORD%
```

### Step 2: Run Application
```bash
mvn spring-boot:run
```

---

## Essential Commands Cheat Sheet

| What You Want              | Command                               |
|----------------------------|---------------------------------------|
| Start everything (local)   | `make up-local`                       |
| Stop everything            | `make down-local`                     |
| View logs                  | `make logs-local`                     |
| Check if database is ready | `make verify-seed`                    |
| Check API health           | `make health-local` / `make health-remote` |
| Inspect env (sanitized)    | `make print-env`                      |
| See what's running         | `docker ps`                           |
| Test if API is working     | `curl http://localhost:8091/db/ping`  |
| Get all trainers           | `curl http://localhost:8091/trainers` |
| Get all courses            | `curl http://localhost:8091/courses`  |

---

## Common Issues - Quick Fixes

### "Access denied for user"
```bash
# You forgot to set environment variables. Set them:
export DB_USERNAME=sparta_user
export DB_PASSWORD=your_password_from_env_file
```

### "Connection refused"
```bash
# MySQL isn't running. Start it:
make up-local
# Or just MySQL in Docker:
docker run -d -p 3306:3306 -e MYSQL_ROOT_PASSWORD=root mysql@sha256:d2fdd0af28933c6f28475ff3b7defdbc0e0475d9f7346b5115b8d3abf8848a1d
```

### "Port already in use"
```bash
# Something else is using the port. Find and stop it:
lsof -i :8091  # Mac/Linux
netstat -ano | findstr :8091  # Windows
```

### "Table doesn't exist"
```bash
# Database wasn't initialized. Reset everything:
make down-local
docker volume prune  # Type 'y' to confirm
make up-local
```

---

## Test Your Setup

Run these commands to verify everything works:

```bash
# 1. Check API is running
curl http://localhost:8091/actuator/health
# Expected: {"status":"UP"}

# 2. Check database connection
curl http://localhost:8091/db/ping
# Expected: "OK: 1"

# 3. Get sample data
curl http://localhost:8091/trainers
# Expected: JSON array with 5 trainers
```

---

## Need Help?

1. Check the full README.md for detailed instructions
2. Look at logs: `make logs-local` or `docker logs sparta_api`
3. Make sure your `.env` file has the correct passwords
4. Verify Docker is running: `docker version`

---

## Additional Key Information

### CI/CD Pipeline - How to Use GitHub Actions

#### Automatic Builds on Push
Every push to any branch automatically:
1. Runs all tests with MySQL
2. Generates test reports
3. Validates compilation

#### Getting Your Own Docker Images Published
1. Fork the repository to your GitHub account
2. Enable GitHub Actions in your fork
3. Push to `main` branch → Automatically builds and publishes to `ghcr.io/YOUR_USERNAME/repo_name`
4. Images are tagged as:
    - `latest` - Most recent main branch build
    - `sha-XXXXXXX` - Specific commit
    - `v1.2.3` - When you create a release

#### Setting Up GitHub Secrets for Deployment
Go to Settings → Secrets → Actions and add:
```
DB_URL=jdbc:mysql://your-server:3306/sparta_academy
DB_USERNAME=your_username
DB_PASSWORD=your_password
```

---

### Running Tests Properly

#### Full Test Suite with Database
```bash
# Start MySQL first (if not using Docker)
docker run -d --name test-mysql -p 3306:3306 \
  -e MYSQL_ROOT_PASSWORD=test \
  -e MYSQL_DATABASE=testdb \
  mysql@sha256:d2fdd0af28933c6f28475ff3b7defdbc0e0475d9f7346b5115b8d3abf8848a1d

# Run tests with CI profile
mvn clean test -Dspring.profiles.active=ci

# Run specific test class
mvn test -Dtest=TrainerServiceTest

# Run with coverage report
mvn clean test jacoco:report
# Open: target/site/jacoco/index.html
```

#### Running Tests in IntelliJ IDEA
1. Right-click on `src/test/java`
2. Select "Run All Tests"
3. For database tests, ensure MySQL is running first

---

### API Usage Examples with cURL

#### Complete CRUD Operations

```bash
# CREATE a new trainer
curl -X POST http://localhost:8091/trainers \
  -H "Content-Type: application/json" \
  -d '{"fullName":"John Smith"}'

# CREATE a new course (needs trainer ID)
curl -X POST http://localhost:8091/courses \
  -H "Content-Type: application/json" \
  -d '{
    "title":"TECH 305",
    "description":"Python Development",
    "enrollDate":"2025-10-01",
    "trainerId":1
  }'

# UPDATE a trainer
curl -X PUT http://localhost:8091/trainers/1 \
  -H "Content-Type: application/json" \
  -d '{"fullName":"Philip Windridge"}'

# DELETE a course
curl -X DELETE http://localhost:8091/courses/5

# Search/Filter (if implemented)
curl "http://localhost:8091/courses?trainerId=1"
```

---

### Database Management Tasks

#### Backup Your Database
```bash
# Backup local Docker MySQL
docker exec sparta_mysql mysqldump -usparta_user -p$APP_DB_PASSWORD sparta_academy > backup.sql

# Backup remote database
mysqldump -h <remote-host> -P 3306 -u sparta_user -p sparta_academy > backup_$(date +%Y%m%d).sql
```

#### Restore From Backup
```bash
# Restore to local Docker MySQL
docker exec -i sparta_mysql mysql -usparta_user -p$APP_DB_PASSWORD sparta_academy < backup.sql

# Restore to remote
mysql -h <remote-host> -P 3306 -u sparta_user -p sparta_academy < backup.sql
```

#### Reset to Clean State
```bash
# Quick reset (data only, keeps schema)
mysql -u sparta_user -p sparta_academy < src/main/resources/database_reseed_quick.sql

# Full reset (drops and recreates everything)
mysql -u sparta_user -p sparta_academy < Wiki\ Documents/database_setup_fixed.sql
```

#### Connect with MySQL Workbench
1. Connection Method: Standard (TCP/IP)
2. Hostname: localhost or your remote DB host (see DB_URL)
3. Port: 3306
4. Username: sparta_user
5. Password: (from your .env file)
6. Default Schema: sparta_academy

---

### Monitoring and Health Checks

#### Spring Boot Actuator Endpoints
```bash
# Health check (basic)
curl http://localhost:8091/actuator/health

# Detailed health (shows database status)
curl http://localhost:8091/actuator/health | jq

# Application info
curl http://localhost:8091/actuator/info

# View all available actuator endpoints
curl http://localhost:8091/actuator
```

#### Checking Container Resources
```bash
# View container stats (CPU, Memory)
docker stats sparta_api sparta_mysql

# Check container logs with timestamps
docker logs -f --since 5m --timestamps sparta_api

# Inspect container configuration
docker inspect sparta_api | jq '.[0].Config.Env'
```

---

### Development Workflow Best Practices

#### Feature Development Workflow
```bash
# 1. Create feature branch
git checkout -b feature/add-search-endpoint

# 2. Make changes and test locally
make up-local
mvn test

# 3. Commit changes
git add .
git commit -m "Add search endpoint for courses"

# 4. Push and create PR
git push origin feature/add-search-endpoint
# GitHub Actions will automatically test your PR

# 5. After merge, new Docker image automatically builds
```

#### Hot Reload During Development
```bash
# Add Spring Boot DevTools for auto-restart
# In pom.xml, add:
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-devtools</artifactId>
    <scope>runtime</scope>
    <optional>true</optional>
</dependency>

# Run with hot reload
mvn spring-boot:run
# Now changes to Java files auto-restart the app
```

---

### Production Deployment Considerations

#### Environment-Specific Configurations
```bash
# Development
SPRING_PROFILES_ACTIVE=dev mvn spring-boot:run

# Staging  
SPRING_PROFILES_ACTIVE=staging java -jar app.jar

# Production
SPRING_PROFILES_ACTIVE=prod java -jar app.jar
```

#### JVM Tuning for Production
```bash
java -Xms512m -Xmx2g \
  -XX:+UseG1GC \
  -Dspring.profiles.active=prod \
  -jar target/Sparta-Global-Academy-0.0.1-SNAPSHOT.jar
```

#### Running as a System Service (Linux)
```bash
# Create service file: /etc/systemd/system/sparta-api.service
[Unit]
Description=Sparta Global Academy API
After=network.target

[Service]
Type=simple
User=sparta
ExecStart=/usr/bin/java -jar /opt/sparta/app.jar
Restart=on-failure
Environment="DB_URL=jdbc:mysql://localhost:3306/sparta_academy"
Environment="DB_USERNAME=sparta_user"
Environment="DB_PASSWORD=secure_password"

[Install]
WantedBy=multi-user.target

# Enable and start
sudo systemctl enable sparta-api
sudo systemctl start sparta-api
```

---

### Using with Postman

#### Import to Postman
1. Open Postman
2. Import → Link → `http://localhost:8091/v3/api-docs`
3. Creates a full collection with all endpoints

#### Environment Variables in Postman
```json
{
  "base_url": "http://localhost:8091",
  "trainer_id": 1,
  "course_id": 1
}
```

---

### Advanced Troubleshooting

#### MySQL Connection Pool Issues
```properties
# Add to application.properties for debugging
spring.datasource.hikari.maximum-pool-size=10
spring.datasource.hikari.minimum-idle=5
spring.datasource.hikari.connection-timeout=20000
logging.level.com.zaxxer.hikari=DEBUG
```

#### Enable SQL Logging
```properties
# Add to application.properties
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.format_sql=true
logging.level.org.hibernate.SQL=DEBUG
logging.level.org.hibernate.type.descriptor.sql.BasicBinder=TRACE
```

#### Memory Issues with Docker
```bash
# Increase memory limit in docker-compose.yml
services:
  api:
    mem_limit: 1g
    mem_reservation: 512m
```

---

### Security Hardening

#### For Production MySQL
```sql
-- Remove default test users
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1');

-- Restrict user permissions
REVOKE ALL PRIVILEGES ON *.* FROM 'sparta_user'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON sparta_academy.* TO 'sparta_user'@'%';

-- Enable SSL/TLS
ALTER USER 'sparta_user'@'%' REQUIRE SSL;
```

#### Application Security Headers
```java
// Add to a configuration class
@Bean
public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    http.headers().frameOptions().deny()
        .xssProtection().and()
        .contentSecurityPolicy("default-src 'self'");
    return http.build();
}
```

---

### Performance Optimization

#### Database Indexes (Already in Schema)
- `idx_trainer_name` - Fast trainer lookups
- `idx_course_title` - Fast course searches
- `idx_course_enroll_date` - Date range queries
- `idx_course_trainer` - Foreign key optimization

#### JPA Query Optimization
```properties
# Add to application.properties
spring.jpa.properties.hibernate.jdbc.batch_size=20
spring.jpa.properties.hibernate.order_inserts=true
spring.jpa.properties.hibernate.order_updates=true
```

---

### Migration from Development to Production

#### Checklist
- [ ] Change all passwords in `.env`
- [ ] Set `spring.jpa.hibernate.ddl-auto=none`
- [ ] Disable SQL logging (`spring.jpa.show-sql=false`)
- [ ] Configure proper logging levels
- [ ] Set up database backups
- [ ] Configure firewall rules
- [ ] Set up monitoring/alerting
- [ ] Configure HTTPS/SSL
- [ ] Set JVM memory limits
- [ ] Enable authentication/authorization

---

### Version Compatibility Matrix

| Component   | Version | Notes                            |
|-------------|---------|----------------------------------|
| Java        | 17+     | Required for Spring Boot 3.x     |
| Spring Boot | 3.5.5   | Current version                  |
| MySQL       | 8.0+    | 5.7 may work with modifications  |
| Docker      | 20.10+  | For buildkit features            |
| Maven       | 3.8+    | For proper dependency resolution |
| MapStruct   | 1.5.5   | For DTO mapping                  |

---

### Useful Links for Beginners

- [Spring Boot Tutorial](https://spring.io/guides/gs/spring-boot/)
- [Docker Basics](https://docs.docker.com/get-started/)
- [MySQL Tutorial](https://www.mysqltutorial.org/)
- [REST API Best Practices](https://restfulapi.net/)
- [Maven in 5 Minutes](https://maven.apache.org/guides/getting-started/maven-in-five-minutes.html)
- [Git Basics](https://git-scm.com/book/en/v2/Getting-Started-Git-Basics)
