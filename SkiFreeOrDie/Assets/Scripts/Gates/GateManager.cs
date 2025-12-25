// Assets/Scripts/Gates/GateManager.cs
using UnityEngine;
using System.Collections.Generic;

public class GateManager : MonoBehaviour
{
    [Header("Settings")]
    [SerializeField] private float penaltyPerMiss = 3f;
    [SerializeField] private float missDetectionBuffer = 2f; // How far past gate before marked as missed

    [Header("References")]
    [SerializeField] private Transform player;

    [Header("State")]
    [SerializeField] private int totalGates;
    [SerializeField] private int gatesPassed;
    [SerializeField] private int gatesMissed;

    private List<GateData> gates = new List<GateData>();
    private int nextGateIndex = 0;

    public int TotalGates => totalGates;
    public int GatesPassed => gatesPassed;
    public int GatesMissed => gatesMissed;
    public float TotalPenalty => gatesMissed * penaltyPerMiss;
    public float PenaltyPerMiss => penaltyPerMiss;

    public event System.Action<GateData> OnGatePassed;
    public event System.Action<GateData, float> OnGateMissed;

    private void Update()
    {
        if (player != null)
        {
            CheckPlayerPosition(player.position.y);
        }
    }

    public void SetPlayer(Transform playerTransform)
    {
        player = playerTransform;
    }

    public void RegisterGate(GateData gateData)
    {
        gates.Add(gateData);
        totalGates = gates.Count;
        // Sort by Y position (descending, since player moves down)
        gates.Sort((a, b) => b.YPosition.CompareTo(a.YPosition));
        ReindexGates();
    }

    private void ReindexGates()
    {
        for (int i = 0; i < gates.Count; i++)
        {
            gates[i].GateIndex = i;
        }
    }

    public void NotifyGatePassed(GateData gate)
    {
        if (gate.State != GateState.Pending) return;

        // Check for any missed gates before this one
        CheckForMissedGates(gate.YPosition);

        gate.MarkPassed();
        gatesPassed++;
        nextGateIndex = gate.GateIndex + 1;

        OnGatePassed?.Invoke(gate);
    }

    public void CheckPlayerPosition(float playerY)
    {
        // Check if player has passed any gates without triggering them
        for (int i = nextGateIndex; i < gates.Count; i++)
        {
            var gate = gates[i];
            if (gate.State != GateState.Pending) continue;

            // If player Y is below gate Y by buffer amount, they missed it
            if (playerY < gate.YPosition - missDetectionBuffer)
            {
                MarkGateMissed(gate);
            }
            else
            {
                break; // Gates are sorted, so stop checking
            }
        }
    }

    private void CheckForMissedGates(float currentGateY)
    {
        foreach (var gate in gates)
        {
            if (gate.State != GateState.Pending) continue;
            if (gate.YPosition > currentGateY)
            {
                MarkGateMissed(gate);
            }
        }
    }

    private void MarkGateMissed(GateData gate)
    {
        gate.MarkMissed();
        gatesMissed++;
        nextGateIndex = gate.GateIndex + 1;

        OnGateMissed?.Invoke(gate, penaltyPerMiss);
    }

    public void Clear()
    {
        gates.Clear();
        totalGates = 0;
        gatesPassed = 0;
        gatesMissed = 0;
        nextGateIndex = 0;
    }

    public GateData GetGate(int index)
    {
        if (index >= 0 && index < gates.Count)
        {
            return gates[index];
        }
        return null;
    }
}
