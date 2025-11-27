--[[
    Resource: life_system
    File: sql/schema.sql
    Purpose: Database schema for the Life & Roleplay System
    
    Tables:
    - properties: Property listings and ownership
    - insurances: Insurance policies
    - phone_contacts: Player phone contacts
    - phone_messages: Text messages between players
    - sns_posts: Social network posts
]]

-- Properties table
CREATE TABLE IF NOT EXISTS `properties` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `property_id` VARCHAR(50) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `type` ENUM('apartment', 'office', 'gang_hideout', 'shop', 'warehouse', 'nightclub', 'bar', 'restaurant', 'car_dealership', 'garage', 'motel', 'penthouse', 'mansion', 'bunker', 'mc_clubhouse', 'strip_club', 'casino', 'factory', 'farm', 'hangar', 'dock') NOT NULL,
    `owner_type` ENUM('player', 'organization') DEFAULT NULL,
    `owner_id` VARCHAR(50) DEFAULT NULL,
    `entrance_coords` TEXT NOT NULL,
    `interior_id` VARCHAR(50) DEFAULT NULL,
    `rent_price` INT NOT NULL DEFAULT 0,
    `sale_price` INT NOT NULL DEFAULT 0,
    `is_rent` BOOLEAN NOT NULL DEFAULT FALSE,
    `rent_expires_at` DATETIME DEFAULT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_property` (`property_id`),
    KEY `idx_owner` (`owner_type`, `owner_id`),
    KEY `idx_type` (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insurances table
CREATE TABLE IF NOT EXISTS `insurances` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `type` ENUM('vehicle', 'health', 'property') NOT NULL,
    `target_id` VARCHAR(50) NOT NULL,
    `owner_cid` VARCHAR(50) NOT NULL,
    `premium` INT NOT NULL DEFAULT 0,
    `coverage` INT NOT NULL DEFAULT 0,
    `valid_until` DATETIME NOT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_insurance` (`type`, `target_id`),
    KEY `idx_owner` (`owner_cid`),
    KEY `idx_valid` (`valid_until`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Phone contacts table
CREATE TABLE IF NOT EXISTS `phone_contacts` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `owner_cid` VARCHAR(50) NOT NULL,
    `contact_cid` VARCHAR(50) NOT NULL,
    `contact_name` VARCHAR(100) NOT NULL,
    `contact_number` VARCHAR(20) NOT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_contact` (`owner_cid`, `contact_cid`),
    KEY `idx_owner` (`owner_cid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Phone messages table
CREATE TABLE IF NOT EXISTS `phone_messages` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `sender_cid` VARCHAR(50) NOT NULL,
    `receiver_cid` VARCHAR(50) NOT NULL,
    `message` TEXT NOT NULL,
    `is_read` BOOLEAN NOT NULL DEFAULT FALSE,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_sender` (`sender_cid`),
    KEY `idx_receiver` (`receiver_cid`),
    KEY `idx_conversation` (`sender_cid`, `receiver_cid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- SNS posts table
CREATE TABLE IF NOT EXISTS `sns_posts` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `author_cid` VARCHAR(50) NOT NULL,
    `author_name` VARCHAR(100) NOT NULL,
    `content` TEXT NOT NULL,
    `image_url` VARCHAR(500) DEFAULT NULL,
    `likes` INT NOT NULL DEFAULT 0,
    `visibility` ENUM('public', 'org', 'private') NOT NULL DEFAULT 'public',
    `org_id` INT DEFAULT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_author` (`author_cid`),
    KEY `idx_visibility` (`visibility`),
    KEY `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Secure chat rooms table
CREATE TABLE IF NOT EXISTS `secure_chat_rooms` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `room_name` VARCHAR(100) NOT NULL,
    `room_password` VARCHAR(255) DEFAULT NULL,
    `org_id` INT DEFAULT NULL,
    `created_by_cid` VARCHAR(50) NOT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_room` (`room_name`),
    KEY `idx_org` (`org_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Secure chat messages table
CREATE TABLE IF NOT EXISTS `secure_chat_messages` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `room_id` INT NOT NULL,
    `sender_cid` VARCHAR(50) NOT NULL,
    `sender_alias` VARCHAR(50) DEFAULT NULL,
    `message` TEXT NOT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_room` (`room_id`),
    CONSTRAINT `fk_secure_room` FOREIGN KEY (`room_id`) REFERENCES `secure_chat_rooms` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Job completions table
CREATE TABLE IF NOT EXISTS `job_completions` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `job_id` VARCHAR(50) NOT NULL,
    `completions` INT NOT NULL DEFAULT 0,
    `total_earnings` BIGINT NOT NULL DEFAULT 0,
    `last_completed_at` DATETIME DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_job_player` (`citizenid`, `job_id`),
    KEY `idx_citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
