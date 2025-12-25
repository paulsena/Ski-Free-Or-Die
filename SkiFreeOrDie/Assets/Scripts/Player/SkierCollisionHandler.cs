// Assets/Scripts/Player/SkierCollisionHandler.cs
using UnityEngine;
using System.Collections;

[RequireComponent(typeof(SkierController))]
public class SkierCollisionHandler : MonoBehaviour
{
    [Header("Crash Settings")]
    [SerializeField] private float crashRecoveryTime = 1.75f;

    [Header("State")]
    [SerializeField] private bool isCrashed;
    [SerializeField] private bool isRecovering;

    private SkierController skierController;

    public bool IsCrashed => isCrashed;
    public bool IsRecovering => isRecovering;

    public event System.Action OnCrash;
    public event System.Action OnRecover;

    private void Awake()
    {
        skierController = GetComponent<SkierController>();
    }

    private void OnCollisionEnter2D(Collision2D collision)
    {
        if (isRecovering) return;

        var obstacle = collision.gameObject.GetComponent<Obstacle>();
        if (obstacle == null) return;

        HandleObstacleCollision(obstacle, collision);
    }

    private void HandleObstacleCollision(Obstacle obstacle, Collision2D collision)
    {
        if (obstacle.CausesCrash())
        {
            StartCoroutine(CrashSequence());
        }
        else
        {
            // Apply speed penalty and deflection
            float penalty = obstacle.GetSpeedPenalty();
            float deflectionAngle = obstacle.GetDeflectionAngle();

            // Determine deflection direction based on collision normal
            Vector2 normal = collision.contacts[0].normal;
            int deflectionDir = normal.x > 0 ? 1 : -1;

            // Convert angle to discrete steps (each step is 30°)
            int steps = Mathf.RoundToInt(deflectionAngle / 30f) * deflectionDir;

            skierController.ApplySpeedPenalty(penalty);
            skierController.ApplyDeflection(steps);

            // Play obstacle hit sound
            PlayObstacleHitSound(obstacle.Type);
        }
    }

    private void PlayObstacleHitSound(ObstacleType obstacleType)
    {
        if (AudioManager.Instance == null) return;

        GameAudioType audioType = obstacleType switch
        {
            ObstacleType.SmallTree => GameAudioType.TreeHit,
            ObstacleType.LargeTree => GameAudioType.TreeHit,
            ObstacleType.Rock => GameAudioType.RockHit,
            ObstacleType.Cabin => GameAudioType.CabinHit,
            _ => GameAudioType.TreeHit
        };

        AudioManager.Instance.PlaySFX(audioType);
    }

    private IEnumerator CrashSequence()
    {
        isCrashed = true;
        isRecovering = true;
        OnCrash?.Invoke();

        // Play crash sound
        if (AudioManager.Instance != null)
        {
            AudioManager.Instance.PlaySFX(GameAudioType.Crash);
            AudioManager.Instance.StopLoop(); // Stop skiing loop
        }

        // Stop the skier
        skierController.SetCrashed(true);

        yield return new WaitForSeconds(crashRecoveryTime);

        // Recover
        skierController.SetCrashed(false);
        isCrashed = false;
        isRecovering = false;
        OnRecover?.Invoke();

        // Resume skiing loop
        if (AudioManager.Instance != null)
        {
            AudioManager.Instance.StartLoop(GameAudioType.SkiLoop);
        }
    }
}
