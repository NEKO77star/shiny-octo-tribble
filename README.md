# shiny-octo-tribble
MAD TOWNのような街をFiveM で作成するためのコーディング

## FiveM QBCore Server - Modern Japan × Mafia Theme

A comprehensive FiveM server implementation featuring a realistic criminal economy with organizations, territories, police/justice system, and everyday life features. Inspired by VCR GTA roleplay servers.

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

**Territories** (22 zones):
- Downtown: Little Tokyo, Entertainment District, Downtown Vinewood, Pillbox Hill
- Gang Areas: Grove Street, Davis, Rancho, Strawberry
- Industrial: La Mesa, Cypress Flats, Elysian Island, Port District
- Wealthy: Vinewood, Vinewood Hills, Rockford Hills
- Coastal: Del Perro Beach, Vespucci Beach
- Rural: Sandy Shores, Grapeseed, Paleto Bay
- Other: Mirror Park

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

**Crime Types** (16 categories):
| Category | Activities |
|----------|------------|
| Drug | Meth Cooking, Weed Harvesting, Cocaine Processing, Heroin Cutting |
| Weapon | Smuggling, Modification, Ghost Gun Manufacturing |
| Robbery | Convenience Store, Liquor Store, Jewelry Store, Fleeca Bank |
| Heist | Pacific Standard, Union Depository, Diamond Casino |
| Burglary | House, Mansion, Warehouse |
| Car Theft | Street Cars, Exotic Vehicles, Contract Boosting |
| Chop Shop | Dismantling, VIN Scratching |
| Kidnapping | Ransom Operations |
| Hacking | Crypto Mining, Identity Theft |
| Smuggling | Boat, Air |
| Street Racing | Circuit Races, Pink Slip Races |
| Hitman | Contract Killing |
| Fraud | ATM Skimming, Credit Card Cloning |
| Loan Shark | Debt Collection |
| Laundering | Business Laundering |
| Protection | Protection Racket |

**Features**:
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

**Property Types** (21 types):
| Category | Types |
|----------|-------|
| Residential | Apartment, Penthouse, Mansion, Motel |
| Commercial | Shop, Restaurant, Bar, Car Dealership |
| Entertainment | Nightclub, Strip Club, Casino |
| Industrial | Warehouse, Factory, Farm |
| Organization | Gang Hideout, Bunker, MC Clubhouse |
| Storage | Garage, Hangar, Dock |
| Business | Office |

**Properties** (50+ locations):
- Apartments: Alta St, Eclipse Towers, Del Perro Heights, Integrity Way
- Penthouses: Diamond Casino, Eclipse Towers
- Mansions: Richman, Vinewood Hills, Rockford Hills
- Nightclubs: Downtown, Del Perro, Vinewood
- Bars: Yellow Jack Inn, Tequi-la-la, Bahama Mamas
- Restaurants: Burger Shot, Cluckin' Bell, Bean Machine, Little Tokyo Sushi
- Car Dealerships: Premium Deluxe Motorsport, Simeon's
- Warehouses: La Mesa, Elysian Island, Cypress Flats
- And many more...

**Features**:
- Property system (buy/rent)
- Insurance system (vehicle, health, property)
- Phone UI with apps:
  - Messages (real-time chat)
  - SNS (social network)
  - SecureChat (encrypted)
  - Bank (accounts and hidden accounts)
  - Jobs
  - Contacts
  - Settings
- Legal jobs integration
- Hobbies: Fishing, Gambling, Racing

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
