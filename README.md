# shiny-octo-tribble
MAD TOWNのような街をFiveM で作成するためのコーディング

## FiveM QBCore Server - Modern Japan × Mafia Theme

A comprehensive FiveM server implementation featuring a realistic criminal economy with organizations, territories, police/justice system, and everyday life features.

### Tech Stack
- **Framework**: QBCore (Lua)
- **Server side**: Lua
- **Client side UI**: NUI (JavaScript + HTML/CSS)
- **Database**: MySQL / MariaDB
- **Inventory**: ox_inventory (can be replaced later if needed)

---

## Resources

### 1. org_system - Organization & Territory System
**Location**: `resources/org_system/`

Manages organizations (mafia, gangs, companies, shops), members, assets, and territories.

**Features**:
- Create/disband organizations
- Member management (invite, kick, promote, demote)
- Salary and revenue share configuration
- Hidden accounts (yen and crypto)
- Territory control and conflicts
- Activity logging

**Database Tables**:
- `organizations`
- `organization_members`
- `org_assets`
- `hidden_accounts`
- `territories`
- `territory_conflicts`
- `org_logs`

**Key Bindings**:
- `F6` - Open Organization Menu

---

### 2. economy_system - Criminal Economy System
**Location**: `resources/economy_system/`

Implements criminal activities with dynamic market pricing based on supply and police confiscations.

**Features**:
- Criminal activities (drug production, weapon smuggling, fraud, laundering)
- Dynamic market pricing
- Reward calculation with territory bonuses
- Organization revenue sharing
- Police confiscation system
- Money laundering

**Database Tables**:
- `criminal_activities`
- `market_index`
- `activity_logs`
- `player_cooldowns`

**Key Bindings**:
- `F7` - Open Criminal Activities Menu

---

### 3. police_system - Police & Justice System
**Location**: `resources/police_system/`

Full investigation, prosecution, and court system for realistic justice roleplay.

**Features**:
- Case management with suspects, witnesses, victims
- Evidence collection and chain of custody
- Vehicle and person lookups
- Warrant system
- Prosecution and sentencing
- Criminal records
- Asset seizure integration

**Database Tables**:
- `cases`
- `case_suspects`
- `evidence`
- `vehicle_checks`
- `criminal_records`
- `warrants`

**Authorized Jobs**:
- `police` - Police Department
- `doj` - Department of Justice

**Key Bindings**:
- `F5` - Open Police MDT

---

### 4. life_system - Life & Roleplay System
**Location**: `resources/life_system/`

Everyday life features including properties, insurance, phone, and hobbies.

**Features**:
- Property system (buy/rent apartments, offices, shops)
- Insurance system (vehicle, health, property)
- Phone UI with apps:
  - Messages (real-time chat)
  - SNS (social network)
  - Bank (accounts and hidden accounts)
  - Contacts
  - Settings
- Legal jobs integration
- Fishing hobby

**Database Tables**:
- `properties`
- `insurances`
- `phone_contacts`
- `phone_messages`
- `sns_posts`
- `secure_chat_rooms`
- `secure_chat_messages`
- `job_completions`

**Key Bindings**:
- `F1` - Open Phone
- `/fish` - Start fishing (near fishing spots)

---

## Installation

### Prerequisites
- FiveM Server
- QBCore Framework
- oxmysql
- ox_inventory

### Setup

1. Copy the `resources` folder contents to your server's resources folder

2. Import the SQL schemas:
```sql
-- Run each schema file in order:
-- resources/org_system/sql/schema.sql
-- resources/economy_system/sql/schema.sql
-- resources/police_system/sql/schema.sql
-- resources/life_system/sql/schema.sql
```

3. Add to your `server.cfg`:
```cfg
ensure qb-core
ensure oxmysql
ensure ox_inventory

ensure org_system
ensure economy_system
ensure police_system
ensure life_system
```

4. Configure each resource's `config.lua` as needed

---

## Event Naming Convention

- **Server events**: `server:<system>:<action>`
- **Client events**: `client:<system>:<action>`
- **Callbacks**: `qb_<system>:server:<callback_name>`

Examples:
- `server:economy:startActivity`
- `client:org:updateOrgUI`
- `qb_police:server:getCases`

---

## Player Identification

- Uses QBCore `citizenid` as the main player identifier
- Organization ID uses integer `org_id` (AUTO_INCREMENT)

---

## Roles

### Legal Jobs
- `police` - Police Department
- `doj` - Prosecutors / Court Staff
- `ems` - Medical

### Illegal Organizations
- `yakuza` - Mafia
- `hangure` - Semi-gang

### Organization Roles
- `boss` - Full permissions
- `executive` - Management permissions
- `member` - Limited permissions
- `associate` - Basic membership

---

## License

This project is for educational and roleplay purposes.
