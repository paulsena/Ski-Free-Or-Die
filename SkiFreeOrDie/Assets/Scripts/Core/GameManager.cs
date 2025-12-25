// Assets/Scripts/Core/GameManager.cs
using UnityEngine;

public class GameManager : MonoBehaviour
{
    [Header("Mode")]
    [SerializeField] private GameMode currentMode = GameMode.TimeTrial;

    [Header("References")]
    [SerializeField] private WorldManager worldManager;
    [SerializeField] private SkierController player;
    [SerializeField] private FinishLine finishLine;
    [SerializeField] private GateManager gateManager;

    [Header("State")]
    [SerializeField] private float elapsedTime;
    [SerializeField] private float distanceTraveled;
    [SerializeField] private bool isRunning;
    [SerializeField] private bool isFinished;
    [SerializeField] private bool isGameOver;

    [Header("Penalties")]
    [SerializeField] private float timePenalty;
    [SerializeField] private int gatesMissed;

    public GameMode CurrentMode => currentMode;
    public float ElapsedTime => elapsedTime;
    public float DistanceTraveled => distanceTraveled;
    public float TotalTime => elapsedTime + timePenalty;
    public float TimePenalty => timePenalty;
    public int GatesMissed => gatesMissed;
    public bool IsRunning => isRunning;
    public bool IsFinished => isFinished;
    public bool IsGameOver => isGameOver;
    public SkierController Player => player;

    public event System.Action OnGameStart;
    public event System.Action<float> OnGameFinish; // Time Trial finish
    public event System.Action<float> OnGameOver;   // Endless game over (Yeti caught)
    public event System.Action<float> OnPenaltyAdded;

    private float playerStartY;

    private void Start()
    {
        SetupGateManager();

        if (currentMode == GameMode.TimeTrial)
        {
            SetupFinishLine();
        }

        StartGame();
    }

    private void SetupGateManager()
    {
        if (gateManager == null)
        {
            gateManager = gameObject.AddComponent<GateManager>();
        }

        gateManager.OnGateMissed += HandleGateMissed;

        // Set player reference for position tracking
        if (player != null)
        {
            gateManager.SetPlayer(player.transform);
        }
    }

    private void HandleGateMissed(GateData gate, float penalty)
    {
        AddTimePenalty(penalty);
    }

    public GateManager GetGateManager()
    {
        return gateManager;
    }

    private void Update()
    {
        if (isRunning && !isFinished && !isGameOver)
        {
            elapsedTime += Time.deltaTime;

            // Track distance for Endless mode (only increases, never decreases)
            if (player != null)
            {
                float newDistance = Mathf.Abs(player.transform.position.y - playerStartY);
                distanceTraveled = Mathf.Max(distanceTraveled, newDistance);
            }
        }
    }

    private void SetupFinishLine()
    {
        if (finishLine == null && worldManager != null)
        {
            // Create finish line at end of course
            float finishY = -(worldManager.TotalTiles - 1) * worldManager.TileHeight - 10f;
            var finishGO = new GameObject("FinishLine");
            finishGO.transform.position = new Vector3(0, finishY, 0);
            finishGO.layer = LayerMask.NameToLayer("Trigger");

            var collider = finishGO.AddComponent<BoxCollider2D>();
            collider.size = new Vector2(20f, 2f);
            collider.isTrigger = true;

            finishLine = finishGO.AddComponent<FinishLine>();
        }

        if (finishLine != null)
        {
            finishLine.OnPlayerFinished += HandleFinish;
        }
    }

    private void StartGame()
    {
        elapsedTime = 0f;
        distanceTraveled = 0f;
        timePenalty = 0f;
        gatesMissed = 0;
        isRunning = true;
        isFinished = false;
        isGameOver = false;

        if (player != null)
        {
            playerStartY = player.transform.position.y;
        }

        // Play game start sound
        if (AudioManager.Instance != null)
        {
            AudioManager.Instance.PlaySFX(GameAudioType.GameStart);
        }

        OnGameStart?.Invoke();
    }

    private void HandleFinish()
    {
        if (isFinished || isGameOver) return;

        isFinished = true;
        isRunning = false;

        // Play finish sound
        if (AudioManager.Instance != null)
        {
            AudioManager.Instance.StopLoop();
            AudioManager.Instance.PlaySFX(GameAudioType.GameFinish);
        }

        OnGameFinish?.Invoke(TotalTime);

        Debug.Log($"Finished! Time: {elapsedTime:F2}s + {timePenalty:F2}s penalty = {TotalTime:F2}s total");
    }

    /// <summary>
    /// Called by YetiController when player is caught.
    /// </summary>
    public void TriggerGameOver()
    {
        if (isFinished || isGameOver) return;

        isGameOver = true;
        isRunning = false;

        // Play game over sound (Yeti catch sound is played by YetiController)
        if (AudioManager.Instance != null)
        {
            AudioManager.Instance.PlaySFX(GameAudioType.GameOver, 0.8f);
        }

        OnGameOver?.Invoke(distanceTraveled);

        Debug.Log($"Game Over! Distance traveled: {distanceTraveled:F0}m");
    }

    public void AddTimePenalty(float penalty)
    {
        timePenalty += penalty;
        gatesMissed++;
        OnPenaltyAdded?.Invoke(penalty);
        Debug.Log($"Penalty added: +{penalty:F1}s (Total penalty: {timePenalty:F1}s)");
    }

    public void SetGameMode(GameMode mode)
    {
        currentMode = mode;
    }

    public void RestartGame()
    {
        // Reload scene for now
        UnityEngine.SceneManagement.SceneManager.LoadScene(
            UnityEngine.SceneManagement.SceneManager.GetActiveScene().name
        );
    }

    private void OnDestroy()
    {
        // Unsubscribe from events to prevent memory leaks
        if (gateManager != null)
        {
            gateManager.OnGateMissed -= HandleGateMissed;
        }
        if (finishLine != null)
        {
            finishLine.OnPlayerFinished -= HandleFinish;
        }
    }
}
