// Assets/Scripts/World/TileData.cs
using System.Collections.Generic;

[System.Serializable]
public class ObstacleSpawn
{
    public ObstacleType Type;
    public float NormalizedX; // 0-1 across tile width
    public float NormalizedY; // 0-1 along tile height

    public ObstacleSpawn(ObstacleType type, float x, float y)
    {
        Type = type;
        NormalizedX = x;
        NormalizedY = y;
    }
}

[System.Serializable]
public class TileData
{
    public TileType Type;
    public SlopeIntensity Slope;
    public List<ObstacleSpawn> Obstacles;
    public List<GateSpawn> Gates;

    public TileData(TileType type, SlopeIntensity slope, List<ObstacleSpawn> obstacles, List<GateSpawn> gates = null)
    {
        Type = type;
        Slope = slope;
        Obstacles = obstacles ?? new List<ObstacleSpawn>();
        Gates = gates ?? new List<GateSpawn>();
    }

    public float GetSlopeMultiplier()
    {
        return Slope switch
        {
            SlopeIntensity.Gentle => 0.8f,
            SlopeIntensity.Moderate => 1.0f,
            SlopeIntensity.Steep => 1.3f,
            _ => 1.0f
        };
    }
}
