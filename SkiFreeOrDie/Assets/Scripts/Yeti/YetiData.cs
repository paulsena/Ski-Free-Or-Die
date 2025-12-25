// Assets/Scripts/Yeti/YetiData.cs
using UnityEngine;

[System.Serializable]
public class YetiData
{
    [Header("Speed Scaling")]
    [SerializeField] private float baseSpeed = 80f;
    [SerializeField] private float maxSpeed = 150f;
    [SerializeField] private float speedRampTime = 120f; // Seconds to reach max speed

    [Header("Zone Thresholds")]
    [SerializeField] private float safeDistance = 50f;
    [SerializeField] private float warningDistance = 30f;
    [SerializeField] private float dangerDistance = 10f;
    [SerializeField] private float catchDistance = 2f;

    public float BaseSpeed => baseSpeed;
    public float MaxSpeed => maxSpeed;
    public float SpeedRampTime => speedRampTime;
    public float CatchDistance => catchDistance;

    public YetiData()
    {
        baseSpeed = 80f;
        maxSpeed = 150f;
        speedRampTime = 120f;
        safeDistance = 50f;
        warningDistance = 30f;
        dangerDistance = 10f;
        catchDistance = 2f;
    }

    /// <summary>
    /// Calculate Yeti speed based on elapsed time.
    /// Speed increases linearly from base to max over speedRampTime.
    /// </summary>
    public float GetCurrentSpeed(float elapsedTime)
    {
        float t = Mathf.Clamp01(elapsedTime / speedRampTime);
        return Mathf.Lerp(baseSpeed, maxSpeed, t);
    }

    /// <summary>
    /// Determine the current danger zone based on distance to player.
    /// </summary>
    public YetiZone GetZone(float distanceToPlayer)
    {
        if (distanceToPlayer > safeDistance)
            return YetiZone.Safe;
        if (distanceToPlayer > warningDistance)
            return YetiZone.Warning;
        if (distanceToPlayer > dangerDistance)
            return YetiZone.Danger;
        return YetiZone.Critical;
    }

    /// <summary>
    /// Get intensity value (0-1) for visual effects based on distance.
    /// </summary>
    public float GetTensionIntensity(float distanceToPlayer)
    {
        if (distanceToPlayer >= safeDistance)
            return 0f;

        // Linear interpolation from safe to catch distance
        float t = Mathf.InverseLerp(safeDistance, catchDistance, distanceToPlayer);
        return t;
    }

    /// <summary>
    /// Check if Yeti has caught the player.
    /// </summary>
    public bool HasCaughtPlayer(float distanceToPlayer)
    {
        return distanceToPlayer <= catchDistance;
    }
}
