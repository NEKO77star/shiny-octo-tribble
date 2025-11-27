--[[
    Resource: org_system
    File: sql/schema.sql
    Purpose: Database schema for the Organization & Territory System
    
    Tables:
    - organizations: Main organization data
    - organization_members: Members of organizations with roles and compensation
    - org_assets: Organization-owned assets (cash, items, properties, vehicles)
    - hidden_accounts: Off-book accounts for players and organizations
    - territories: Territory definitions and control
    - territory_conflicts: Territory conflict tracking
]]

-- Organizations table
CREATE TABLE IF NOT EXISTS `organizations` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(100) NOT NULL,
    `type` ENUM('mafia', 'gang', 'company', 'store') NOT NULL,
    `leader_cid` VARCHAR(50) NOT NULL,
    `description` TEXT DEFAULT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_name` (`name`),
    KEY `idx_leader` (`leader_cid`),
    KEY `idx_type` (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Organization members table
CREATE TABLE IF NOT EXISTS `organization_members` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `org_id` INT NOT NULL,
    `citizenid` VARCHAR(50) NOT NULL,
    `role` ENUM('boss', 'executive', 'member', 'associate') NOT NULL DEFAULT 'associate',
    `salary` INT NOT NULL DEFAULT 0,
    `share_percent` INT NOT NULL DEFAULT 0,
    `joined_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_member` (`org_id`, `citizenid`),
    KEY `idx_citizenid` (`citizenid`),
    KEY `idx_role` (`role`),
    CONSTRAINT `fk_members_org` FOREIGN KEY (`org_id`) REFERENCES `organizations` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Organization assets table
CREATE TABLE IF NOT EXISTS `org_assets` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `org_id` INT NOT NULL,
    `asset_type` ENUM('cash', 'item', 'property', 'vehicle') NOT NULL,
    `identifier` VARCHAR(100) NOT NULL,
    `amount` INT NOT NULL DEFAULT 0,
    `hidden` BOOLEAN NOT NULL DEFAULT FALSE,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_org_asset` (`org_id`, `asset_type`),
    KEY `idx_identifier` (`identifier`),
    CONSTRAINT `fk_assets_org` FOREIGN KEY (`org_id`) REFERENCES `organizations` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Hidden accounts table (for players and organizations)
CREATE TABLE IF NOT EXISTS `hidden_accounts` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `owner_type` ENUM('player', 'organization') NOT NULL,
    `owner_id` VARCHAR(50) NOT NULL,
    `balance` BIGINT NOT NULL DEFAULT 0,
    `currency` ENUM('yen', 'crypto') NOT NULL DEFAULT 'yen',
    `risk_level` INT NOT NULL DEFAULT 0,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_account` (`owner_type`, `owner_id`, `currency`),
    KEY `idx_owner` (`owner_type`, `owner_id`),
    KEY `idx_risk` (`risk_level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Territories table
CREATE TABLE IF NOT EXISTS `territories` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(100) NOT NULL,
    `zone_id` VARCHAR(50) NOT NULL,
    `controlling_org_id` INT DEFAULT NULL,
    `influence_mafia` INT NOT NULL DEFAULT 0,
    `influence_gang` INT NOT NULL DEFAULT 0,
    `base_bonus` FLOAT NOT NULL DEFAULT 1.0,
    `last_updated` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_zone` (`zone_id`),
    KEY `idx_controller` (`controlling_org_id`),
    CONSTRAINT `fk_territory_org` FOREIGN KEY (`controlling_org_id`) REFERENCES `organizations` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Territory conflicts table
CREATE TABLE IF NOT EXISTS `territory_conflicts` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `territory_id` INT NOT NULL,
    `attacker_org_id` INT NOT NULL,
    `defender_org_id` INT DEFAULT NULL,
    `started_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `ended_at` DATETIME DEFAULT NULL,
    `status` ENUM('ongoing', 'attacker_win', 'defender_win', 'cancelled') NOT NULL DEFAULT 'ongoing',
    PRIMARY KEY (`id`),
    KEY `idx_territory` (`territory_id`),
    KEY `idx_attacker` (`attacker_org_id`),
    KEY `idx_defender` (`defender_org_id`),
    KEY `idx_status` (`status`),
    CONSTRAINT `fk_conflict_territory` FOREIGN KEY (`territory_id`) REFERENCES `territories` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_conflict_attacker` FOREIGN KEY (`attacker_org_id`) REFERENCES `organizations` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_conflict_defender` FOREIGN KEY (`defender_org_id`) REFERENCES `organizations` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Organization logs table (for activity tracking)
CREATE TABLE IF NOT EXISTS `org_logs` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `org_id` INT NOT NULL,
    `action_type` VARCHAR(50) NOT NULL,
    `actor_cid` VARCHAR(50) NOT NULL,
    `target_cid` VARCHAR(50) DEFAULT NULL,
    `details` TEXT DEFAULT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_org_logs` (`org_id`, `created_at`),
    KEY `idx_actor` (`actor_cid`),
    CONSTRAINT `fk_logs_org` FOREIGN KEY (`org_id`) REFERENCES `organizations` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
