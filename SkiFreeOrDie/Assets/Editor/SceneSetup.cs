// Assets/Editor/SceneSetup.cs
using UnityEngine;
using UnityEditor;
using UnityEditor.SceneManagement;

public class SceneSetup : EditorWindow
{
    [MenuItem("Ski Free Or Die/Setup Scene/Create Game Scene")]
    public static void CreateGameScene()
    {
        // Create new scene
        var scene = EditorSceneManager.NewScene(NewSceneSetup.DefaultGameObjects, NewSceneMode.Single);

        // Setup camera
        var mainCamera = Camera.main;
        if (mainCamera != null)
        {
            mainCamera.orthographic = true;
            mainCamera.orthographicSize = 8f;
            mainCamera.clearFlags = CameraClearFlags.SolidColor;
            mainCamera.backgroundColor = new Color(0.9f, 0.95f, 1f); // Light snow color

            var cameraFollow = mainCamera.gameObject.AddComponent<CameraFollow>();
        }

        // Create AudioManager
        var audioManagerGO = new GameObject("AudioManager");
        audioManagerGO.AddComponent<AudioManager>();

        // Create GameManager
        var gameManagerGO = new GameObject("GameManager");
        var gameManager = gameManagerGO.AddComponent<GameManager>();
        var worldManager = gameManagerGO.AddComponent<WorldManager>();

        // Load and instantiate Skier prefab
        var skierPrefab = AssetDatabase.LoadAssetAtPath<GameObject>("Assets/Prefabs/Player/Skier.prefab");
        GameObject skier = null;
        if (skierPrefab != null)
        {
            skier = (GameObject)PrefabUtility.InstantiatePrefab(skierPrefab);
            skier.transform.position = new Vector3(0, 0, 0);
        }
        else
        {
            Debug.LogWarning("Skier prefab not found! Run 'Create Prefabs' first.");
            // Create a placeholder
            skier = new GameObject("Skier");
            var sr = skier.AddComponent<SpriteRenderer>();
            sr.color = GameColors.ElectricBlue;
            skier.AddComponent<Rigidbody2D>().gravityScale = 0;
            skier.AddComponent<CircleCollider2D>();
            skier.AddComponent<SkierController>();
            skier.AddComponent<SkierCollisionHandler>();
        }

        // Wire up references
        if (mainCamera != null)
        {
            var cameraFollow = mainCamera.GetComponent<CameraFollow>();
            if (cameraFollow != null)
            {
                // Set target via SerializedObject
                var so = new SerializedObject(cameraFollow);
                so.FindProperty("target").objectReferenceValue = skier.transform;
                so.ApplyModifiedProperties();
            }
        }

        // Set GameManager references
        var gmSO = new SerializedObject(gameManager);
        gmSO.FindProperty("player").objectReferenceValue = skier.GetComponent<SkierController>();
        gmSO.FindProperty("worldManager").objectReferenceValue = worldManager;
        gmSO.ApplyModifiedProperties();

        // Load prefabs for WorldManager
        var tilePrefab = AssetDatabase.LoadAssetAtPath<GameObject>("Assets/Prefabs/Tiles/Tile.prefab");
        var smallTreePrefab = AssetDatabase.LoadAssetAtPath<GameObject>("Assets/Prefabs/Obstacles/SmallTree.prefab");
        var largeTreePrefab = AssetDatabase.LoadAssetAtPath<GameObject>("Assets/Prefabs/Obstacles/LargeTree.prefab");
        var rockPrefab = AssetDatabase.LoadAssetAtPath<GameObject>("Assets/Prefabs/Obstacles/Rock.prefab");
        var gatePrefab = AssetDatabase.LoadAssetAtPath<GameObject>("Assets/Prefabs/Gates/Gate.prefab");

        var wmSO = new SerializedObject(worldManager);
        wmSO.FindProperty("tilePrefab").objectReferenceValue = tilePrefab;
        wmSO.FindProperty("gatePrefab").objectReferenceValue = gatePrefab;

        // Set individual obstacle prefabs
        wmSO.FindProperty("smallTreePrefab").objectReferenceValue = smallTreePrefab;
        wmSO.FindProperty("largeTreePrefab").objectReferenceValue = largeTreePrefab;
        wmSO.FindProperty("rockPrefab").objectReferenceValue = rockPrefab;

        // Load and set cabin prefab
        var cabinPrefab = AssetDatabase.LoadAssetAtPath<GameObject>("Assets/Prefabs/Obstacles/Cabin.prefab");
        wmSO.FindProperty("cabinPrefab").objectReferenceValue = cabinPrefab;

        wmSO.FindProperty("player").objectReferenceValue = skier.transform;
        wmSO.FindProperty("gameManager").objectReferenceValue = gameManager;
        wmSO.ApplyModifiedProperties();

        // Create snow background
        var backgroundGO = new GameObject("SnowBackground");
        var bgSR = backgroundGO.AddComponent<SpriteRenderer>();
        bgSR.color = GameColors.SnowWhite;
        bgSR.sortingLayerName = "Background";
        bgSR.sortingOrder = -100;
        backgroundGO.transform.position = new Vector3(0, 0, 10);
        backgroundGO.transform.localScale = new Vector3(100, 200, 1);

        // Create HUD Canvas
        var canvasGO = new GameObject("HUDCanvas");
        var canvas = canvasGO.AddComponent<Canvas>();
        canvas.renderMode = RenderMode.ScreenSpaceOverlay;
        canvasGO.AddComponent<UnityEngine.UI.CanvasScaler>();
        canvasGO.AddComponent<UnityEngine.UI.GraphicRaycaster>();

        // Create basic HUD text
        CreateHUDText(canvasGO.transform, "TimerText", new Vector2(0, -30), "00:00.00");
        CreateHUDText(canvasGO.transform, "SpeedText", new Vector2(0, -60), "0 km/h");

        var hudGO = new GameObject("GameHUD");
        hudGO.transform.SetParent(canvasGO.transform);
        var hud = hudGO.AddComponent<GameHUD>();

        // Wire up HUD
        var hudSO = new SerializedObject(hud);
        hudSO.FindProperty("gameManager").objectReferenceValue = gameManager;
        hudSO.FindProperty("skier").objectReferenceValue = skier.GetComponent<SkierController>();
        hudSO.ApplyModifiedProperties();

        // Save scene
        string scenePath = "Assets/Scenes/GameScene.unity";
        EnsureDirectoryExists("Assets/Scenes");
        EditorSceneManager.SaveScene(scene, scenePath);

        Debug.Log("Game scene created and saved to " + scenePath);
        Debug.Log("Press Play to test!");
    }

    private static void CreateHUDText(Transform parent, string name, Vector2 position, string defaultText)
    {
        var textGO = new GameObject(name);
        textGO.transform.SetParent(parent);

        var rectTransform = textGO.AddComponent<RectTransform>();
        rectTransform.anchorMin = new Vector2(0.5f, 1f);
        rectTransform.anchorMax = new Vector2(0.5f, 1f);
        rectTransform.anchoredPosition = position;
        rectTransform.sizeDelta = new Vector2(200, 30);

        var text = textGO.AddComponent<UnityEngine.UI.Text>();
        text.text = defaultText;
        text.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
        text.fontSize = 24;
        text.alignment = TextAnchor.MiddleCenter;
        text.color = Color.black;
    }

    private static void EnsureDirectoryExists(string path)
    {
        if (!AssetDatabase.IsValidFolder(path))
        {
            string[] parts = path.Split('/');
            string currentPath = parts[0];
            for (int i = 1; i < parts.Length; i++)
            {
                string newPath = currentPath + "/" + parts[i];
                if (!AssetDatabase.IsValidFolder(newPath))
                {
                    AssetDatabase.CreateFolder(currentPath, parts[i]);
                }
                currentPath = newPath;
            }
        }
    }
}
