// Assets/Scripts/World/WorldManager.cs
using UnityEngine;
using System.Collections.Generic;

public class WorldManager : MonoBehaviour
{
    [Header("Mode")]
    [SerializeField] private bool isEndlessMode = false;

    [Header("Generation")]
    [SerializeField] private int seed = 12345;
    [SerializeField] private int totalTiles = 20;

    [Header("Tile Settings")]
    [SerializeField] private float tileHeight = 20f;
    [SerializeField] private float tileWidth = 15f;
    [SerializeField] private int tilesAhead = 3;
    [SerializeField] private int tilesBehind = 1;

    [Header("Prefabs")]
    [SerializeField] private GameObject tilePrefab;
    [SerializeField] private GameObject smallTreePrefab;
    [SerializeField] private GameObject largeTreePrefab;
    [SerializeField] private GameObject rockPrefab;
    [SerializeField] private GameObject cabinPrefab;
    [SerializeField] private GameObject gatePrefab;

    [Header("References")]
    [SerializeField] private Transform player;
    [SerializeField] private SeedLoader seedLoader;
    [SerializeField] private GameManager gameManager;

    private TileGenerator generator;
    private List<TileData> courseData;
    private Dictionary<int, TileInstance> activeTiles = new Dictionary<int, TileInstance>();
    private Dictionary<ObstacleType, GameObject> obstaclePrefabs;
    private int currentTileIndex = 0;
    private int highestGeneratedTile = -1;

    public int TotalTiles => isEndlessMode ? int.MaxValue : totalTiles;
    public int CurrentTileIndex => currentTileIndex;
    public float TileHeight => tileHeight;
    public bool IsEndlessMode => isEndlessMode;

    private void Awake()
    {
        obstaclePrefabs = new Dictionary<ObstacleType, GameObject>
        {
            { ObstacleType.SmallTree, smallTreePrefab },
            { ObstacleType.LargeTree, largeTreePrefab },
            { ObstacleType.Rock, rockPrefab },
            { ObstacleType.Cabin, cabinPrefab }
        };
    }

    private void Start()
    {
        // Check game mode from GameManager
        if (gameManager != null)
        {
            isEndlessMode = gameManager.CurrentMode == GameMode.Endless;
        }

        if (seedLoader != null)
        {
            seed = seedLoader.WeeklySeed;
        }
        TileInstance.ResetGateCounter();
        GenerateCourse();
        SpawnInitialTiles();
    }

    private void Update()
    {
        if (player == null) return;

        UpdateCurrentTileIndex();
        ManageActiveTiles();
        UpdatePlayerSlopeMultiplier();
    }

    private void GenerateCourse()
    {
        generator = new TileGenerator(seed);

        if (isEndlessMode)
        {
            // For endless mode, start with a few tiles and generate more as needed
            courseData = generator.GenerateCourse(tilesAhead + 5);
            highestGeneratedTile = courseData.Count - 1;
        }
        else
        {
            courseData = generator.GenerateCourse(totalTiles);
            highestGeneratedTile = totalTiles - 1;
        }
    }

    private void SpawnInitialTiles()
    {
        for (int i = 0; i <= tilesAhead; i++)
        {
            SpawnTile(i);
        }
    }

    private void UpdateCurrentTileIndex()
    {
        float playerY = player.position.y;
        currentTileIndex = Mathf.FloorToInt(-playerY / tileHeight);

        if (!isEndlessMode)
        {
            currentTileIndex = Mathf.Clamp(currentTileIndex, 0, totalTiles - 1);
        }
        else
        {
            currentTileIndex = Mathf.Max(0, currentTileIndex);
        }
    }

    private void ManageActiveTiles()
    {
        int minTile = Mathf.Max(0, currentTileIndex - tilesBehind);
        int maxTile = currentTileIndex + tilesAhead;

        if (!isEndlessMode)
        {
            maxTile = Mathf.Min(totalTiles - 1, maxTile);
        }

        // Generate more tiles if needed for endless mode
        if (isEndlessMode && maxTile > highestGeneratedTile)
        {
            GenerateMoreTiles(maxTile);
        }

        // Spawn new tiles
        for (int i = minTile; i <= maxTile; i++)
        {
            if (!activeTiles.ContainsKey(i))
            {
                SpawnTile(i);
            }
        }

        // Remove old tiles
        var toRemove = new List<int>();
        foreach (var kvp in activeTiles)
        {
            if (kvp.Key < minTile || kvp.Key > maxTile)
            {
                toRemove.Add(kvp.Key);
            }
        }

        foreach (int index in toRemove)
        {
            DespawnTile(index);
        }
    }

    private void GenerateMoreTiles(int targetIndex)
    {
        // Generate tiles up to the target index
        while (highestGeneratedTile < targetIndex)
        {
            highestGeneratedTile++;

            // Calculate endless mode difficulty scaling
            float progress = Mathf.Min(1f, highestGeneratedTile / 100f); // Max difficulty at tile 100
            var tileData = generator.GenerateSingleTile(progress);
            courseData.Add(tileData);
        }
    }

    private void SpawnTile(int index)
    {
        if (index < 0 || index >= courseData.Count) return;
        if (activeTiles.ContainsKey(index)) return;

        Vector3 position = new Vector3(0, -index * tileHeight, 0);

        GameObject tileGO;
        if (tilePrefab != null)
        {
            tileGO = Instantiate(tilePrefab, position, Quaternion.identity, transform);
        }
        else
        {
            tileGO = new GameObject($"Tile_{index}");
            tileGO.transform.position = position;
            tileGO.transform.SetParent(transform);
        }

        var tileInstance = tileGO.GetComponent<TileInstance>();

        if (tileInstance == null)
        {
            tileInstance = tileGO.AddComponent<TileInstance>();
        }

        var gateManagerRef = gameManager != null ? gameManager.GetGateManager() : null;
        tileInstance.Initialize(courseData[index], obstaclePrefabs, gatePrefab, gateManagerRef);
        activeTiles[index] = tileInstance;
    }

    private void DespawnTile(int index)
    {
        if (!activeTiles.TryGetValue(index, out var tile)) return;

        tile.Cleanup();
        Destroy(tile.gameObject);
        activeTiles.Remove(index);
    }

    private void UpdatePlayerSlopeMultiplier()
    {
        if (activeTiles.TryGetValue(currentTileIndex, out var tile))
        {
            var skier = player.GetComponent<SkierController>();
            if (skier != null)
            {
                skier.SetSlopeMultiplier(tile.Data.GetSlopeMultiplier());
            }
        }
    }

    public void SetSeed(int newSeed)
    {
        seed = newSeed;
    }

    public void SetEndlessMode(bool endless)
    {
        isEndlessMode = endless;
    }
}
