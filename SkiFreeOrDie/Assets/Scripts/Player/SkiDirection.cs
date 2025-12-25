// Assets/Scripts/Player/SkiDirection.cs
using UnityEngine;

/// <summary>
/// Discrete ski positions matching original SkiFree style.
/// Ordered from screen-left to screen-right.
/// </summary>
public enum SkiDirection
{
    Left,             // Facing sideways left (stopped)
    DownLeftSharp,    // Sharp carve left (slow)
    DownLeftSlight,   // Slight turn left (fast)
    Down,             // Straight down (fastest)
    DownRightSlight,  // Slight turn right (fast)
    DownRightSharp,   // Sharp carve right (slow)
    Right             // Facing sideways right (stopped)
}

/// <summary>
/// Extension methods for SkiDirection - all data derived from enum index.
/// </summary>
public static class SkiDirectionExtensions
{
    public const int DirectionCount = 7;
    public const int DownIndex = 3;

    // Pre-computed normalized direction vectors (no trig at runtime)
    // Left = (-1, 0), Down = (0, -1), Right = (1, 0)
    // Sharp = 60° from down, Slight = 30° from down
    private static readonly Vector2[] Directions =
    {
        new Vector2(-1f, 0f),              // Left (90°)
        new Vector2(-0.866f, -0.5f),       // DownLeftSharp (60°)
        new Vector2(-0.5f, -0.866f),       // DownLeftSlight (30°)
        new Vector2(0f, -1f),              // Down (0°)
        new Vector2(0.5f, -0.866f),        // DownRightSlight (-30°)
        new Vector2(0.866f, -0.5f),        // DownRightSharp (-60°)
        new Vector2(1f, 0f)                // Right (-90°)
    };

    // Speed multipliers: stopped at edges, fastest in center
    private static readonly float[] SpeedMultipliers =
    {
        0f,     // Left - stopped
        0.35f,  // DownLeftSharp - slow
        0.8f,   // DownLeftSlight - fast
        1f,     // Down - maximum
        0.8f,   // DownRightSlight - fast
        0.35f,  // DownRightSharp - slow
        0f      // Right - stopped
    };

    /// <summary>
    /// Get the normalized movement direction vector.
    /// </summary>
    public static Vector2 GetDirection(this SkiDirection dir)
    {
        return Directions[(int)dir];
    }

    /// <summary>
    /// Get the speed multiplier (0.0 = stopped, 1.0 = full speed).
    /// </summary>
    public static float GetSpeedMultiplier(this SkiDirection dir)
    {
        return SpeedMultipliers[(int)dir];
    }

    /// <summary>
    /// Get the sprite rotation in degrees.
    /// Down = 0°, Left = 90°, Right = -90°
    /// </summary>
    public static float GetRotation(this SkiDirection dir)
    {
        // Down (index 3) = 0°, each step is 30°
        return (DownIndex - (int)dir) * 30f;
    }

    /// <summary>
    /// Clamp an index to valid direction range.
    /// </summary>
    public static SkiDirection FromIndex(int index)
    {
        return (SkiDirection)Mathf.Clamp(index, 0, DirectionCount - 1);
    }
}
