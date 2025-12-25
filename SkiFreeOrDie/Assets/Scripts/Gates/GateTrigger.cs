// Assets/Scripts/Gates/GateTrigger.cs
using UnityEngine;

[RequireComponent(typeof(BoxCollider2D))]
public class GateTrigger : MonoBehaviour
{
    [Header("Visual References")]
    [SerializeField] private SpriteRenderer leftPole;
    [SerializeField] private SpriteRenderer rightPole;
    [SerializeField] private SpriteRenderer flag;

    [Header("State")]
    [SerializeField] private GateData gateData;
    [SerializeField] private bool hasTriggered;

    private GateManager gateManager;
    private BoxCollider2D triggerCollider;

    public GateData Data => gateData;

    public event System.Action OnGatePassed;
    public event System.Action OnGateMissed;

    private void Awake()
    {
        triggerCollider = GetComponent<BoxCollider2D>();
        triggerCollider.isTrigger = true;
    }

    public void Initialize(GateManager manager, int gateIndex)
    {
        gateManager = manager;
        gateData = new GateData(gateIndex, transform.position.x, transform.position.y);

        if (gateManager != null)
        {
            gateManager.RegisterGate(gateData);
            // Subscribe to missed gate events for visual updates
            gateManager.OnGateMissed += HandleGateMissedEvent;
        }

        UpdateVisuals();
    }

    private void OnDestroy()
    {
        // Unsubscribe to prevent memory leaks
        if (gateManager != null)
        {
            gateManager.OnGateMissed -= HandleGateMissedEvent;
        }
    }

    private void HandleGateMissedEvent(GateData missedGate, float penalty)
    {
        // Check if this event is about our gate
        if (missedGate == gateData)
        {
            hasTriggered = true;
            UpdateVisuals();
            OnGateMissed?.Invoke();
        }
    }

    private void OnTriggerEnter2D(Collider2D other)
    {
        if (hasTriggered) return;
        if (other.GetComponent<SkierController>() == null) return;

        hasTriggered = true;

        if (gateManager != null)
        {
            gateManager.NotifyGatePassed(gateData);
        }
        else
        {
            gateData.MarkPassed();
        }

        UpdateVisuals();
        OnGatePassed?.Invoke();
    }

    public void MarkAsMissed()
    {
        if (hasTriggered) return;
        hasTriggered = true;
        gateData.MarkMissed();
        UpdateVisuals();
    }

    private void UpdateVisuals()
    {
        Color targetColor = gateData.State switch
        {
            GateState.Pending => GameColors.GatePending,
            GateState.Passed => GameColors.GatePassed,
            GateState.Missed => GameColors.GateMissed,
            _ => GameColors.GatePending
        };

        if (leftPole != null) leftPole.color = targetColor;
        if (rightPole != null) rightPole.color = targetColor;
        if (flag != null) flag.color = targetColor;
    }

    public void SetVisualReferences(SpriteRenderer left, SpriteRenderer right, SpriteRenderer flagRenderer)
    {
        leftPole = left;
        rightPole = right;
        flag = flagRenderer;
    }
}
