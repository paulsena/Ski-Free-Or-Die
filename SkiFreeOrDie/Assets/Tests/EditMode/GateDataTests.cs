// Assets/Tests/EditMode/GateDataTests.cs
using NUnit.Framework;

public class GateDataTests
{
    [Test]
    public void NewGate_StartsAsPending()
    {
        var gate = new GateData(0, 0f, -10f);
        Assert.AreEqual(GateState.Pending, gate.State);
        Assert.IsTrue(gate.IsPending);
    }

    [Test]
    public void MarkPassed_ChangesStateToPassed()
    {
        var gate = new GateData(0, 0f, -10f);
        gate.MarkPassed();
        Assert.AreEqual(GateState.Passed, gate.State);
        Assert.IsTrue(gate.IsPassed);
    }

    [Test]
    public void MarkMissed_ChangesStateToMissed()
    {
        var gate = new GateData(0, 0f, -10f);
        gate.MarkMissed();
        Assert.AreEqual(GateState.Missed, gate.State);
        Assert.IsTrue(gate.IsMissed);
    }

    [Test]
    public void MarkPassed_DoesNothing_IfAlreadyMissed()
    {
        var gate = new GateData(0, 0f, -10f);
        gate.MarkMissed();
        gate.MarkPassed();
        Assert.AreEqual(GateState.Missed, gate.State);
    }

    [Test]
    public void MarkMissed_DoesNothing_IfAlreadyPassed()
    {
        var gate = new GateData(0, 0f, -10f);
        gate.MarkPassed();
        gate.MarkMissed();
        Assert.AreEqual(GateState.Passed, gate.State);
    }
}
