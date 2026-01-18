# World Generation

## File Locations
- `src/world/tile_generator.lua` - Course generation, difficulty phases, pacing rules
- `src/world/tile_data.lua` - Tile templates, constants, obstacle types
- `src/world/world_manager.lua` - Spawn/despawn, entity instantiation
- `src/lib/seeded_random.lua` - Deterministic LCG-based RNG

## Tile Templates (in `tile_data.lua`)
| Template | Type | Difficulty | Obstacles | Gates |
|----------|------|------------|-----------|-------|
| `warmup` | WARMUP | 1 | small_tree (0.2) | 0-1 wide |
| `slalom_easy` | SLALOM | 2 | none | 2-3 wide |
| `slalom_medium` | SLALOM | 3 | small_tree (0.3) | 3-4 normal |
| `slalom_hard` | SLALOM | 4 | trees (0.5) | 4-5 tight |
| `obstacle_forest` | OBSTACLE_FIELD | 3 | trees (0.7) | none |
| `obstacle_rocks` | OBSTACLE_FIELD | 4 | rock (0.5) | none |
| `obstacle_mixed` | OBSTACLE_FIELD | 5 | all types (0.8) | none |
| `speed` | SPEED | 1 | small_tree (0.1) | none |
| `ramp` | RAMP | 3 | small_tree (0.2) | none |

## Difficulty Phases (in `tile_generator.lua`)
| Phase | Progress | Diff Range | Templates Used |
|-------|----------|------------|----------------|
| warmup | 0-25% | 1-2 | warmup, slalom_easy |
| rising | 25-50% | 2-3 | slalom variants, obstacle_forest |
| challenge | 50-75% | 3-4 | slalom_hard, obstacle_rocks |
| climax | 75-100% | 4-5 | obstacle_mixed, hard content |

## Set Pieces (tile indices 8, 15 in 20-tile course)
| Name | Description |
|------|-------------|
| `cabin_chicane` | Tight weave between 4 cabins |
| `the_gauntlet` | Dense obstacles with narrow center path |
| `ski_lift_alley` | Parallel tree rows forming corridor |
| `spectator_row` | Empty steep slope (speed section) |

## Key Constants
- `TILE_HEIGHT = 400` (3-5 seconds of skiing)
- `TILE_WIDTH = 340` (skiable area)
- `TRANSITION_ZONE = 50` (obstacle-free edges)
- `TIME_TRIAL_TILES = 20` (60-90 second course)

## Spawn/Despawn (world_manager.lua)
- `SPAWN_AHEAD`: Generate tiles ahead of camera
- `DESPAWN_BEHIND`: Remove entities behind camera
- Time trial: Full course generated at start
- Endless: Tiles generated on-demand, max difficulty at tile 30

## Seeded RNG Usage
```lua
local rng = SeededRandom.new(seed)
rng:random()           -- [0, 1)
rng:random_int(1, 10)  -- inclusive
rng:choose(array)      -- random element
rng:reset()            -- restart sequence
```

## Adding New Content
1. **New tile template**: Add to `TILE_TEMPLATES` in `tile_data.lua`
2. **New set piece**: Add to `populate_set_piece()` in `tile_generator.lua`
3. **New obstacle type**: Update `obstacle_types` arrays in templates
4. **Adjust difficulty curve**: Modify `DIFFICULTY_PHASES` breakpoints

## Common Tasks

**Add new tile template:**
1. Add template to `TILE_TEMPLATES` in `src/world/tile_data.lua` (line 60)
2. Reference in `get_valid_templates()` phase selection in `tile_generator.lua` (line 161)

**Add new set piece:**
1. Add to `set_pieces` array in `generate_set_piece_tile()` at `tile_generator.lua:136`
2. Add `elseif` branch in `populate_set_piece()` at `tile_generator.lua:295`
3. Add tile index to `SET_PIECE_POSITIONS` at `tile_generator.lua:24`

**Change course length:**
- Edit `TIME_TRIAL_TILES` in `src/world/tile_generator.lua` (line 12)

**Adjust difficulty progression:**
- Modify phase breakpoints in `DIFFICULTY_PHASES` at `tile_generator.lua:16-21`

**Add new obstacle type:**
1. Add to `obstacle_types` array in relevant templates in `tile_data.lua` (lines 60-153)
2. Ensure `Obstacle` entity supports the type in `src/entities/obstacle.lua`
