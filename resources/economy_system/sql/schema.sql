--[[
    Resource: economy_system
    File: sql/schema.sql
    Purpose: Database schema for the Criminal Economy System
    
    Tables:
    - criminal_activities: Activity definitions and tracking
    - market_index: Dynamic market pricing data
    - activity_logs: Player activity history
]]

-- Criminal Activities table
CREATE TABLE IF NOT EXISTS `criminal_activities` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `activity_type` ENUM('drug', 'weapon', 'loan_shark', 'fraud', 'laundry', 'human_traffic', 'robbery', 'heist', 'burglary', 'car_theft', 'kidnapping', 'hacking', 'smuggling', 'chop_shop', 'street_racing', 'hitman') NOT NULL,
    `activity_id` VARCHAR(50) NOT NULL,
    `org_id` INT DEFAULT NULL,
    `citizenid` VARCHAR(50) DEFAULT NULL,
    `location` VARCHAR(100) DEFAULT NULL,
    `required_players` INT NOT NULL DEFAULT 1,
    `required_equipment` TEXT DEFAULT NULL,
    `base_reward_min` INT NOT NULL DEFAULT 0,
    `base_reward_max` INT NOT NULL DEFAULT 0,
    `risk_level` INT NOT NULL DEFAULT 1,
    `cooldown` INT NOT NULL DEFAULT 0,
    `last_completed` DATETIME DEFAULT NULL,
    `total_completions` INT NOT NULL DEFAULT 0,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_activity` (`activity_id`),
    KEY `idx_type` (`activity_type`),
    KEY `idx_org` (`org_id`),
    KEY `idx_citizen` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Market Index table
CREATE TABLE IF NOT EXISTS `market_index` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `commodity` VARCHAR(50) NOT NULL,
    `price_index` FLOAT NOT NULL DEFAULT 1.0,
    `server_supply` INT NOT NULL DEFAULT 0,
    `confiscated_amount` INT NOT NULL DEFAULT 0,
    `total_traded` BIGINT NOT NULL DEFAULT 0,
    `last_updated` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_commodity` (`commodity`),
    KEY `idx_price` (`price_index`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Activity Logs table
CREATE TABLE IF NOT EXISTS `activity_logs` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `org_id` INT DEFAULT NULL,
    `activity_id` VARCHAR(50) NOT NULL,
    `activity_type` VARCHAR(50) NOT NULL,
    `reward_amount` INT NOT NULL DEFAULT 0,
    `org_share` INT NOT NULL DEFAULT 0,
    `player_share` INT NOT NULL DEFAULT 0,
    `market_price_index` FLOAT NOT NULL DEFAULT 1.0,
    `territory_bonus` FLOAT NOT NULL DEFAULT 1.0,
    `success` BOOLEAN NOT NULL DEFAULT TRUE,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_citizen_activity` (`citizenid`, `created_at`),
    KEY `idx_org_activity` (`org_id`, `created_at`),
    KEY `idx_activity_type` (`activity_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Player Cooldowns table
CREATE TABLE IF NOT EXISTS `player_cooldowns` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `activity_id` VARCHAR(50) NOT NULL,
    `expires_at` DATETIME NOT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_cooldown` (`citizenid`, `activity_id`),
    KEY `idx_expires` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
