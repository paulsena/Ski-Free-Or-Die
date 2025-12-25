// Assets/Scripts/Yeti/YetiAnimator.cs
using UnityEngine;

public enum YetiAnimState
{
    Idle,
    Chasing,
    Reaching,
    Catching
}

[RequireComponent(typeof(YetiController))]
public class YetiAnimator : MonoBehaviour
{
    [Header("References")]
    [SerializeField] private SpriteRenderer spriteRenderer;
    [SerializeField] private Animator animator;

    [Header("Sprites (Placeholder System)")]
    [SerializeField] private Sprite idleSprite;
    [SerializeField] private Sprite chasingSprite;
    [SerializeField] private Sprite reachingSprite;
    [SerializeField] private Sprite catchingSprite;

    [Header("State")]
    [SerializeField] private YetiAnimState currentState;

    private YetiController yetiController;

    public YetiAnimState CurrentState => currentState;

    private void Awake()
    {
        yetiController = GetComponent<YetiController>();

        if (spriteRenderer == null)
        {
            spriteRenderer = GetComponent<SpriteRenderer>();
        }
    }

    private void Start()
    {
        if (yetiController != null)
        {
            yetiController.OnZoneChanged += HandleZoneChanged;
            yetiController.OnPlayerCaught += HandlePlayerCaught;
        }
    }

    private void Update()
    {
        if (yetiController == null || !yetiController.IsActive) return;

        UpdateAnimationState();
        ApplyAnimation();
    }

    private void UpdateAnimationState()
    {
        // Determine animation based on zone
        YetiZone zone = yetiController.CurrentZone;

        if (currentState == YetiAnimState.Catching)
        {
            return; // Stay in catching state
        }

        currentState = zone switch
        {
            YetiZone.Safe => YetiAnimState.Chasing,
            YetiZone.Warning => YetiAnimState.Chasing,
            YetiZone.Danger => YetiAnimState.Reaching,
            YetiZone.Critical => YetiAnimState.Reaching,
            _ => YetiAnimState.Chasing
        };
    }

    private void ApplyAnimation()
    {
        // If using Animator component
        if (animator != null)
        {
            animator.SetInteger("State", (int)currentState);
            animator.SetFloat("Distance", yetiController.DistanceToPlayer);
            animator.SetFloat("Tension", yetiController.TensionIntensity);
            return;
        }

        // Fallback to sprite swapping
        if (spriteRenderer == null) return;

        Sprite targetSprite = currentState switch
        {
            YetiAnimState.Idle => idleSprite,
            YetiAnimState.Chasing => chasingSprite,
            YetiAnimState.Reaching => reachingSprite,
            YetiAnimState.Catching => catchingSprite,
            _ => chasingSprite
        };

        if (targetSprite != null)
        {
            spriteRenderer.sprite = targetSprite;
        }
    }

    private void HandleZoneChanged(YetiZone newZone)
    {
        // Could add special animation triggers on zone changes
        if (animator != null && newZone == YetiZone.Critical)
        {
            animator.SetTrigger("AlertReach");
        }
    }

    private void HandlePlayerCaught()
    {
        currentState = YetiAnimState.Catching;
        ApplyAnimation();

        if (animator != null)
        {
            animator.SetTrigger("Catch");
        }
    }

    private void OnDestroy()
    {
        if (yetiController != null)
        {
            yetiController.OnZoneChanged -= HandleZoneChanged;
            yetiController.OnPlayerCaught -= HandlePlayerCaught;
        }
    }
}
