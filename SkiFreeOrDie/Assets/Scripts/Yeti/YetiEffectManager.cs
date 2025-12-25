// Assets/Scripts/Yeti/YetiEffectManager.cs
using UnityEngine;
using UnityEngine.UI;

public class YetiEffectManager : MonoBehaviour
{
    [Header("References")]
    [SerializeField] private YetiController yetiController;
    [SerializeField] private Image vignetteOverlay;

    [Header("Effect Settings")]
    [SerializeField] private Color safeColor = new Color(0, 0, 0, 0);
    [SerializeField] private Color warningColor = new Color(0.2f, 0, 0.1f, 0.2f);
    [SerializeField] private Color dangerColor = new Color(0.5f, 0, 0.1f, 0.4f);
    [SerializeField] private Color criticalColor = new Color(0.8f, 0, 0, 0.6f);

    [Header("Pulse Settings")]
    [SerializeField] private float pulseSpeed = 2f;
    [SerializeField] private float pulseAmount = 0.2f;

    [Header("Audio Settings")]
    [SerializeField] private float growlIntervalBase = 8f;
    [SerializeField] private float growlIntervalMin = 2f;
    [SerializeField] private float footstepInterval = 0.5f;

    private float pulsePhase;
    private float nextGrowlTime;
    private float nextFootstepTime;

    private void Start()
    {
        if (yetiController != null)
        {
            yetiController.OnZoneChanged += HandleZoneChanged;
        }

        // Ensure overlay starts invisible
        if (vignetteOverlay != null)
        {
            vignetteOverlay.color = safeColor;
        }
    }

    private void Update()
    {
        if (yetiController == null || !yetiController.IsActive) return;

        UpdateVignetteEffect();
        UpdateAudio();
    }

    private void UpdateAudio()
    {
        if (AudioManager.Instance == null) return;

        YetiZone zone = yetiController.CurrentZone;

        // Growl sounds - more frequent when closer
        if (zone >= YetiZone.Warning && Time.time >= nextGrowlTime)
        {
            float tensionFactor = yetiController.TensionIntensity;
            float growlInterval = Mathf.Lerp(growlIntervalBase, growlIntervalMin, tensionFactor);
            nextGrowlTime = Time.time + growlInterval;

            // Volume increases with tension
            float volume = 0.3f + tensionFactor * 0.7f;
            AudioManager.Instance.PlaySFX(GameAudioType.YetiGrowl, volume);
        }

        // Footstep sounds when in danger zone
        if (zone >= YetiZone.Danger && Time.time >= nextFootstepTime)
        {
            nextFootstepTime = Time.time + footstepInterval;
            float volume = zone == YetiZone.Critical ? 0.8f : 0.5f;
            AudioManager.Instance.PlaySFX(GameAudioType.YetiFootstep, volume);
        }
    }

    private void HandleZoneChanged(YetiZone newZone)
    {
        // Could trigger audio/screen shake here
        if (newZone == YetiZone.Critical)
        {
            // Intense warning
            Debug.Log("YETI IS VERY CLOSE!");
        }
    }

    private void UpdateVignetteEffect()
    {
        if (vignetteOverlay == null) return;

        Color targetColor = yetiController.CurrentZone switch
        {
            YetiZone.Safe => safeColor,
            YetiZone.Warning => warningColor,
            YetiZone.Danger => dangerColor,
            YetiZone.Critical => criticalColor,
            _ => safeColor
        };

        // Add pulsing effect for danger zones
        if (yetiController.CurrentZone >= YetiZone.Danger)
        {
            pulsePhase += Time.deltaTime * pulseSpeed;
            float pulse = (Mathf.Sin(pulsePhase) + 1f) * 0.5f * pulseAmount;
            targetColor.a += pulse;
        }

        vignetteOverlay.color = Color.Lerp(vignetteOverlay.color, targetColor, Time.deltaTime * 5f);
    }

    public void SetYetiController(YetiController controller)
    {
        // Unsubscribe from old controller to prevent memory leaks
        if (yetiController != null)
        {
            yetiController.OnZoneChanged -= HandleZoneChanged;
        }

        yetiController = controller;

        if (yetiController != null)
        {
            yetiController.OnZoneChanged += HandleZoneChanged;
        }
    }

    private void OnDestroy()
    {
        if (yetiController != null)
        {
            yetiController.OnZoneChanged -= HandleZoneChanged;
        }
    }
}
