# Configuration Reference

Quick reference for all tweakable game constants. Use this to tune game feel.

## Display Settings (`src/core/config.lua`, `conf.lua`)

| Constant | Value | Description |
|----------|-------|-------------|
| `GAME_WIDTH` | 360 | Native game width (3:4 portrait) |
| `GAME_HEIGHT` | 480 | Native game height |
| `SCALE` | 3 | Pixel scaling (final: 1080x1440) |
| `SIDEBAR_WIDTH` | 400 | UI sidebar width each side |

## Skier Physics (`src/entities/skier.lua`)

| Constant | Value | Description |
|----------|-------|-------------|
| `BASE_SPEED` | 140 | Default downhill speed (px/sec) |
| `MAX_SPEED` | 320 | Speed cap |
| `TUCK_SPEED_BONUS` | 0.30 | +30% speed when tucking |
| `CRASH_DURATION` | 1.0 | Seconds to recover from crash |
| `IMMUNITY_DURATION` | 1.0 | Invincibility after recovery |
| `HITBOX_RADIUS` | 8 | Collision radius (forgiving) |
| `DEFLECT_VX_FACTOR` | 0.8 | X velocity reversal on deflect |
| `SPEED_LERP_FACTOR` | 4 | Acceleration smoothing |
| `STOP_LERP_FACTOR` | 3 | Deceleration inertia |
| `STOPPED_THRESHOLD` | 5 | Speed below = stopped |
| `SIDEWAYS_PUSH_SPEED` | 60 | Cross-country push speed |

## Mouse Control Zones (`src/entities/skier.lua`)

| Constant | Value | Description |
|----------|-------|-------------|
| `ZONE_CENTER` | 30 | 0-30px = straight (deadzone) |
| `ZONE_GENTLE` | 80 | 31-80px = gentle turn |
| `ZONE_SHARP` | 140 | 81-140px = sharp turn |
| (beyond) | 141+ | Full brake/stop turn |

## Yeti Settings (`src/entities/yeti.lua`)

| Constant | Value | Description |
|----------|-------|-------------|
| `BASE_SPEED` | 70 | Yeti chase speed |
| `SPEED_INCREASE_RATE` | 0.01 | Speed gain per second |
| `CATCH_DISTANCE` | 30 | Distance to catch player |
| `START_DISTANCE` | -300 | Initial spawn behind player |
| `BOOST_ON_CRASH` | 1.5 | Speed mult when player crashes |
| `ZONE_SAFE` | 500 | Safe distance threshold |
| `ZONE_WARNING` | 350 | Warning zone starts |
| `ZONE_DANGER` | 150 | Danger zone starts |
| `ZONE_CRITICAL` | 75 | About to catch |

## Gate/Spawn Settings (`src/core/config.lua`)

| Constant | Value | Description |
|----------|-------|-------------|
| `GATE_PENALTY` | 3 | Seconds added for missed gate |
| `GATE_WIDTH` | 75 | Gate width in pixels |
| `SPAWN_AHEAD` | 550 | Spawn distance ahead of camera |
| `DESPAWN_BEHIND` | 300 | Cleanup distance behind camera |

## Difficulty (`src/core/config.lua`)

| Constant | Value | Description |
|----------|-------|-------------|
| `DIFFICULTY_INCREASE_RATE` | 0.5 | Increase per 5000 pixels |
| `MAX_DIFFICULTY` | 2.0 | Difficulty cap |

## Tile System (`src/world/tile_data.lua`)

| Constant | Value | Description |
|----------|-------|-------------|
| `TILE_HEIGHT` | 400 | Tile length (3-5 sec skiing) |
| `TILE_WIDTH` | 340 | Skiable area width |
| `TRANSITION_ZONE` | 50 | Safe zone at tile edges |
| `GATE_SPACING.wide` | 120 | Easy gate spacing |
| `GATE_SPACING.normal` | 100 | Medium gate spacing |
| `GATE_SPACING.tight` | 75 | Hard gate spacing |

## Slope Multipliers (`src/world/tile_data.lua`)

| Slope | Multiplier | Effect |
|-------|------------|--------|
| gentle | 0.85 | -15% speed |
| moderate | 1.0 | Normal |
| steep | 1.2 | +20% speed |

## Common Tasks

**Make game faster:**
- Increase `BASE_SPEED` and `MAX_SPEED` in `src/entities/skier.lua`

**Make yeti more aggressive:**
- Increase `BASE_SPEED` or `BOOST_ON_CRASH` in `src/entities/yeti.lua`
- Decrease `START_DISTANCE` (less negative = closer spawn)

**Adjust difficulty curve:**
- Edit `DIFFICULTY_INCREASE_RATE` in `src/core/config.lua`
- Lower `MAX_DIFFICULTY` to cap how hard it gets

**Make controls more responsive:**
- Increase `SPEED_LERP_FACTOR` in `src/entities/skier.lua` for snappier acceleration
- Decrease `ZONE_CENTER` for smaller deadzone

**Adjust gate challenge:**
- Decrease `GATE_WIDTH` in `src/core/config.lua` for harder gates
- Increase `GATE_PENALTY` for harsher miss penalties
