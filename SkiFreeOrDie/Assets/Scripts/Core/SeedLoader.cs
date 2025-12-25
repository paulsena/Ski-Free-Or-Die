// Assets/Scripts/Core/SeedLoader.cs
using UnityEngine;

[System.Serializable]
public class SeedConfig
{
    public int weeklySeed;
    public int[] testSeeds;
}

public class SeedLoader : MonoBehaviour
{
    [SerializeField] private TextAsset seedsFile;

    private SeedConfig config;

    public int WeeklySeed => config?.weeklySeed ?? 12345;

    private void Awake()
    {
        LoadSeeds();
    }

    private void LoadSeeds()
    {
        if (seedsFile == null)
        {
            Debug.LogWarning("No seeds file assigned, using default seed");
            config = new SeedConfig { weeklySeed = 12345 };
            return;
        }

        config = JsonUtility.FromJson<SeedConfig>(seedsFile.text);
    }

    public int GetSeed(bool useWeekly = true)
    {
        if (useWeekly)
        {
            return WeeklySeed;
        }

        // Return random test seed
        if (config.testSeeds != null && config.testSeeds.Length > 0)
        {
            return config.testSeeds[Random.Range(0, config.testSeeds.Length)];
        }

        return 12345;
    }
}
