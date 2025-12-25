// Assets/Scripts/Player/SkierStats.cs
using UnityEngine;

[System.Serializable]
public class SkierStats
{
    [SerializeField] private float baseSpeed;
    [SerializeField] private float tuckBonus;

    public float BaseSpeed => baseSpeed;
    public float TuckBonus => tuckBonus;

    public SkierStats(float baseSpeed, float tuckBonus = 0.12f)
    {
        this.baseSpeed = baseSpeed;
        this.tuckBonus = tuckBonus;
    }

    public float GetEffectiveSpeed(bool isTucking, float slopeMultiplier)
    {
        float speed = baseSpeed * slopeMultiplier;
        if (isTucking)
        {
            speed *= (1f + tuckBonus);
        }
        return speed;
    }
}
