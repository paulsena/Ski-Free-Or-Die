// Assets/Tests/EditMode/TileDataTests.cs
using NUnit.Framework;
using System.Collections.Generic;

public class TileDataTests
{
    [Test]
    public void TileData_StoresObstaclePositions()
    {
        var obstacles = new List<ObstacleSpawn>
        {
            new ObstacleSpawn(ObstacleType.SmallTree, 0.2f, 0.5f),
            new ObstacleSpawn(ObstacleType.Rock, 0.8f, 0.3f)
        };

        var tile = new TileData(TileType.ObstacleField, SlopeIntensity.Moderate, obstacles);

        Assert.AreEqual(2, tile.Obstacles.Count);
        Assert.AreEqual(ObstacleType.SmallTree, tile.Obstacles[0].Type);
    }

    [Test]
    public void TileData_HasSlopeIntensity()
    {
        var tile = new TileData(TileType.Speed, SlopeIntensity.Steep, new List<ObstacleSpawn>());

        Assert.AreEqual(SlopeIntensity.Steep, tile.Slope);
        Assert.AreEqual(1.3f, tile.GetSlopeMultiplier(), 0.01f);
    }
}
