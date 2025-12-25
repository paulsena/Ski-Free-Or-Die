// Assets/Scripts/Player/SkierController.cs
using UnityEngine;

[RequireComponent(typeof(Rigidbody2D))]
public class SkierController : MonoBehaviour
{
    [Header("Stats")]
    [SerializeField] private float baseSpeed = 100f;
    [SerializeField] private float tuckBonus = 0.12f;
    [SerializeField] private float maxSpeed = 200f;

    [Header("Turning")]
    [SerializeField] private float lowSpeedThreshold = 40f;
    [SerializeField] private float highSpeedThreshold = 60f;
    [SerializeField] private float tuckTurnPenalty = 0.6f;
    [SerializeField] private float turnSpeed = 180f; // Degrees per second

    [Header("Current State")]
    [SerializeField] private bool isTucking;
    [SerializeField] private float currentSpeed;
    [SerializeField] private float currentSlopeMultiplier = 1f;
    [SerializeField] private bool isCrashed;

    private Rigidbody2D rb;
    private SkierStats stats;
    private TurnCalculator turnCalculator;
    private float targetAngle;
    private bool wasTucking;

    public bool IsTucking => isTucking;
    public float CurrentSpeed => currentSpeed;
    public bool IsCrashed => isCrashed;

    private void Awake()
    {
        rb = GetComponent<Rigidbody2D>();
        rb.gravityScale = 0; // We handle movement manually

        stats = new SkierStats(baseSpeed, tuckBonus);
        turnCalculator = new TurnCalculator(
            lowSpeedThreshold,
            highSpeedThreshold,
            maxSpeed,
            tuckTurnPenalty
        );

        targetAngle = 0f; // Facing down
    }

    private void Start()
    {
        // Start ski loop sound
        if (AudioManager.Instance != null)
        {
            AudioManager.Instance.StartLoop(GameAudioType.SkiLoop);
        }
    }

    private void Update()
    {
        HandleInput();
        UpdateAudio();
    }

    private void FixedUpdate()
    {
        UpdateMovement();
    }

    private void HandleInput()
    {
        if (isCrashed) return;

        // Tuck: Hold down arrow or left shift
        isTucking = Input.GetKey(KeyCode.DownArrow) || Input.GetKey(KeyCode.LeftShift);

        // Turn: Left/Right arrows or A/D
        float turnInput = 0f;
        if (Input.GetKey(KeyCode.LeftArrow) || Input.GetKey(KeyCode.A))
        {
            turnInput = 1f; // Turn left (positive rotation in Unity 2D)
        }
        else if (Input.GetKey(KeyCode.RightArrow) || Input.GetKey(KeyCode.D))
        {
            turnInput = -1f; // Turn right (negative rotation)
        }

        // Apply turn with response factor
        float turnResponse = turnCalculator.GetTurnResponse(currentSpeed);
        float radiusMultiplier = turnCalculator.GetTurnRadius(isTucking);
        float effectiveTurnSpeed = turnSpeed * turnResponse / radiusMultiplier;

        targetAngle += turnInput * effectiveTurnSpeed * Time.deltaTime;
        targetAngle = Mathf.Clamp(targetAngle, -80f, 80f); // Limit turning angle
    }

    private void UpdateAudio()
    {
        if (isCrashed) return;
        if (AudioManager.Instance == null) return;

        // Crossfade between ski and tuck wind loop
        if (isTucking != wasTucking)
        {
            wasTucking = isTucking;
            if (isTucking)
            {
                AudioManager.Instance.CrossfadeToLoop(GameAudioType.TuckWindLoop, 0.3f);
            }
            else
            {
                AudioManager.Instance.CrossfadeToLoop(GameAudioType.SkiLoop, 0.3f);
            }
        }

        // Adjust loop volume based on speed
        float speedNormalized = Mathf.Clamp01(currentSpeed / maxSpeed);
        AudioManager.Instance.SetLoopVolume(0.3f + speedNormalized * 0.7f);
    }

    private void UpdateMovement()
    {
        if (isCrashed) return;

        // Calculate effective speed
        currentSpeed = stats.GetEffectiveSpeed(isTucking, currentSlopeMultiplier);
        currentSpeed = Mathf.Min(currentSpeed, maxSpeed);

        // Convert angle to direction (0 = down, positive = left, negative = right)
        float radians = (targetAngle - 90f) * Mathf.Deg2Rad;
        Vector2 direction = new Vector2(Mathf.Cos(radians), Mathf.Sin(radians));

        // Apply velocity (using velocity for Unity 2022 LTS compatibility)
        rb.linearVelocity = direction * currentSpeed;

        // Rotate sprite to match direction
        transform.rotation = Quaternion.Euler(0, 0, targetAngle);
    }

    /// <summary>
    /// Called by tile system to update slope intensity.
    /// </summary>
    public void SetSlopeMultiplier(float multiplier)
    {
        currentSlopeMultiplier = multiplier;
    }

    /// <summary>
    /// Called by collision handler to set crash state.
    /// </summary>
    public void SetCrashed(bool crashed)
    {
        isCrashed = crashed;
        if (crashed)
        {
            rb.linearVelocity = Vector2.zero;
            currentSpeed = 0f;
        }
    }

    /// <summary>
    /// Called by collision handler for non-crash collisions.
    /// </summary>
    public void ApplySpeedPenalty(float multiplier)
    {
        currentSpeed *= multiplier;
    }

    /// <summary>
    /// Called by collision handler for deflection on tree hits.
    /// </summary>
    public void ApplyDeflection(float angle)
    {
        targetAngle += angle;
        targetAngle = Mathf.Clamp(targetAngle, -80f, 80f);
    }
}
