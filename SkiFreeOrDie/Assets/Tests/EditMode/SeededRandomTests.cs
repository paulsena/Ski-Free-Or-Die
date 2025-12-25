// Assets/Tests/EditMode/SeededRandomTests.cs
using NUnit.Framework;

public class SeededRandomTests
{
    [Test]
    public void SameSeed_ProducesSameSequence()
    {
        var rng1 = new SeededRandom(12345);
        var rng2 = new SeededRandom(12345);

        for (int i = 0; i < 100; i++)
        {
            Assert.AreEqual(rng1.NextFloat(), rng2.NextFloat());
        }
    }

    [Test]
    public void DifferentSeeds_ProduceDifferentSequences()
    {
        var rng1 = new SeededRandom(12345);
        var rng2 = new SeededRandom(54321);

        // Very unlikely to match
        Assert.AreNotEqual(rng1.NextFloat(), rng2.NextFloat());
    }

    [Test]
    public void Range_ReturnsValuesInBounds()
    {
        var rng = new SeededRandom(42);

        for (int i = 0; i < 1000; i++)
        {
            float value = rng.Range(10f, 20f);
            Assert.GreaterOrEqual(value, 10f);
            Assert.LessOrEqual(value, 20f);
        }
    }
}
