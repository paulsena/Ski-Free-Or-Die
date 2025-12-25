// Assets/Scripts/Player/TurnCalculator.cs
using UnityEngine;

public class TurnCalculator
{
    private readonly float lowSpeedThreshold;
    private readonly float highSpeedThreshold;
    private readonly float maxSpeed;
    private readonly float tuckTurnPenalty;
    private readonly float baseTurnRadius;

    public TurnCalculator(
        float lowSpeedThreshold,
        float highSpeedThreshold,
        float maxSpeed,
        float tuckTurnPenalty = 0.6f,
        float baseTurnRadius = 1f)
    {
        this.lowSpeedThreshold = lowSpeedThreshold;
        this.highSpeedThreshold = highSpeedThreshold;
        this.maxSpeed = maxSpeed;
        this.tuckTurnPenalty = tuckTurnPenalty;
        this.baseTurnRadius = baseTurnRadius;
    }

    /// <summary>
    /// Returns turn responsiveness from 0 (sluggish) to 1 (instant).
    /// </summary>
    public float GetTurnResponse(float currentSpeed)
    {
        if (currentSpeed <= lowSpeedThreshold)
        {
            return 1f; // Direct control at low speed
        }
        else if (currentSpeed >= highSpeedThreshold)
        {
            // Momentum-based at high speed (0.3 to 0.5 range)
            float highSpeedFactor = Mathf.InverseLerp(highSpeedThreshold, maxSpeed, currentSpeed);
            return Mathf.Lerp(0.5f, 0.3f, highSpeedFactor);
        }
        else
        {
            // Blend in transition zone
            float t = Mathf.InverseLerp(lowSpeedThreshold, highSpeedThreshold, currentSpeed);
            return Mathf.Lerp(1f, 0.5f, t);
        }
    }

    /// <summary>
    /// Returns turn radius multiplier. Higher = wider turns.
    /// </summary>
    public float GetTurnRadius(bool isTucking)
    {
        if (isTucking)
        {
            return baseTurnRadius / tuckTurnPenalty; // Wider radius when tucking
        }
        return baseTurnRadius;
    }
}
