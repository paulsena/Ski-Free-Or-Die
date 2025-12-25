// Assets/Scripts/World/TileInstance.cs
using UnityEngine;
using System.Collections.Generic;

public class TileInstance : MonoBehaviour
{
    [SerializeField] private TileData data;
    [SerializeField] private float tileHeight = 20f;
    [SerializeField] private float tileWidth = 15f;

    private List<GameObject> spawnedObstacles = new List<GameObject>();
    private List<GameObject> spawnedGates = new List<GameObject>();
    private static int gateIndexCounter = 0;

    public float TileHeight => tileHeight;
    public float TopEdge => transform.position.y + tileHeight / 2f;
    public float BottomEdge => transform.position.y - tileHeight / 2f;
    public TileData Data => data;

    public void Initialize(TileData tileData, Dictionary<ObstacleType, GameObject> obstaclePrefabs,
        GameObject gatePrefab = null, GateManager gateManager = null)
    {
        data = tileData;
        SpawnObstacles(obstaclePrefabs);
        SpawnGates(gatePrefab, gateManager);
    }

    // Overload for backwards compatibility
    public void Initialize(TileData tileData, Dictionary<ObstacleType, GameObject> obstaclePrefabs)
    {
        Initialize(tileData, obstaclePrefabs, null, null);
    }

    private void SpawnObstacles(Dictionary<ObstacleType, GameObject> prefabs)
    {
        foreach (var spawn in data.Obstacles)
        {
            if (!prefabs.TryGetValue(spawn.Type, out var prefab)) continue;

            float x = (spawn.NormalizedX - 0.5f) * tileWidth;
            float y = (spawn.NormalizedY - 0.5f) * tileHeight;
            Vector3 localPos = new Vector3(x, y, 0);

            var obstacle = Instantiate(prefab, transform);
            obstacle.transform.localPosition = localPos;
            spawnedObstacles.Add(obstacle);
        }
    }

    private void SpawnGates(GameObject gatePrefab, GateManager gateManager)
    {
        if (gatePrefab == null || data.Gates == null || data.Gates.Count == 0) return;

        foreach (var spawn in data.Gates)
        {
            float x = (spawn.NormalizedX - 0.5f) * tileWidth;
            float y = (spawn.NormalizedY - 0.5f) * tileHeight;
            Vector3 localPos = new Vector3(x, y, 0);

            var gateGO = Instantiate(gatePrefab, transform);
            gateGO.transform.localPosition = localPos;
            spawnedGates.Add(gateGO);

            // Initialize the gate trigger
            var gateTrigger = gateGO.GetComponent<GateTrigger>();
            if (gateTrigger != null && gateManager != null)
            {
                gateTrigger.Initialize(gateManager, gateIndexCounter++);
            }
        }
    }

    public void Cleanup()
    {
        foreach (var obstacle in spawnedObstacles)
        {
            if (obstacle != null)
            {
                Destroy(obstacle);
            }
        }
        spawnedObstacles.Clear();

        foreach (var gate in spawnedGates)
        {
            if (gate != null)
            {
                Destroy(gate);
            }
        }
        spawnedGates.Clear();
    }

    public static void ResetGateCounter()
    {
        gateIndexCounter = 0;
    }
}
