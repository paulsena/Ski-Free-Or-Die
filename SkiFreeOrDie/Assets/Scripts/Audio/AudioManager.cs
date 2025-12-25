// Assets/Scripts/Audio/AudioManager.cs
using UnityEngine;
using System.Collections.Generic;

public class AudioManager : MonoBehaviour
{
    public static AudioManager Instance { get; private set; }

    [Header("Audio Sources")]
    [SerializeField] private AudioSource sfxSource;
    [SerializeField] private AudioSource loopSource;
    [SerializeField] private AudioSource musicSource;

    [Header("Audio Clips")]
    [SerializeField] private AudioClip skiLoop;
    [SerializeField] private AudioClip tuckWindLoop;
    [SerializeField] private AudioClip snowSpray;
    [SerializeField] private AudioClip treeHit;
    [SerializeField] private AudioClip rockHit;
    [SerializeField] private AudioClip cabinHit;
    [SerializeField] private AudioClip crash;
    [SerializeField] private AudioClip gatePass;
    [SerializeField] private AudioClip gateMiss;
    [SerializeField] private AudioClip yetiGrowl;
    [SerializeField] private AudioClip yetiFootstep;
    [SerializeField] private AudioClip yetiCatch;
    [SerializeField] private AudioClip menuSelect;
    [SerializeField] private AudioClip gameStart;
    [SerializeField] private AudioClip gameFinish;
    [SerializeField] private AudioClip gameOver;

    [Header("Volume Settings")]
    [SerializeField] private float masterVolume = 1f;
    [SerializeField] private float sfxVolume = 1f;
    [SerializeField] private float musicVolume = 0.7f;
    [SerializeField] private float loopVolume = 0.5f;

    private Dictionary<GameAudioType, AudioClip> clipLookup;
    private GameAudioType currentLoop = GameAudioType.SkiLoop;
    private bool loopPlaying = false;
    private Coroutine crossfadeCoroutine;

    private void Awake()
    {
        if (Instance != null && Instance != this)
        {
            Destroy(gameObject);
            return;
        }

        Instance = this;
        DontDestroyOnLoad(gameObject);
        InitializeClipLookup();
        CreateAudioSources();
    }

    private void CreateAudioSources()
    {
        if (sfxSource == null)
        {
            var sfxGO = new GameObject("SFX Source");
            sfxGO.transform.SetParent(transform);
            sfxSource = sfxGO.AddComponent<AudioSource>();
            sfxSource.playOnAwake = false;
        }

        if (loopSource == null)
        {
            var loopGO = new GameObject("Loop Source");
            loopGO.transform.SetParent(transform);
            loopSource = loopGO.AddComponent<AudioSource>();
            loopSource.playOnAwake = false;
            loopSource.loop = true;
        }

        if (musicSource == null)
        {
            var musicGO = new GameObject("Music Source");
            musicGO.transform.SetParent(transform);
            musicSource = musicGO.AddComponent<AudioSource>();
            musicSource.playOnAwake = false;
            musicSource.loop = true;
        }
    }

    private void InitializeClipLookup()
    {
        clipLookup = new Dictionary<GameAudioType, AudioClip>
        {
            { GameAudioType.SkiLoop, skiLoop },
            { GameAudioType.TuckWindLoop, tuckWindLoop },
            { GameAudioType.SnowSpray, snowSpray },
            { GameAudioType.TreeHit, treeHit },
            { GameAudioType.RockHit, rockHit },
            { GameAudioType.CabinHit, cabinHit },
            { GameAudioType.Crash, crash },
            { GameAudioType.GatePass, gatePass },
            { GameAudioType.GateMiss, gateMiss },
            { GameAudioType.YetiGrowl, yetiGrowl },
            { GameAudioType.YetiFootstep, yetiFootstep },
            { GameAudioType.YetiCatch, yetiCatch },
            { GameAudioType.MenuSelect, menuSelect },
            { GameAudioType.GameStart, gameStart },
            { GameAudioType.GameFinish, gameFinish },
            { GameAudioType.GameOver, gameOver }
        };
    }

