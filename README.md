# Sparta Global Academy — Spring Boot API
A professional Spring Boot REST API with MySQL database for managing trainers and courses. This guide provides comprehensive setup instructions for beginners to easily deploy and run the application.

## Quick Start Options

You have three efficient ways to run this application:

| Method                           | Difficulty        | Best For                              | Time Required |
|----------------------------------|-------------------|---------------------------------------|---------------|
| **Docker with Pre-built Images** | ★☆☆ (Easiest)     | Production-like setup, no compilation | 2 minutes     |
| **Docker with Local MySQL**      | ★★☆ (Recommended) | Development with database control     | 3 minutes     |
| **Local Deployment**             | ★★★ (Traditional) | Full control over environment         | 5-10 minutes  |

## Prerequisites

### For Docker deployment:

- **Docker Desktop** installed ([Download here](https://www.docker.com/products/docker-desktop))
- Docker Compose (included with Docker Desktop)
- Git for cloning the repository

### For local deployment without Docker:

- **Java 17** or higher ([Download Eclipse Temurin](https://adoptium.net/))
- **Maven 3.8+** ([Download Maven](https://maven.apache.org/download.cgi))
- MySQL 8.0 (optional if using Docker for database only)

## Initial Setup

### Step 1: Clone the Repository
```bash
git clone https://github.com/stravos97/Sparta_Global_Academy_Springboot_Public.git
cd Sparta_Global_Academy_Springboot_Public
```

### Step 2: Create Your Environment File
The `.env` file contains sensitive credentials that should never be committed to Git.

**Option A: Automated Generation (Recommended)**
```bash
# Generate secure .env with strong passwords
make gen-env
```

**Option B: Manual Setup**
```bash
# Copy the example environment file
cp .env.example .env

# Edit the .env file with your preferred text editor
nano .env  # or use: vim, code, notepad, etc.
```

### Step 3: Configure Your .env File

Edit the `.env` file with the following values:

```bash
# ====================================
# Database Credentials Configuration
# ====================================

# Application database user credentials
# These are used by the Spring Boot application to connect to MySQL
APP_DB_USERNAME=sparta_user
APP_DB_PASSWORD=your_secure_password_here  # Change this!

# Local MySQL root password (only for local Docker deployment)
MYSQL_ROOT_PASSWORD=local_root_password_here  # Change this!
MYSQL_ADMIN_PASSWORD=local_admin_password_here  # Change this!

# Remote database URL (optional - only if using remote MySQL)
# Uncomment and modify if you're connecting to a different remote database
# DB_URL=jdbc:mysql://your-server-ip:3306/sparta_academy
```

**Security Notes:**
- Use strong passwords (mix of letters, numbers, special characters)
- Never commit the `.env` file to Git (it's already in `.gitignore`)
- Keep your `.env` file secure and don't share passwords
 - Credentials for Docker Compose and local runs are sourced exclusively from `.env`. If `.env` is missing or incomplete, `make up-local` / `make up-remote` will fail to connect to the database.
 
Quick sanity check of your .env:
```bash
make print-env
```

## Environment File Management

### Automated .env Generation (Recommended)

For enhanced security and convenience, use the automated `.env` generation:

```bash
# Generate secure .env with strong passwords (recommended)
make gen-env

# Force generate (overwrites existing .env)
make gen-env-force
```

**Features:**
- 🔐 **Strong 25-character passwords** using OpenSSL cryptographic generation
- 📝 **Helpful inline comments** explaining each variable's purpose
- 🔄 **Environment-aware defaults** for local and remote configurations
- ⚠️ **Safety checks** to prevent accidental overwrites
- 📋 **Usage guidance** built into the generated file

**Example Output:**
```bash
$ make gen-env
✅ Secure .env file generated successfully!
   - Generated 2025-01-14 10:30:45
   - APP_DB_PASSWORD: 25 chars (secure)
   - MYSQL passwords: 25 chars each (secure)

Next steps:
   1. Verify settings: make print-env
   2. Start local stack: make up-local
   3. Or remote stack: make up-remote

⚠️  Remember to backup this .env file securely!
```

### Security Best Practices

- **Never commit `.env`** - It's already in `.gitignore`
- **Backup securely** - Store credentials in a secure location
- **Rotate regularly** - Regenerate passwords periodically using `make gen-env-force`
- **Use strong passwords** - The generated passwords use mixed case, numbers, and symbols
- **Verify before use** - Always run `make print-env` to check settings

### Manual Configuration (Alternative)

If you prefer manual setup, follow the original process in [Step 3: Configure Your .env File](#step-3-configure-your-env-file) above.

## Method 1: Using Docker with Pre-built Images

This is the easiest method - uses pre-built images from GitHub Container Registry.

### Option A: Connect to Remote Database

```bash
# Start the application connected to remote database
make up-remote

# Or without Make:
docker compose -f docker-compose.remote.yml up -d

# View application logs
make logs-remote

# Stop the application
make down-remote
```
 
Note: The application reads database credentials from your `.env` (variables `APP_DB_USERNAME` and `APP_DB_PASSWORD`). Do not hardcode passwords in compose files.

### Option B: Use Local MySQL Database

```bash
# Start local MySQL and the application
make up-local

# Or without Make:
docker compose -f docker-compose.local.yml up -d

# Wait for MySQL to be healthy (check status)
docker ps  # Look for "healthy" status

# View application logs
make logs-local

# Verify the database was seeded correctly
make verify-seed

# Stop everything
make down-local
```

Note: Local MySQL and the application use credentials from `.env`. Ensure `APP_DB_USERNAME`, `APP_DB_PASSWORD`, and local MySQL passwords are set there before starting.

### Accessing the Application
Once running, access the application at:
- **API (port 8091)**: http://localhost:8091
- **Swagger UI (port 8091)**: http://localhost:8091/swagger-ui/index.html
- **Health Check (port 8091)**: http://localhost:8091/actuator/health

View container images, available tags, and digests on GHCR:
- [GHCR package page](https://github.com/stravos97/Sparta_Global_Academy_Springboot_Public/pkgs/container/sparta_global_academy_springboot_public)

## Method 2: Running Locally Without Docker

### Step 1: Set Up MySQL Database

#### Option A: Use Docker for MySQL only
```bash
# Start just MySQL using Docker
docker run -d \
  --name sparta-mysql \
  -e MYSQL_ROOT_PASSWORD=rootpassword \
  -e MYSQL_DATABASE=sparta_academy \
  -e MYSQL_USER=sparta_user \
  -e MYSQL_PASSWORD=your_password_here \
  -p 3306:3306 \
  mysql@sha256:d2fdd0af28933c6f28475ff3b7defdbc0e0475d9f7346b5115b8d3abf8848a1d

# Wait for MySQL to be ready (about 30 seconds)
docker logs sparta-mysql

# Create tables and seed data
docker exec -i sparta-mysql mysql -usparta_user -pyour_password_here sparta_academy < Wiki\ Documents/database_setup_fixed.sql
```

#### Option B: Use existing MySQL installation
```bash
# Connect to your MySQL server
mysql -u root -p

# Create database and user
CREATE DATABASE sparta_academy;
CREATE USER 'sparta_user'@'localhost' IDENTIFIED BY 'your_password_here';
GRANT ALL PRIVILEGES ON sparta_academy.* TO 'sparta_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;

# Import the schema and seed data
mysql -u sparta_user -p sparta_academy < Wiki\ Documents/database_setup_fixed.sql
```

### Step 2: Configure Application Environment Variables

Set environment variables before running the application:

#### On Windows (Command Prompt):
```cmd
set DB_URL=jdbc:mysql://localhost:3306/sparta_academy
set DB_USERNAME=sparta_user
set DB_PASSWORD=your_password_here
```

#### On Windows (PowerShell):
```powershell
$env:DB_URL="jdbc:mysql://localhost:3306/sparta_academy"
$env:DB_USERNAME="sparta_user"
$env:DB_PASSWORD="your_password_here"
```

#### On macOS/Linux:
```bash
export DB_URL=jdbc:mysql://localhost:3306/sparta_academy
export DB_USERNAME=sparta_user
export DB_PASSWORD=your_password_here
```

### Step 3: Build and Run the Application

```bash
# Clean and compile the project
mvn clean compile

# Run tests (optional)
mvn test

# Run the application
mvn spring-boot:run

# Or build a JAR and run it
mvn clean package
java -jar target/Sparta-Global-Academy-0.0.1-SNAPSHOT.jar
```

## Makefile Commands Reference

The project includes a Makefile for convenience. Here are all available commands:

| Command                   | Description                            |
|---------------------------|----------------------------------------|
| `make help`               | Show all available commands            |
| **Local Stack Commands**  |                                        |
| `make up-local`           | Start local MySQL + API with seed data |
| `make down-local`         | Stop local MySQL + API                 |
| `make logs-local`         | View logs from local API               |
| `make ps-local`           | Show status of local containers        |
| `make verify-seed`        | Verify database was seeded correctly   |
| **Remote Stack Commands** |                                        |
| `make up-remote`          | Start API connected to remote database |
| `make down-remote`        | Stop remote-connected API              |
| `make logs-remote`        | View logs from remote-connected API    |
| `make ps-remote`          | Show status of remote containers       |
| **Utility Commands**      |                                        |
| `make pull-image`         | Pull latest Docker image from GHCR     |
| `make gen-env`            | Generate secure .env file              |
| `make gen-env-force`      | Generate .env file (overwrite existing)|

## CI/CD Overview

- Private repo (this repository):
  - Runs CI tests on all pushes and PRs.
  - On `main`, runs a deploy job (placeholder) after tests pass.
  - If tests and deploy both succeed, mirrors a single-commit snapshot to the public repo.
- Public repo: publishes Docker images only
  - Receives the snapshot commit and builds multi-arch images (amd64 + arm64).
  - Images and tags are visible on GHCR: 
    - https://github.com/stravos97/Sparta_Global_Academy_Springboot_Public/pkgs/container/sparta_global_academy_springboot_public
- Full details and maintenance guide: see the [Workflow and Mirroring Guide](https://github.com/stravos97/Sparta_Global_Academy_Springboot/blob/main/WORKFLOWS.md)

| Command             | Description                          |
|---------------------|--------------------------------------|
| `make health-local` | Check local API health endpoint      |
| `make health-remote`| Check remote-connected API health    |
| `make print-env`    | Show environment values from `.env`  |

## Troubleshooting

### Common Issues and Solutions

#### 1. "Access denied for user 'root'@'localhost'" Error
**Problem:** Environment variables not set correctly.

**Solution:**
- Ensure you've set the environment variables (DB_URL, DB_USERNAME, DB_PASSWORD)
- Check they're exported (Linux/Mac) or set (Windows) in your current terminal session
- Verify the values match your MySQL setup

#### 2. "Connection refused" or "Can't connect to MySQL"
**Problem:** MySQL isn't running or isn't accessible.

**Solution:**
- Check MySQL is running: `docker ps` (if using Docker) or `systemctl status mysql`
- Ensure MySQL is listening on port 3306
- Check firewall settings aren't blocking port 3306

#### 3. Docker Image Pull Issues
**Problem:** Can't pull the pre-built image from GHCR.

**Solution:**
```bash
# The image is public, but you might need to authenticate for rate limits
docker login ghcr.io -u YOUR_GITHUB_USERNAME

# Then pull the image
docker pull ghcr.io/stravos97/sparta_global_academy_springboot_public:latest
```

#### 4. Port Already in Use
**Problem:** Port 8091 or 3306 already in use.

**Solution:**
```bash
# Find what's using the port (Linux/Mac)
lsof -i :8091
lsof -i :3306

# On Windows
netstat -ano | findstr :8091
netstat -ano | findstr :3306

# Either stop the conflicting service or change ports in docker-compose files
```

#### 5. Database Not Initialized
**Problem:** Tables don't exist or data is missing.

**Solution for Docker:**
```bash
# Remove volumes and restart to reinitialize
docker compose -f docker-compose.local.yml down -v
make up-local
```

**Solution for local MySQL:**
```bash
# Re-run the setup script
mysql -u sparta_user -p sparta_academy < Wiki\ Documents/database_setup_fixed.sql
```

## Verifying Your Installation

### 1. Check Application Health
```bash
curl http://localhost:8091/actuator/health
# Should return: {"status":"UP"}
```

### 2. Test Database Connection
```bash
curl http://localhost:8091/db/ping
# Should return: "OK: 1"
```

### 3. List Database Tables
```bash
curl http://localhost:8091/db/tables
# Should return: ["courses","trainers"]
```

### 4. Get All Trainers
```bash
curl http://localhost:8091/trainers
# Should return list of trainers
```

## Database Information

### Default Schema
- **Database Name:** sparta_academy
- **Tables:** trainers, courses
- **View:** course_details

### Sample Data (Pre-seeded)
The database comes with sample data:
- 5 Trainers (Phil, Catherine, Nish, Abdul, Paula)
- 5 Courses (TECH 300-303, DATA 304)

### Connection Examples

#### Using MySQL Client:
```bash
# Connect to local Docker MySQL
mysql -h localhost -u sparta_user -p sparta_academy

# Connect to remote MySQL (replace with your server)
mysql -h <remote-host> -P 3306 -u sparta_user -p sparta_academy
```

#### Using IntelliJ IDEA:
1. Open Database tool: View → Tool Windows → Database
2. Add Data Source → MySQL
3. Configure:
    - Host: localhost (or your remote IP)
    - Port: 3306
    - User: sparta_user
    - Password: (from your .env file)
    - Database: sparta_academy
4. Test Connection

## Using Different Docker Images

### Latest Stable Version
```bash
docker pull ghcr.io/stravos97/sparta_global_academy_springboot_public:latest
```

### Specific Git Commit
```bash
# Use a specific commit SHA
docker pull ghcr.io/stravos97/sparta_global_academy_springboot_public:sha-902e448
```

### Main Branch (Development)
```bash
docker pull ghcr.io/stravos97/sparta_global_academy_springboot_public:main
```

To use a different image version, update the image tag in the docker-compose files.

## Local Docker Development and Testing

Use this if you want to iterate on code and run the API with a locally built image instead of pulling from GHCR. It also shows how to run tests in containers.

### Build a Local Image
```bash
# Build with BuildKit caching for speed
DOCKER_BUILDKIT=1 docker build -t sparta-api:local .

# Optionally tag with your own name/registry
# docker build -t yourname/sparta-api:dev .
```

### Use Your Local Image with Docker Compose (Dev)
You have two simple options — pick one.

1) Quick edit of `docker-compose.local.yml` (temporary change):
```diff
 services:
   api:
-    image: ghcr.io/stravos97/sparta_global_academy_springboot_public:latest
+    build: .
+    image: sparta-api:local   # optional tag for local builds
     environment:
-      SPRING_PROFILES_ACTIVE: prod
+      # Default properties are dev-friendly; set profile only if you add one
+      # SPRING_PROFILES_ACTIVE: dev
       DB_URL: jdbc:mysql://mysql:3306/sparta_academy
       DB_USERNAME: ${APP_DB_USERNAME}
       DB_PASSWORD: ${APP_DB_PASSWORD}
```

Then run:
```bash
docker compose -f docker-compose.local.yml up -d --build
```

2) Use an override file (preferred; no edits to tracked files):
Create `docker-compose.dev.yml` with just the API overrides:
```yaml
services:
  api:
    build: .
    image: sparta-api:local
    environment:
      # Uncomment if you add a dev profile later
      # SPRING_PROFILES_ACTIVE: dev
```

Run with both files:
```bash
docker compose -f docker-compose.local.yml -f docker-compose.dev.yml up -d --build
```

Notes:
- The default `application.properties` is already suitable for local dev. A `dev` profile is optional.
- The MySQL service and credentials still come from your `.env`.

### Local Testing in Docker
If you want to run the Maven test suite in a container (useful for parity across machines), add a lightweight test service via an override file.

Create `docker-compose.test.yml`:
```yaml
services:
  test:
    image: maven:3.9-eclipse-temurin-17
    working_dir: /workspace
    volumes:
      - .:/workspace
      - ~/.m2:/root/.m2
    environment:
      # Use CI profile or override DB via env below
      SPRING_PROFILES_ACTIVE: ci
      # If your tests need a database, point to the compose MySQL service:
      # DB_URL: jdbc:mysql://mysql:3306/testdb
      # DB_USERNAME: root
      # DB_PASSWORD: ${MYSQL_ROOT_PASSWORD}
    command: mvn -q -B clean test
    depends_on:
      - mysql
```

Run tests (ensures MySQL is up when needed):
```bash
# Start DB only (no API) and run tests
docker compose -f docker-compose.local.yml -f docker-compose.test.yml up --abort-on-container-exit --exit-code-from test test

# Or run unit tests without DB from your host
mvn -q -B test
```

### Optional Dockerfile Tweaks for Dev Speed
- The Dockerfile already uses multi-stage builds and caches Maven deps:
  - `--mount=type=cache,target=/root/.m2` keeps dependency downloads fast.
- For faster local rebuilds, keep test execution outside the image build (run `mvn test` separately).
- If you later add a `dev` profile, you can expose it via Compose `environment: SPRING_PROFILES_ACTIVE=dev`.

### Clean Up
```bash
# Stop containers
docker compose -f docker-compose.local.yml down

# Remove volumes if you want a fresh DB
docker compose -f docker-compose.local.yml down -v
```

## Important Security Notes

1. Never commit credentials: The `.env` file should never be committed to Git
2. Use strong passwords: Especially for production deployments
3. Rotate credentials regularly: Change passwords periodically
4. Limit database access: Use firewall rules to restrict database access
5. Use HTTPS in production: Add SSL/TLS certificates for production deployments

## Additional Resources

- [Spring Boot Documentation](https://spring.io/projects/spring-boot)
- [Docker Documentation](https://docs.docker.com/)
- [MySQL Documentation](https://dev.mysql.com/doc/)
- [Project Architecture Guide](https://github.com/stravos97/Sparta_Global_Academy_Springboot_Public/blob/main/Wiki%20Documents/Architecture.md)
- [Workflow and Mirroring Guide](https://github.com/stravos97/Sparta_Global_Academy_Springboot/blob/main/WORKFLOWS.md)

## Reference Links

- [Quickstart guide](https://github.com/stravos97/Sparta_Global_Academy_Springboot_Public/blob/main/quickstart.md)
- [Architecture document](https://github.com/stravos97/Sparta_Global_Academy_Springboot_Public/blob/main/Wiki%20Documents/Architecture.md)
- [Database setup SQL](https://github.com/stravos97/Sparta_Global_Academy_Springboot_Public/blob/main/Wiki%20Documents/database_setup_fixed.sql)
- [Server setup script](https://github.com/stravos97/Sparta_Global_Academy_Springboot_Public/blob/main/Wiki%20Documents/server_setup.sh)

## Getting Help

If you encounter issues not covered in this guide:

1. Check the [GitHub Issues](https://github.com/stravos97/Sparta_Global_Academy_Springboot_Public/issues)
2. Review application logs: `make logs-local` or `docker logs sparta_api`
3. Verify your environment variables are set correctly
4. Ensure all prerequisites are installed and versions match requirements

## License

This project is part of the Sparta Global Academy training program.

**Last Updated:** September 2025
**Version:** 1.0.0
