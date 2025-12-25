// Assets/Scripts/Player/SkierAnimator.cs
using UnityEngine;

public enum SkierAnimState
{
    Skiing,
    Tucking,
    TurningLeft,
    TurningRight,
    Crashed,
    Recovering
}

[RequireComponent(typeof(SkierController))]
[RequireComponent(typeof(SkierCollisionHandler))]
public class SkierAnimator : MonoBehaviour
{
    [Header("References")]
    [SerializeField] private SpriteRenderer spriteRenderer;
    [SerializeField] private Animator animator;

    [Header("Sprites (Placeholder System)")]
    [SerializeField] private Sprite skiingSprite;
    [SerializeField] private Sprite tuckingSprite;
    [SerializeField] private Sprite turningLeftSprite;
    [SerializeField] private Sprite turningRightSprite;
    [SerializeField] private Sprite crashedSprite;

    [Header("Animation Parameters")]
    [SerializeField] private float turnThreshold = 15f;

    [Header("State")]
    [SerializeField] private SkierAnimState currentState;

    private SkierController skierController;
    private SkierCollisionHandler collisionHandler;

    public SkierAnimState CurrentState => currentState;

    private void Awake()
    {
        skierController = GetComponent<SkierController>();
        collisionHandler = GetComponent<SkierCollisionHandler>();

        if (spriteRenderer == null)
        {
            spriteRenderer = GetComponent<SpriteRenderer>();
        }
    }

    private void Start()
    {
        if (collisionHandler != null)
        {
            collisionHandler.OnCrash += HandleCrash;
            collisionHandler.OnRecover += HandleRecover;
        }
    }

    private void Update()
    {
        if (collisionHandler != null && collisionHandler.IsCrashed)
        {
            return; // Don't update during crash
        }

        UpdateAnimationState();
        ApplyAnimation();
    }

    private void UpdateAnimationState()
    {
        if (skierController == null) return;

        // Get turn direction from rotation
        float rotation = transform.eulerAngles.z;
        if (rotation > 180) rotation -= 360;

        if (skierController.IsTucking)
        {
            currentState = SkierAnimState.Tucking;
        }
        else if (rotation > turnThreshold)
        {
            currentState = SkierAnimState.TurningLeft;
        }
        else if (rotation < -turnThreshold)
        {
            currentState = SkierAnimState.TurningRight;
        }
        else
        {
            currentState = SkierAnimState.Skiing;
        }
    }

    private void ApplyAnimation()
    {
        // If using Animator component
        if (animator != null)
        {
            animator.SetInteger("State", (int)currentState);
            animator.SetFloat("Speed", skierController.CurrentSpeed);
            animator.SetBool("IsTucking", skierController.IsTucking);
            return;
        }

        // Fallback to sprite swapping
        if (spriteRenderer == null) return;

        Sprite targetSprite = currentState switch
        {
            SkierAnimState.Skiing => skiingSprite,
            SkierAnimState.Tucking => tuckingSprite,
            SkierAnimState.TurningLeft => turningLeftSprite,
            SkierAnimState.TurningRight => turningRightSprite,
            SkierAnimState.Crashed => crashedSprite,
            SkierAnimState.Recovering => skiingSprite,
            _ => skiingSprite
        };

        if (targetSprite != null)
        {
            spriteRenderer.sprite = targetSprite;
        }
    }

    private void HandleCrash()
    {
        currentState = SkierAnimState.Crashed;
        ApplyAnimation();

        if (animator != null)
        {
            animator.SetTrigger("Crash");
        }
    }

    private void HandleRecover()
    {
        currentState = SkierAnimState.Recovering;

        if (animator != null)
        {
            animator.SetTrigger("Recover");
        }
    }

    private void OnDestroy()
    {
        if (collisionHandler != null)
        {
            collisionHandler.OnCrash -= HandleCrash;
            collisionHandler.OnRecover -= HandleRecover;
        }
    }
}
