# Grader Than Workspace Templates

A collection of setup scripts used to initialize development environments for different languages and frameworks in the Grader Than Workspace. These scripts are designed to provide a low barrier to entry for academic environments.

## Overview

This repository contains automated setup scripts that configure development environments with:
- Language-specific tools and package managers
- Testing frameworks
- Linting and formatting tools
- Jupyter kernel support where applicable
- Database containers with persistent storage

## Available Languages

- **JavaScript** - Node.js environment with Jest, ESLint, and Prettier
- **TypeScript** - TypeScript development with ts-jest, ESLint, and type checking
- **Python** - Python environment with virtual env, pytest, black, and Jupyter support
- **MySQL** - MySQL database container with persistent storage
- **PostgreSQL** - PostgreSQL database container with persistent storage
- **Redis** - Redis cache container with persistent storage
- **MongoDB** - MongoDB NoSQL database container with persistent storage

## Usage

### Basic Usage

```bash
./setup.sh <language>
```

Example:
```bash
./setup.sh javascript
./setup.sh python
./setup.sh mysql
```

### Project Directory

By default, projects are created in `/home/$USERNAME/Documents/code`. You can override this:

```bash
PROJECT_ROOT=/custom/path ./setup.sh javascript
```

## Language-Specific Features

### JavaScript/TypeScript
- Creates a `package.json` with pre-configured dependencies
- Installs Jest for testing
- Configures ESLint with relaxed rules for academic use
- Sets up Prettier for code formatting
- Installs Jupyter kernel support (tslab)

### Python
- Creates a virtual environment in `.venv`
- Installs development tools: black, isort, mypy, pylint, pytest
- Configures Jupyter support
- Installs optional visualization packages globally

### Database Containers

All database setup scripts support environment variables for customization:

#### MySQL
```bash
MYSQL_HOST_PORT=3307 \
MYSQL_DATA_DIR=/custom/mysql/data \
MYSQL_TAG=8.0 \
MYSQL_ROOT_PASSWORD=secret \
./setup.sh mysql
```

#### PostgreSQL
```bash
POSTGRES_HOST_PORT=5433 \
POSTGRES_DATA_DIR=/custom/postgres/data \
POSTGRES_TAG=15-alpine \
POSTGRES_USER=myuser \
POSTGRES_PASSWORD=mypass \
POSTGRES_DB=mydb \
./setup.sh postgres
```

#### Redis
```bash
REDIS_HOST_PORT=6380 \
REDIS_DATA_DIR=/custom/redis/data \
REDIS_TAG=7.2 \
./setup.sh redis
```

#### MongoDB
```bash
MONGODB_HOST_PORT=27018 \
MONGODB_DATA_DIR=/custom/mongodb/data \
MONGODB_TAG=7.0 \
./setup.sh mongodb
```

## Environment Variables

### Global Variables
- `PROJECT_ROOT` - Base directory for project creation (default: `/home/$USERNAME/Documents/code`)
- `CACHE_DIR` - Cache directory for downloaded resources (default: `/home/$USERNAME/.gt-cache`)

### Database Variables
All database containers support:
- `*_HOST_PORT` - Host port for container mapping
- `*_DATA_DIR` - Directory for persistent data storage
- `*_TAG` - Docker image tag/version (default: `latest`)

## Requirements

- **Bash** - All scripts require Bash shell
- **Docker** - Required for database containers
- **Node.js/npm** - Required for JavaScript/TypeScript environments
- **Python 3** - Required for Python environments

## Academic Environment Features

These templates are optimized for academic use with:
- Relaxed linting rules to reduce friction for beginners
- No authentication on databases (development only)
- Clear error messages and setup feedback
- Persistent data storage in project directories
- Simple, memorable default passwords

## Project Structure

```
workspace-templates/
├── setup.sh              # Main entry point
├── javascript/
│   ├── setup.sh         # JavaScript-specific setup
│   └── project.json     # Template package.json
├── typescript/
│   ├── setup.sh         # TypeScript-specific setup
│   ├── project.json     # Template package.json
│   └── tsconfig.json    # TypeScript configuration
├── python/
│   └── setup.sh         # Python-specific setup
├── mysql/
│   └── setup.sh         # MySQL container setup
├── postgres/
│   └── setup.sh         # PostgreSQL container setup
├── redis/
│   └── setup.sh         # Redis container setup
└── mongodb/
    └── setup.sh         # MongoDB container setup
```

## License

Grader Than Technology LLC Academic Content License - This content is licensed for academic use only. See [LICENSE](LICENSE) file for full license terms.

Key points:
- Free for academic use
- Attribution to Grader Than Technology LLC required
- Commercial use prohibited without written permission
- License terms may be updated periodically
