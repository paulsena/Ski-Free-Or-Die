// Assets/Scripts/UI/MainMenuManager.cs
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.SceneManagement;

public class MainMenuManager : MonoBehaviour
{
    [Header("UI References")]
    [SerializeField] private Button timeTrialButton;
    [SerializeField] private Button endlessModeButton;
    [SerializeField] private Button settingsButton;
    [SerializeField] private Button quitButton;
    [SerializeField] private GameObject settingsPanel;

    [Header("Scene Names")]
    [SerializeField] private string gameSceneName = "GameScene";

    [Header("Settings")]
    [SerializeField] private Slider masterVolumeSlider;
    [SerializeField] private Slider sfxVolumeSlider;

    private static GameMode selectedMode = GameMode.TimeTrial;
    public static GameMode SelectedMode => selectedMode;

    private void Start()
    {
        SetupButtons();
        SetupSettings();

        if (settingsPanel != null)
        {
            settingsPanel.SetActive(false);
        }
    }

    private void SetupButtons()
    {
        if (timeTrialButton != null)
        {
            timeTrialButton.onClick.AddListener(StartTimeTrial);
        }

        if (endlessModeButton != null)
        {
            endlessModeButton.onClick.AddListener(StartEndlessMode);
        }

        if (settingsButton != null)
        {
            settingsButton.onClick.AddListener(ToggleSettings);
        }

        if (quitButton != null)
        {
            quitButton.onClick.AddListener(QuitGame);
        }
    }

    private void SetupSettings()
    {
        if (masterVolumeSlider != null)
        {
            masterVolumeSlider.value = PlayerPrefs.GetFloat("MasterVolume", 1f);
            masterVolumeSlider.onValueChanged.AddListener(SetMasterVolume);
        }

        if (sfxVolumeSlider != null)
        {
            sfxVolumeSlider.value = PlayerPrefs.GetFloat("SFXVolume", 1f);
            sfxVolumeSlider.onValueChanged.AddListener(SetSFXVolume);
        }
    }

    public void StartTimeTrial()
    {
        selectedMode = GameMode.TimeTrial;
        PlaySelectSound();
        LoadGameScene();
    }

    public void StartEndlessMode()
    {
        selectedMode = GameMode.Endless;
        PlaySelectSound();
        LoadGameScene();
    }

    private void LoadGameScene()
    {
        SceneManager.LoadScene(gameSceneName);
    }

    public void ToggleSettings()
    {
        if (settingsPanel != null)
        {
            settingsPanel.SetActive(!settingsPanel.activeSelf);
            PlaySelectSound();
        }
    }

    public void CloseSettings()
    {
        if (settingsPanel != null)
        {
            settingsPanel.SetActive(false);
            PlaySelectSound();
        }
    }

    public void SetMasterVolume(float volume)
    {
        PlayerPrefs.SetFloat("MasterVolume", volume);
        if (AudioManager.Instance != null)
        {
            AudioManager.Instance.SetMasterVolume(volume);
        }
    }

    public void SetSFXVolume(float volume)
    {
        PlayerPrefs.SetFloat("SFXVolume", volume);
        if (AudioManager.Instance != null)
        {
            AudioManager.Instance.SetSFXVolume(volume);
        }
    }

    public void QuitGame()
    {
        PlaySelectSound();
#if UNITY_EDITOR
        UnityEditor.EditorApplication.isPlaying = false;
#else
        Application.Quit();
#endif
    }

    private void PlaySelectSound()
    {
        if (AudioManager.Instance != null)
        {
            AudioManager.Instance.PlaySFX(GameAudioType.MenuSelect);
        }
    }
}
