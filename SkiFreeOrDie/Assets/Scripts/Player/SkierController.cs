// Assets/Scripts/Player/SkierController.cs
using UnityEngine;

[RequireComponent(typeof(Rigidbody2D))]
public class SkierController : MonoBehaviour
{
    [Header("Speed Settings")]
    [SerializeField] private float baseSpeed = 25f;
    [SerializeField] private float tuckBonus = 0.2f;
    [SerializeField] private float maxSpeed = 40f;

    [Header("Current State")]
    [SerializeField] private SkiDirection currentDirection = SkiDirection.Down;
    [SerializeField] private bool isTucking;
    [SerializeField] private float currentSpeed;
    [SerializeField] private float currentSlopeMultiplier = 1f;
    [SerializeField] private bool isCrashed;

    private Rigidbody2D rb;
    private SpriteRenderer spriteRenderer;
    private bool wasTucking;
    private bool leftWasPressed;
    private bool rightWasPressed;

    public SkiDirection CurrentDirection => currentDirection;
    public bool IsTucking => isTucking;
    public float CurrentSpeed => currentSpeed;
    public bool IsCrashed => isCrashed;

    private void Awake()
    {
        rb = GetComponent<Rigidbody2D>();
        spriteRenderer = GetComponentInChildren<SpriteRenderer>();
        rb.gravityScale = 0;
        currentDirection = SkiDirection.Down;
    }

    private void Start()
    {
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

        isTucking = Input.GetKey(KeyCode.DownArrow) || Input.GetKey(KeyCode.LeftShift);

        bool leftPressed = Input.GetKey(KeyCode.LeftArrow) || Input.GetKey(KeyCode.A);
        bool rightPressed = Input.GetKey(KeyCode.RightArrow) || Input.GetKey(KeyCode.D);

        int directionIndex = (int)currentDirection;

        if (leftPressed && !leftWasPressed)
        {
            currentDirection = SkiDirectionExtensions.FromIndex(directionIndex - 1);
        }
        if (rightPressed && !rightWasPressed)
        {
            currentDirection = SkiDirectionExtensions.FromIndex(directionIndex + 1);
        }

        leftWasPressed = leftPressed;
        rightWasPressed = rightPressed;
    }

    private void UpdateAudio()
    {
        if (isCrashed) return;
        if (AudioManager.Instance == null) return;

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

        float speedNormalized = Mathf.Clamp01(currentSpeed / maxSpeed);
        AudioManager.Instance.SetLoopVolume(0.3f + speedNormalized * 0.7f);
    }

    private void UpdateMovement()
    {
        if (isCrashed) return;

        // Calculate speed with tuck bonus and direction multiplier
        float effectiveSpeed = baseSpeed * currentSlopeMultiplier;
        if (isTucking) effectiveSpeed *= (1f + tuckBonus);

        currentSpeed = effectiveSpeed * currentDirection.GetSpeedMultiplier();
        currentSpeed = Mathf.Min(currentSpeed, maxSpeed);

        // Apply velocity using pre-computed direction vector
        rb.linearVelocity = currentDirection.GetDirection() * currentSpeed;

        // Flip sprite for left turns (direction index < 3 means turning left)
        int dirIndex = (int)currentDirection;
        bool turningLeft = dirIndex < 3;

        if (spriteRenderer != null)
        {
            spriteRenderer.flipX = turningLeft;
        }

        // Use absolute rotation for magnitude
        // Negate when flipping because flip reverses the visual rotation direction
        float rotation = Mathf.Abs(currentDirection.GetRotation());
        if (turningLeft)
        {
            rotation = -rotation;
        }
        transform.rotation = Quaternion.Euler(0, 0, rotation);
    }

    public void SetSlopeMultiplier(float multiplier)
    {
        currentSlopeMultiplier = multiplier;
    }

    public void SetCrashed(bool crashed)
    {
        isCrashed = crashed;
        if (crashed)
        {
            rb.linearVelocity = Vector2.zero;
            currentSpeed = 0f;
        }
    }

    public void ApplySpeedPenalty(float multiplier)
    {
        currentSpeed *= multiplier;
    }

    public void ApplyDeflection(int steps)
    {
        int newIndex = (int)currentDirection + steps;
        currentDirection = SkiDirectionExtensions.FromIndex(newIndex);
    }

    public void SetDirection(SkiDirection direction)
    {
        currentDirection = direction;
    }
}
