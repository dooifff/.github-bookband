-- Create database if not exists
CREATE DATABASE IF NOT EXISTS studiobook CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Create user if not exists
CREATE USER IF NOT EXISTS 'studiobook'@'%' IDENTIFIED BY 'secret';

-- Grant privileges
GRANT ALL PRIVILEGES ON studiobook.* TO 'studiobook'@'%';

-- Flush privileges
FLUSH PRIVILEGES;
