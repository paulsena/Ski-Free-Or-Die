// Assets/Tests/EditMode/SkierStatsTests.cs
using NUnit.Framework;

public class SkierStatsTests
{
    [Test]
    public void BaseSpeed_ReturnsConfiguredValue()
    {
        var stats = new SkierStats(baseSpeed: 10f);
        Assert.AreEqual(10f, stats.BaseSpeed);
    }

    [Test]
    public void TuckSpeedMultiplier_IsWithinDesignRange()
    {
        var stats = new SkierStats(baseSpeed: 10f, tuckBonus: 0.12f);
        // Design spec: 10-15% boost
        Assert.GreaterOrEqual(stats.TuckBonus, 0.10f);
        Assert.LessOrEqual(stats.TuckBonus, 0.15f);
    }

    [Test]
    public void GetEffectiveSpeed_WithTuck_AppliesBonus()
    {
        var stats = new SkierStats(baseSpeed: 100f, tuckBonus: 0.12f);
        float tuckedSpeed = stats.GetEffectiveSpeed(isTucking: true, slopeMultiplier: 1f);
        Assert.AreEqual(112f, tuckedSpeed, 0.01f);
    }

    [Test]
    public void GetEffectiveSpeed_WithSteepSlope_IncreasesSpeed()
    {
        var stats = new SkierStats(baseSpeed: 100f, tuckBonus: 0.12f);
        float steepSpeed = stats.GetEffectiveSpeed(isTucking: false, slopeMultiplier: 1.3f);
        Assert.AreEqual(130f, steepSpeed, 0.01f);
    }
}
