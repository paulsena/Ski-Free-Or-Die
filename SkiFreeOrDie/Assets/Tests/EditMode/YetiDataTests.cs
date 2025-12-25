// Assets/Tests/EditMode/YetiDataTests.cs
using NUnit.Framework;

public class YetiDataTests
{
    [Test]
    public void GetCurrentSpeed_StartsAtBase()
    {
        var data = new YetiData();
        float speed = data.GetCurrentSpeed(0f);
        Assert.AreEqual(data.BaseSpeed, speed, 0.01f);
    }

    [Test]
    public void GetCurrentSpeed_ReachesMaxAtRampTime()
    {
        var data = new YetiData();
        float speed = data.GetCurrentSpeed(data.SpeedRampTime);
        Assert.AreEqual(data.MaxSpeed, speed, 0.01f);
    }

    [Test]
    public void GetCurrentSpeed_CapsAtMax()
    {
        var data = new YetiData();
        float speed = data.GetCurrentSpeed(data.SpeedRampTime * 2);
        Assert.AreEqual(data.MaxSpeed, speed, 0.01f);
    }

    [Test]
    public void GetZone_ReturnsSafe_WhenFarAway()
    {
        var data = new YetiData();
        Assert.AreEqual(YetiZone.Safe, data.GetZone(100f));
    }

    [Test]
    public void GetZone_ReturnsWarning_WhenCloser()
    {
        var data = new YetiData();
        Assert.AreEqual(YetiZone.Warning, data.GetZone(40f));
    }

    [Test]
    public void GetZone_ReturnsDanger_WhenClose()
    {
        var data = new YetiData();
        Assert.AreEqual(YetiZone.Danger, data.GetZone(20f));
    }

    [Test]
    public void GetZone_ReturnsCritical_WhenVeryClose()
    {
        var data = new YetiData();
        Assert.AreEqual(YetiZone.Critical, data.GetZone(5f));
    }

    [Test]
    public void HasCaughtPlayer_ReturnsFalse_WhenFar()
    {
        var data = new YetiData();
        Assert.IsFalse(data.HasCaughtPlayer(10f));
    }

    [Test]
    public void HasCaughtPlayer_ReturnsTrue_WhenCaught()
    {
        var data = new YetiData();
        Assert.IsTrue(data.HasCaughtPlayer(1f));
    }
}
