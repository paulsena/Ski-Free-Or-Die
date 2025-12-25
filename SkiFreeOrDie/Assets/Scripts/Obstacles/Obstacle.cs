// Assets/Scripts/Obstacles/Obstacle.cs
using UnityEngine;

public class Obstacle : MonoBehaviour
{
    [SerializeField] private ObstacleType obstacleType;

    public ObstacleType Type => obstacleType;

    /// <summary>
    /// Returns speed multiplier on collision (1.0 = no change, 0 = full stop)
    /// </summary>
    public float GetSpeedPenalty()
    {
        return obstacleType switch
        {
            ObstacleType.SmallTree => 0.8f,   // 20% speed loss
            ObstacleType.LargeTree => 0.4f,   // 60% speed loss
            ObstacleType.Rock => 0f,          // Full stop
            ObstacleType.Cabin => 0f,         // Full stop
            _ => 1f
        };
    }

    /// <summary>
    /// Returns true if this obstacle causes a full crash.
    /// </summary>
    public bool CausesCrash()
    {
        return obstacleType == ObstacleType.Rock || obstacleType == ObstacleType.Cabin;
    }

    /// <summary>
    /// Returns deflection angle for non-crash collisions.
    /// </summary>
    public float GetDeflectionAngle()
    {
        return obstacleType switch
        {
            ObstacleType.LargeTree => 30f,
            _ => 0f
        };
    }
}