    /// <summary>
    /// Play a one-shot sound effect.
    /// </summary>
    public void PlaySFX(GameAudioType audioType, float volumeScale = 1f)
    {
        if (clipLookup.TryGetValue(audioType, out AudioClip clip) && clip != null)
        {
            sfxSource.PlayOneShot(clip, sfxVolume * masterVolume * volumeScale);
        }
    }

    /// <summary>
    /// Start playing a looping sound (e.g., skiing, wind).
    /// </summary>
    public void StartLoop(GameAudioType audioType)
    {
        if (clipLookup.TryGetValue(audioType, out AudioClip clip) && clip != null)
        {
            if (loopSource.clip != clip || !loopSource.isPlaying)
            {
                loopSource.clip = clip;
                loopSource.volume = loopVolume * masterVolume;
                loopSource.Play();
                currentLoop = audioType;
                loopPlaying = true;
            }
        }
    }

    /// <summary>
    /// Stop the current loop.
    /// </summary>
    public void StopLoop()
    {
        loopSource.Stop();
        loopPlaying = false;
    }

    /// <summary>
    /// Set the loop volume dynamically (for speed-based volume scaling).
    /// </summary>
    public void SetLoopVolume(float normalizedVolume)
    {
        loopSource.volume = loopVolume * masterVolume * Mathf.Clamp01(normalizedVolume);
    }

    /// <summary>
    /// Crossfade to a different loop (e.g., from ski to tuck wind).
    /// </summary>
    public void CrossfadeToLoop(GameAudioType audioType, float duration = 0.5f)
    {
        if (currentLoop == audioType && loopPlaying) return;

        // Stop any existing crossfade to prevent race conditions
        if (crossfadeCoroutine != null)
        {
            StopCoroutine(crossfadeCoroutine);
        }

        crossfadeCoroutine = StartCoroutine(CrossfadeCoroutine(audioType, duration));
    }

    private System.Collections.IEnumerator CrossfadeCoroutine(GameAudioType audioType, float duration)
    {
        float startVolume = loopSource.volume;

        // Fade out
        float elapsed = 0f;
        while (elapsed < duration * 0.5f)
        {
            elapsed += Time.deltaTime;
            loopSource.volume = Mathf.Lerp(startVolume, 0f, elapsed / (duration * 0.5f));
            yield return null;
        }

        // Switch clip
        if (clipLookup.TryGetValue(audioType, out AudioClip clip) && clip != null)
        {
            loopSource.clip = clip;
            loopSource.Play();
            currentLoop = audioType;
            loopPlaying = true; // Ensure loopPlaying is set when crossfading
        }

        // Fade in
        elapsed = 0f;
        while (elapsed < duration * 0.5f)
        {
            elapsed += Time.deltaTime;
            loopSource.volume = Mathf.Lerp(0f, loopVolume * masterVolume, elapsed / (duration * 0.5f));
            yield return null;
        }

        loopSource.volume = loopVolume * masterVolume;
        crossfadeCoroutine = null; // Clear reference when complete
    }

    /// <summary>
    /// Set master volume.
    /// </summary>
    public void SetMasterVolume(float volume)
    {
        masterVolume = Mathf.Clamp01(volume);
        UpdateVolumes();
    }

    /// <summary>
    /// Set SFX volume.
    /// </summary>
    public void SetSFXVolume(float volume)
    {
        sfxVolume = Mathf.Clamp01(volume);
    }

    /// <summary>
    /// Set music volume.
    /// </summary>
    public void SetMusicVolume(float volume)
    {
        musicVolume = Mathf.Clamp01(volume);
        if (musicSource != null)
        {
            musicSource.volume = musicVolume * masterVolume;
        }
    }

    private void UpdateVolumes()
    {
        if (loopSource != null && loopPlaying)
        {
            loopSource.volume = loopVolume * masterVolume;
        }
        if (musicSource != null)
        {
            musicSource.volume = musicVolume * masterVolume;
        }
    }
}
