// Assets/Tests/EditMode/GateManagerTests.cs
using NUnit.Framework;
using UnityEngine;

public class GateManagerTests
{
    private GateManager CreateManager()
    {
        var go = new GameObject("TestGateManager");
        return go.AddComponent<GateManager>();
    }

    [TearDown]
    public void TearDown()
    {
        // Clean up test objects
        foreach (var go in Object.FindObjectsOfType<GateManager>())
        {
            Object.DestroyImmediate(go.gameObject);
        }
    }

    [Test]
    public void RegisterGate_IncrementsTotal()
    {
        var manager = CreateManager();

        manager.RegisterGate(new GateData(0, 0f, -10f));
        manager.RegisterGate(new GateData(1, 0f, -30f));

        Assert.AreEqual(2, manager.TotalGates);
    }

    [Test]
    public void NotifyGatePassed_IncrementsPassedCount()
    {
        var manager = CreateManager();
        var gate = new GateData(0, 0f, -10f);
        manager.RegisterGate(gate);

        manager.NotifyGatePassed(gate);

        Assert.AreEqual(1, manager.GatesPassed);
        Assert.AreEqual(GateState.Passed, gate.State);
    }

    [Test]
    public void TotalPenalty_CalculatesCorrectly()
    {
        var manager = CreateManager();
        var gate1 = new GateData(0, 0f, -10f);
        var gate2 = new GateData(1, 0f, -30f);
        manager.RegisterGate(gate1);
        manager.RegisterGate(gate2);

        // Skip first gate, pass second (first should be missed)
        manager.NotifyGatePassed(gate2);

        Assert.AreEqual(1, manager.GatesMissed);
        Assert.AreEqual(3f, manager.TotalPenalty); // Default 3s penalty
    }

    [Test]
    public void CheckPlayerPosition_DetectsMissedGates()
    {
        var manager = CreateManager();
        var gate = new GateData(0, 0f, -10f);
        manager.RegisterGate(gate);

        // Player at Y = -15 (past the gate at -10, with buffer of 2)
        manager.CheckPlayerPosition(-15f);

        Assert.AreEqual(1, manager.GatesMissed);
        Assert.AreEqual(GateState.Missed, gate.State);
    }
}
