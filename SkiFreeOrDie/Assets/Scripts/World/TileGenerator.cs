// Assets/Scripts/World/TileGenerator.cs
using System.Collections.Generic;

public class TileGenerator
{
    private readonly SeededRandom rng;
    private bool alternateGateSide = false;
    private TileType previousType = TileType.Warmup;
    private int hardTilesInRow = 0;

    public TileGenerator(int seed)
    {
        rng = new SeededRandom(seed);
    }

    /// <summary>
    /// Generate a single tile for endless mode progression.
    /// </summary>
    public TileData GenerateSingleTile(float progress)
    {
        var tile = GenerateTile(progress, previousType, ref hardTilesInRow);
        previousType = tile.Type;
        return tile;
    }

    public List<TileData> GenerateCourse(int tileCount)
    {
        var tiles = new List<TileData>();
        TileType previousType = TileType.Warmup;
        int hardTilesInRow = 0;

        for (int i = 0; i < tileCount; i++)
        {
            float progress = (float)i / tileCount;
            var tile = GenerateTile(progress, previousType, ref hardTilesInRow);
            tiles.Add(tile);
            previousType = tile.Type;
        }

        return tiles;
    }

    private TileData GenerateTile(float progress, TileType previousType, ref int hardTilesInRow)
    {
        // First tile is always warmup
        if (progress < 0.05f)
        {
            hardTilesInRow = 0;
            return new TileData(TileType.Warmup, SlopeIntensity.Gentle, GenerateObstacles(TileType.Warmup, 0));
        }

        // Determine difficulty based on progress
        int difficulty = GetDifficultyRating(progress);

        // Pacing rule: after hard tile, add a speed tile
        if (hardTilesInRow >= 2)
        {
            hardTilesInRow = 0;
            return new TileData(TileType.Speed, SlopeIntensity.Steep, GenerateObstacles(TileType.Speed, difficulty));
        }

        // Choose tile type based on difficulty
        TileType type = ChooseTileType(difficulty);
        SlopeIntensity slope = ChooseSlopeIntensity(difficulty);

        if (difficulty >= 4)
        {
            hardTilesInRow++;
        }
        else
        {
            hardTilesInRow = 0;
        }

        var obstacles = GenerateObstacles(type, difficulty);
        var gates = type == TileType.Slalom ? GenerateGates(difficulty) : null;

        return new TileData(type, slope, obstacles, gates);
    }

    private int GetDifficultyRating(float progress)
    {
        // 1-5 scale based on progress
        if (progress < 0.25f) return rng.NextInt(1, 3);
        if (progress < 0.50f) return rng.NextInt(2, 4);
        if (progress < 0.75f) return rng.NextInt(3, 5);
        return rng.NextInt(4, 6);
    }

    private TileType ChooseTileType(int difficulty)
    {
        TileType[] options = difficulty switch
        {
            1 or 2 => new[] { TileType.Warmup, TileType.Speed, TileType.ObstacleField },
            3 or 4 => new[] { TileType.ObstacleField, TileType.Slalom, TileType.Speed },
            _ => new[] { TileType.ObstacleField, TileType.Slalom, TileType.Ramp }
        };
        return rng.Choose(options);
    }

    private SlopeIntensity ChooseSlopeIntensity(int difficulty)
    {
        return difficulty switch
        {
            1 or 2 => SlopeIntensity.Gentle,
            3 => rng.NextFloat() > 0.5f ? SlopeIntensity.Moderate : SlopeIntensity.Gentle,
            4 => rng.NextFloat() > 0.5f ? SlopeIntensity.Steep : SlopeIntensity.Moderate,
            _ => SlopeIntensity.Steep
        };
    }

    private List<ObstacleSpawn> GenerateObstacles(TileType type, int difficulty)
    {
        var obstacles = new List<ObstacleSpawn>();

        int obstacleCount = type switch
        {
            TileType.Warmup => rng.NextInt(0, 2),
            TileType.Speed => rng.NextInt(0, 2),
            TileType.ObstacleField => rng.NextInt(3, 6) + difficulty,
            TileType.Slalom => rng.NextInt(1, 3), // Fewer obstacles in slalom to leave room for gates
            TileType.Ramp => rng.NextInt(1, 3),
            _ => 0
        };

        for (int i = 0; i < obstacleCount; i++)
        {
            ObstacleType obstacleType = ChooseObstacleType(difficulty);
            float x = rng.Range(0.1f, 0.9f);
            float y = rng.Range(0.1f, 0.9f);
            obstacles.Add(new ObstacleSpawn(obstacleType, x, y));
        }

        return obstacles;
    }

    private List<GateSpawn> GenerateGates(int difficulty)
    {
        var gates = new List<GateSpawn>();

        // Number of gates based on difficulty (2-4 gates per slalom tile)
        int gateCount = difficulty switch
        {
            1 or 2 => 2,
            3 or 4 => 3,
            _ => 4
        };

        // Distribute gates evenly along the tile height
        for (int i = 0; i < gateCount; i++)
        {
            // Normalized Y position (0 = top of tile, 1 = bottom)
            float normalizedY = (float)(i + 1) / (gateCount + 1);

            // Alternating left/right pattern for slalom
            float baseX = alternateGateSide ? 0.7f : 0.3f;
            // Add some randomness to X position
            float xOffset = rng.Range(-0.1f, 0.1f);
            float normalizedX = baseX + xOffset;

            gates.Add(new GateSpawn(normalizedX, normalizedY));

            // Toggle side for next gate
            alternateGateSide = !alternateGateSide;
        }

        return gates;
    }

    private ObstacleType ChooseObstacleType(int difficulty)
    {
        float roll = rng.NextFloat();

        if (difficulty <= 2)
        {
            // Easy: mostly small trees
            return roll < 0.8f ? ObstacleType.SmallTree : ObstacleType.LargeTree;
        }
        else if (difficulty <= 4)
        {
            // Medium: mix
            if (roll < 0.4f) return ObstacleType.SmallTree;
            if (roll < 0.7f) return ObstacleType.LargeTree;
            return ObstacleType.Rock;
        }
        else
        {
            // Hard: more dangerous
            if (roll < 0.2f) return ObstacleType.SmallTree;
            if (roll < 0.5f) return ObstacleType.LargeTree;
            if (roll < 0.8f) return ObstacleType.Rock;
            return ObstacleType.Cabin;
        }
    }
}
