// Assets/Scripts/UI/GameHUD.cs
using UnityEngine;
using UnityEngine.UI;
using System.Text;

public class GameHUD : MonoBehaviour
{
    [Header("References")]
    [SerializeField] private GameManager gameManager;
    [SerializeField] private SkierController skier;
    [SerializeField] private YetiController yetiController;

    [Header("UI Elements - Common")]
    [SerializeField] private Text timerText;
    [SerializeField] private Text speedText;
    [SerializeField] private Text penaltyText;
    [SerializeField] private Text finishText;
    [SerializeField] private GameObject finishPanel;

    [Header("UI Elements - Endless Mode")]
    [SerializeField] private Text distanceText;
    [SerializeField] private Text yetiDistanceText;
    [SerializeField] private GameObject gameOverPanel;
    [SerializeField] private Text gameOverText;

    // Cached values to avoid string allocations every frame
    private int lastMinutes = -1;
    private int lastSeconds = -1;
    private int lastMilliseconds = -1;
    private int lastSpeed = -1;
    private int lastDistance = -1;
    private int lastYetiDistance = -1;
    private StringBuilder timerBuilder = new StringBuilder(12);
    private StringBuilder speedBuilder = new StringBuilder(12);
    private StringBuilder distanceBuilder = new StringBuilder(16);

    private void Start()
    {
        if (finishPanel != null)
        {
            finishPanel.SetActive(false);
        }
        if (gameOverPanel != null)
        {
            gameOverPanel.SetActive(false);
        }

        if (gameManager != null)
        {
            gameManager.OnGameFinish += ShowFinishScreen;
            gameManager.OnGameOver += ShowGameOverScreen;
            gameManager.OnPenaltyAdded += ShowPenalty;
        }

        // Auto-find YetiController if not assigned (for Endless mode)
        if (yetiController == null)
        {
            yetiController = FindObjectOfType<YetiController>();
        }

        // Adjust UI based on game mode
        UpdateModeVisibility();
    }

    private void UpdateModeVisibility()
    {
        if (gameManager == null) return;

        bool isEndless = gameManager.CurrentMode == GameMode.Endless;

        // Distance is only shown in Endless mode
        if (distanceText != null)
        {
            distanceText.gameObject.SetActive(isEndless);
        }
        if (yetiDistanceText != null)
        {
            yetiDistanceText.gameObject.SetActive(isEndless);
        }

        // Penalty is only shown in Time Trial mode (for gates)
        if (penaltyText != null)
        {
            penaltyText.gameObject.SetActive(!isEndless);
        }
    }

    private void Update()
    {
        UpdateTimer();
        UpdateSpeed();

        if (gameManager != null && gameManager.CurrentMode == GameMode.Endless)
        {
            UpdateDistance();
            UpdateYetiDistance();
        }
    }

    private void UpdateTimer()
    {
        if (timerText == null || gameManager == null) return;

        float time = gameManager.ElapsedTime;
        int minutes = Mathf.FloorToInt(time / 60f);
        int seconds = Mathf.FloorToInt(time % 60f);
        int milliseconds = Mathf.FloorToInt((time * 100f) % 100f);

        // Only update string if values changed
        if (minutes != lastMinutes || seconds != lastSeconds || milliseconds != lastMilliseconds)
        {
            lastMinutes = minutes;
            lastSeconds = seconds;
            lastMilliseconds = milliseconds;

            timerBuilder.Clear();
            timerBuilder.Append(minutes.ToString("00"));
            timerBuilder.Append(':');
            timerBuilder.Append(seconds.ToString("00"));
            timerBuilder.Append('.');
            timerBuilder.Append(milliseconds.ToString("00"));
            timerText.text = timerBuilder.ToString();
        }
    }

    private void UpdateSpeed()
    {
        if (speedText == null || skier == null) return;

        int speed = Mathf.RoundToInt(skier.CurrentSpeed);

        // Only update if speed changed
        if (speed != lastSpeed)
        {
            lastSpeed = speed;
            speedBuilder.Clear();
            speedBuilder.Append(speed);
            speedBuilder.Append(" km/h");
            speedText.text = speedBuilder.ToString();
        }
    }

    private void UpdateDistance()
    {
        if (distanceText == null || gameManager == null) return;

        int distance = Mathf.FloorToInt(gameManager.DistanceTraveled);

        if (distance != lastDistance)
        {
            lastDistance = distance;
            distanceBuilder.Clear();
            distanceBuilder.Append(distance);
            distanceBuilder.Append("m");
            distanceText.text = distanceBuilder.ToString();
        }
    }

    private void UpdateYetiDistance()
    {
        if (yetiDistanceText == null || yetiController == null) return;

        int yetiDist = Mathf.FloorToInt(yetiController.DistanceToPlayer);

        if (yetiDist != lastYetiDistance)
        {
            lastYetiDistance = yetiDist;
            yetiDistanceText.text = $"YETI: {yetiDist}m behind";

            // Change color based on zone
            yetiDistanceText.color = yetiController.CurrentZone switch
            {
                YetiZone.Safe => Color.white,
                YetiZone.Warning => GameColors.BrightYellow,
                YetiZone.Danger => GameColors.SunsetOrange,
                YetiZone.Critical => GameColors.HotPink,
                _ => Color.white
            };
        }
    }

    private void ShowPenalty(float penalty)
    {
        if (penaltyText == null || gameManager == null) return;
        penaltyText.text = $"+{gameManager.TimePenalty:F1}s";
    }

    private void ShowFinishScreen(float finalTime)
    {
        if (finishPanel != null)
        {
            finishPanel.SetActive(true);
        }

        if (finishText != null)
        {
            int minutes = Mathf.FloorToInt(finalTime / 60f);
            int seconds = Mathf.FloorToInt(finalTime % 60f);
            int milliseconds = Mathf.FloorToInt((finalTime * 100f) % 100f);

            string penaltyInfo = gameManager.GatesMissed > 0
                ? $"\n({gameManager.GatesMissed} gates missed: +{gameManager.TimePenalty:F1}s)"
                : "";

            finishText.text = $"FINISH!\n{minutes:00}:{seconds:00}.{milliseconds:00}{penaltyInfo}";
        }
    }

    private void ShowGameOverScreen(float finalDistance)
    {
        if (gameOverPanel != null)
        {
            gameOverPanel.SetActive(true);
        }

        if (gameOverText != null)
        {
            int distance = Mathf.FloorToInt(finalDistance);
            int minutes = Mathf.FloorToInt(gameManager.ElapsedTime / 60f);
            int seconds = Mathf.FloorToInt(gameManager.ElapsedTime % 60f);

            gameOverText.text = $"CAUGHT BY YETI!\n\nDistance: {distance}m\nTime: {minutes:00}:{seconds:00}";
        }
    }

    public void SetYetiController(YetiController controller)
    {
        yetiController = controller;
    }
}
