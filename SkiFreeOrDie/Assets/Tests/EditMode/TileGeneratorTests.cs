// Assets/Tests/EditMode/TileGeneratorTests.cs
using NUnit.Framework;

public class TileGeneratorTests
{
    [Test]
    public void SameSeed_GeneratesSameTiles()
    {
        var gen1 = new TileGenerator(12345);
        var gen2 = new TileGenerator(12345);

        var tiles1 = gen1.GenerateCourse(10);
        var tiles2 = gen2.GenerateCourse(10);

        Assert.AreEqual(tiles1.Count, tiles2.Count);
        for (int i = 0; i < tiles1.Count; i++)
        {
            Assert.AreEqual(tiles1[i].Type, tiles2[i].Type);
            Assert.AreEqual(tiles1[i].Slope, tiles2[i].Slope);
        }
    }

    [Test]
    public void FirstTile_IsAlwaysWarmup()
    {
        var gen = new TileGenerator(99999);
        var tiles = gen.GenerateCourse(10);

        Assert.AreEqual(TileType.Warmup, tiles[0].Type);
        Assert.AreEqual(SlopeIntensity.Gentle, tiles[0].Slope);
    }

    [Test]
    public void DifficultyIncreases_OverCourse()
    {
        var gen = new TileGenerator(12345);
        var tiles = gen.GenerateCourse(20);

        // Count steep slopes in first half vs second half
        int steepFirstHalf = 0;
        int steepSecondHalf = 0;

        for (int i = 0; i < 10; i++)
        {
            if (tiles[i].Slope == SlopeIntensity.Steep) steepFirstHalf++;
        }
        for (int i = 10; i < 20; i++)
        {
            if (tiles[i].Slope == SlopeIntensity.Steep) steepSecondHalf++;
        }

        Assert.GreaterOrEqual(steepSecondHalf, steepFirstHalf);
    }
}
