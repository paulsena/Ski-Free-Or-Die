// Assets/Scripts/Gates/GateData.cs
using UnityEngine;

public enum GateState
{
    Pending,
    Passed,
    Missed
}

[System.Serializable]
public class GateData
{
    public int GateIndex;
    public float YPosition;
    public float XPosition;
    public GateState State;

    public GateData(int index, float x, float y)
    {
        GateIndex = index;
        XPosition = x;
        YPosition = y;
        State = GateState.Pending;
    }

    public void MarkPassed()
    {
        if (State == GateState.Pending)
        {
            State = GateState.Passed;
        }
    }

    public void MarkMissed()
    {
        if (State == GateState.Pending)
        {
            State = GateState.Missed;
        }
    }

    public bool IsPending => State == GateState.Pending;
    public bool IsPassed => State == GateState.Passed;
    public bool IsMissed => State == GateState.Missed;
}

[System.Serializable]
public class GateSpawn
{
    public float NormalizedX; // 0-1 across tile width
    public float NormalizedY; // 0-1 along tile height

    public GateSpawn(float x, float y)
    {
        NormalizedX = x;
        NormalizedY = y;
    }
}
