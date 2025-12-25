// Assets/Scripts/Yeti/YetiController.cs
using UnityEngine;

public class YetiController : MonoBehaviour
{
    [Header("Data")]
    [SerializeField] private YetiData yetiData;

    [Header("References")]
    [SerializeField] private Transform player;
    [SerializeField] private GameManager gameManager;

    [Header("State")]
    [SerializeField] private float currentSpeed;
    [SerializeField] private float distanceToPlayer;
    [SerializeField] private YetiZone currentZone;
    [SerializeField] private bool isActive = false;

    [Header("Settings")]
    [SerializeField] private float startBehindPlayer = 60f;

    public float DistanceToPlayer => distanceToPlayer;
    public YetiZone CurrentZone => currentZone;
    public float TensionIntensity => yetiData.GetTensionIntensity(distanceToPlayer);
    public bool IsActive => isActive;

    public event System.Action<YetiZone> OnZoneChanged;
    public event System.Action OnPlayerCaught;

    private YetiZone lastZone = YetiZone.Safe;

    private void Awake()
    {
        if (yetiData == null)
        {
            yetiData = new YetiData();
        }
    }

    private void Start()
    {
        // Only activate in Endless mode
        if (gameManager != null && gameManager.CurrentMode == GameMode.Endless)
        {
            Activate();
        }
        else
        {
            gameObject.SetActive(false);
        }
    }

    public void Activate()
    {
        isActive = true;

        if (player != null)
        {
            // Start behind the player
            transform.position = new Vector3(0, player.position.y + startBehindPlayer, 0);
        }
    }

    private void Update()
    {
        if (!isActive || gameManager == null || !gameManager.IsRunning) return;
        if (player == null) return;

        UpdateSpeed();
        MoveTowardsPlayer();
        UpdateZone();
        CheckCatch();
    }

    private void UpdateSpeed()
    {
        float elapsedTime = gameManager.ElapsedTime;
        currentSpeed = yetiData.GetCurrentSpeed(elapsedTime);
    }

    private void MoveTowardsPlayer()
    {
        // Yeti moves downward (negative Y) towards player
        float targetY = player.position.y;
        float currentY = transform.position.y;
        float playerX = player.position.x;

        // Only move if behind player
        if (currentY > targetY)
        {
            float newY = currentY - currentSpeed * Time.deltaTime;
            transform.position = new Vector3(playerX, newY, 0);
        }
        else
        {
            // Yeti caught up, stay with player (use CatchDistance for consistent offset)
            transform.position = new Vector3(playerX, targetY + yetiData.CatchDistance, 0);
        }

        // Calculate distance (Yeti Y is above player Y, so positive difference means behind)
        distanceToPlayer = transform.position.y - player.position.y;
    }

    private void UpdateZone()
    {
        currentZone = yetiData.GetZone(distanceToPlayer);

        if (currentZone != lastZone)
        {
            OnZoneChanged?.Invoke(currentZone);
            lastZone = currentZone;

            Debug.Log($"Yeti zone changed to: {currentZone} (Distance: {distanceToPlayer:F1}m)");
        }
    }

    private void CheckCatch()
    {
        if (yetiData.HasCaughtPlayer(distanceToPlayer))
        {
            OnPlayerCaught?.Invoke();

            // Play catch sound
            if (AudioManager.Instance != null)
            {
                AudioManager.Instance.StopLoop();
                AudioManager.Instance.PlaySFX(GameAudioType.YetiCatch);
            }

            gameManager.TriggerGameOver();
            isActive = false;

            Debug.Log("Yeti caught the player!");
        }
    }

    public void SetReferences(Transform playerTransform, GameManager manager)
    {
        player = playerTransform;
        gameManager = manager;
    }
}
