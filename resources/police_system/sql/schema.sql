--[[
    Resource: police_system
    File: sql/schema.sql
    Purpose: Database schema for the Police & Justice System
    
    Tables:
    - cases: Main case records
    - case_suspects: Suspects, witnesses, and victims linked to cases
    - evidence: Evidence items linked to cases
    - vehicle_checks: Vehicle lookup history
    - criminal_records: Permanent criminal record entries
]]

-- Cases table
CREATE TABLE IF NOT EXISTS `cases` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `case_number` VARCHAR(50) NOT NULL,
    `title` VARCHAR(200) NOT NULL,
    `description` TEXT DEFAULT NULL,
    `status` ENUM('open', 'pending_prosecution', 'closed', 'dismissed') NOT NULL DEFAULT 'open',
    `lead_officer_cid` VARCHAR(50) NOT NULL,
    `prosecutor_cid` VARCHAR(50) DEFAULT NULL,
    `judge_cid` VARCHAR(50) DEFAULT NULL,
    `sentence_jail_time` INT DEFAULT NULL,
    `sentence_fine` INT DEFAULT NULL,
    `sentence_notes` TEXT DEFAULT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `closed_at` DATETIME DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_case_number` (`case_number`),
    KEY `idx_status` (`status`),
    KEY `idx_lead_officer` (`lead_officer_cid`),
    KEY `idx_prosecutor` (`prosecutor_cid`),
    KEY `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Case Suspects table (also for witnesses and victims)
CREATE TABLE IF NOT EXISTS `case_suspects` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `case_id` INT NOT NULL,
    `citizenid` VARCHAR(50) NOT NULL,
    `role` ENUM('suspect', 'witness', 'victim') NOT NULL DEFAULT 'suspect',
    `notes` TEXT DEFAULT NULL,
    `added_by_cid` VARCHAR(50) NOT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_case_person` (`case_id`, `citizenid`, `role`),
    KEY `idx_citizenid` (`citizenid`),
    KEY `idx_role` (`role`),
    CONSTRAINT `fk_suspect_case` FOREIGN KEY (`case_id`) REFERENCES `cases` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Evidence table
CREATE TABLE IF NOT EXISTS `evidence` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `case_id` INT NOT NULL,
    `evidence_type` ENUM('item', 'weapon', 'photo', 'audio', 'log', 'dna', 'fingerprint') NOT NULL,
    `reference_id` VARCHAR(255) DEFAULT NULL,
    `description` TEXT NOT NULL,
    `seized_by_cid` VARCHAR(50) NOT NULL,
    `chain_of_custody` TEXT DEFAULT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_case` (`case_id`),
    KEY `idx_type` (`evidence_type`),
    KEY `idx_seized_by` (`seized_by_cid`),
    CONSTRAINT `fk_evidence_case` FOREIGN KEY (`case_id`) REFERENCES `cases` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Vehicle Checks table
CREATE TABLE IF NOT EXISTS `vehicle_checks` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `plate` VARCHAR(20) NOT NULL,
    `owner_cid` VARCHAR(50) DEFAULT NULL,
    `owner_name` VARCHAR(100) DEFAULT NULL,
    `vehicle_model` VARCHAR(50) DEFAULT NULL,
    `checked_by_cid` VARCHAR(50) NOT NULL,
    `notes` TEXT DEFAULT NULL,
    `last_checked_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_plate` (`plate`),
    KEY `idx_owner` (`owner_cid`),
    KEY `idx_checked_by` (`checked_by_cid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Criminal Records table
CREATE TABLE IF NOT EXISTS `criminal_records` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `case_id` INT DEFAULT NULL,
    `offense` VARCHAR(200) NOT NULL,
    `sentence` VARCHAR(200) DEFAULT NULL,
    `fine` INT DEFAULT NULL,
    `date` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `officer_cid` VARCHAR(50) NOT NULL,
    `notes` TEXT DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_citizenid` (`citizenid`),
    KEY `idx_case` (`case_id`),
    KEY `idx_date` (`date`),
    CONSTRAINT `fk_record_case` FOREIGN KEY (`case_id`) REFERENCES `cases` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Warrants table
CREATE TABLE IF NOT EXISTS `warrants` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `case_id` INT DEFAULT NULL,
    `type` ENUM('arrest', 'search') NOT NULL DEFAULT 'arrest',
    `reason` TEXT NOT NULL,
    `issued_by_cid` VARCHAR(50) NOT NULL,
    `expires_at` DATETIME DEFAULT NULL,
    `status` ENUM('active', 'executed', 'expired', 'cancelled') NOT NULL DEFAULT 'active',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_citizenid` (`citizenid`),
    KEY `idx_status` (`status`),
    CONSTRAINT `fk_warrant_case` FOREIGN KEY (`case_id`) REFERENCES `cases` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
