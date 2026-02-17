# Spell Clash - Battle Royale

A fast-paced magical Battle Royale game with fighting-game inspired spell casting mechanics.

## Features

### Core Gameplay

- **Battle Royale Mode**: Last wizard standing wins
- **Shrinking Zone**: "Aetherial Crucible" forces players into combat
- **Spell Combo System**: Fighting-game style directional inputs
- **Clash Mechanic**: Same spells cast simultaneously cancel each other

### Characters

- **Player**: Controlled wizard with keyboard/controller input
- **Bots**: AI opponents that can cast spells and hunt players
- **Minions**: PvE creeps that drop loot when killed
- **Dummies**: Training targets for testing spells

### Bot AI Features (NEW)

The bot system implements intelligent AI opponents with the following capabilities:

#### Behavior

- **Wander Mode**: Patrols randomly when no target is nearby
- **Chase Mode**: Pursues players within aggro radius (300 units)
- **Spell Casting**: Uses varied spells with intelligent cooldown management
- **Dynamic Combat**: Changes spell preferences every 8 seconds for unpredictability

#### Spell Arsenal

Bots can cast 4 different spell types:

1. **Fireball** (3s cooldown) - Direct projectile attack
2. **Lightning** (4s cooldown) - Area of effect at target location
3. **Beam** (5s cooldown) - Continuous damage beam
4. **Plant** (6s cooldown) - Shoots 3-fireball spread pattern

#### Stats

- Health: 40 HP
- Speed: 40 (wander: 30, chase: 60)
- Aggro Range: 300 units
- Cast Range: 250 units
- Attack Interval: 2.5 seconds

#### Loot Drops

- 80% chance to drop a spell book when killed
- Random spell book selection (Fireball, Lightning, Beam, or Plant)

### Spell System

- **Tier 1 Spells**: Fireball, Lightning, Beam, Plant
- **Ultimate Spells**: Enhanced versions unlocked by collecting spell books
- **Spell Enhancement**: Collect duplicates to upgrade existing spells

### Progression

- **PvE**: Kill creeps for XP and stat boosts (50% chance)
- **PvP**: Kill players for guaranteed major stat boosts
  - +2% Spell Damage
  - +5% Health

## Files Structure

- `bot.gd` / `bot.tscn` - AI bot implementation
- `player*.gd` / `player*.tscn` - Player character files
- `minion.gd` / `minion.tscn` - PvE creeps
- `enemy.gd` / `enemy.tscn` - Basic enemy AI
- `world.gd` / `world.tscn` - Main game scene with zone mechanics
- `spells/` - Player spell implementations
- `spells_enemy/` - Enemy/Bot spell implementations
- `book_spells/` - Collectible spell books

## Usage

### Adding Bots to a Scene

1. Open your scene in Godot
2. Instance `bot.tscn`
3. Position as desired
4. Bots will automatically search for and attack players

### Bot Configuration

Edit `bot.gd` to customize:

- Speed values (wander/chase)
- Aggro and cast ranges
- Cooldown durations
- Health values
- Spell preferences

## Development Notes

- Bots use the same collision system as minions
- Spell scenes are preloaded for performance
- Animation system uses goblin sprite sheets
- AI uses state-based behavior (wander/chase/cast)
