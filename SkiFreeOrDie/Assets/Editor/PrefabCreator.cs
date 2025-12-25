// Assets/Editor/PrefabCreator.cs
using UnityEngine;
using UnityEditor;
using System.IO;

public class PrefabCreator : EditorWindow
{
    [MenuItem("Ski Free Or Die/Create Prefabs/Create Skier Prefab")]
    public static void CreateSkierPrefab()
    {
        // Ensure directories exist
        EnsureDirectoryExists("Assets/Prefabs/Player");
        EnsureDirectoryExists("Assets/Sprites/Player");

        // Create placeholder sprite texture
        string spritePath = "Assets/Sprites/Player/skier_placeholder.png";
        if (!File.Exists(spritePath))
        {
            CreatePlaceholderSprite(spritePath, 16, 24, GameColors.ElectricBlue);
            AssetDatabase.Refresh();
        }

        // Load the sprite
        Sprite skierSprite = AssetDatabase.LoadAssetAtPath<Sprite>(spritePath);

        // Create GameObject
        GameObject skierGO = new GameObject("Skier");

        // Add SpriteRenderer
        SpriteRenderer sr = skierGO.AddComponent<SpriteRenderer>();
        sr.sprite = skierSprite;
        sr.sortingLayerName = "Player";

        // Add Rigidbody2D
        Rigidbody2D rb = skierGO.AddComponent<Rigidbody2D>();
        rb.gravityScale = 0;
        rb.constraints = RigidbodyConstraints2D.FreezeRotation;

        // Add CircleCollider2D (forgiving hitbox)
        CircleCollider2D col = skierGO.AddComponent<CircleCollider2D>();
        col.radius = 0.25f; // 4 pixels at 16 PPU

        // Set layer
        skierGO.layer = LayerMask.NameToLayer("Player");

        // Add SkierController, SkierCollisionHandler, and SkierAnimator
        skierGO.AddComponent<SkierController>();
        skierGO.AddComponent<SkierCollisionHandler>();
        skierGO.AddComponent<SkierAnimator>();

        // Enable interpolation to prevent camera jitter
        rb.interpolation = RigidbodyInterpolation2D.Interpolate;

        // Save as prefab
        string prefabPath = "Assets/Prefabs/Player/Skier.prefab";
        PrefabUtility.SaveAsPrefabAsset(skierGO, prefabPath);
        DestroyImmediate(skierGO);

        Debug.Log($"Skier prefab created at {prefabPath}");
        Selection.activeObject = AssetDatabase.LoadAssetAtPath<GameObject>(prefabPath);
    }

    [MenuItem("Ski Free Or Die/Create Prefabs/Create Obstacle Prefabs")]
    public static void CreateObstaclePrefabs()
    {
        EnsureDirectoryExists("Assets/Prefabs/Obstacles");
        EnsureDirectoryExists("Assets/Sprites/Obstacles");

        CreateObstaclePrefab("SmallTree", 16, 24, GameColors.PineGreen, ObstacleType.SmallTree, 0.25f);
        CreateObstaclePrefab("LargeTree", 24, 32, GameColors.PineGreen, ObstacleType.LargeTree, 0.375f);
        CreateObstaclePrefab("Rock", 16, 16, GameColors.RockGray, ObstacleType.Rock, 0.3125f);
        CreateObstaclePrefab("Cabin", 32, 32, GameColors.CabinBrown, ObstacleType.Cabin, 0.75f, true);

        Debug.Log("All obstacle prefabs created!");
    }

    private static void CreateObstaclePrefab(string name, int width, int height, Color color,
        ObstacleType obstacleType, float colliderSize, bool useBoxCollider = false)
    {
        string spritePath = $"Assets/Sprites/Obstacles/{name.ToLower()}_placeholder.png";
        if (!File.Exists(spritePath))
        {
            CreatePlaceholderSprite(spritePath, width, height, color);
            AssetDatabase.Refresh();
        }

        Sprite sprite = AssetDatabase.LoadAssetAtPath<Sprite>(spritePath);

        GameObject go = new GameObject(name);

        SpriteRenderer sr = go.AddComponent<SpriteRenderer>();
        sr.sprite = sprite;
        sr.sortingLayerName = "Obstacles";

        if (useBoxCollider)
        {
            BoxCollider2D col = go.AddComponent<BoxCollider2D>();
            col.size = new Vector2(colliderSize, colliderSize);
        }
        else
        {
            CircleCollider2D col = go.AddComponent<CircleCollider2D>();
            col.radius = colliderSize;
        }

        go.layer = LayerMask.NameToLayer("Obstacle");

        // Add Obstacle component directly and set type via SerializedObject
        var obstacle = go.AddComponent<Obstacle>();
        // Use SerializedObject to set the private field
        var so = new SerializedObject(obstacle);
        so.FindProperty("obstacleType").enumValueIndex = (int)obstacleType;
        so.ApplyModifiedProperties();

        string prefabPath = $"Assets/Prefabs/Obstacles/{name}.prefab";
        PrefabUtility.SaveAsPrefabAsset(go, prefabPath);
        DestroyImmediate(go);

        Debug.Log($"Created {name} prefab at {prefabPath}");
    }

    [MenuItem("Ski Free Or Die/Create Prefabs/Create Tile Prefab")]
    public static void CreateTilePrefab()
    {
        EnsureDirectoryExists("Assets/Prefabs/Tiles");

        GameObject tileGO = new GameObject("Tile");

        // Add TileInstance component directly
        tileGO.AddComponent<TileInstance>();

        string prefabPath = "Assets/Prefabs/Tiles/Tile.prefab";
        PrefabUtility.SaveAsPrefabAsset(tileGO, prefabPath);
        DestroyImmediate(tileGO);

        Debug.Log($"Tile prefab created at {prefabPath}");
    }

    [MenuItem("Ski Free Or Die/Create Prefabs/Create Gate Prefab")]
    public static void CreateGatePrefab()
    {
        EnsureDirectoryExists("Assets/Prefabs/Gates");
        EnsureDirectoryExists("Assets/Sprites/Gates");

        // Create pole sprite
        string polePath = "Assets/Sprites/Gates/gate_pole_placeholder.png";
        if (!File.Exists(polePath))
        {
            CreatePlaceholderSprite(polePath, 8, 32, GameColors.HotPink);
            AssetDatabase.Refresh();
        }

        // Create flag sprite
        string flagPath = "Assets/Sprites/Gates/gate_flag_placeholder.png";
        if (!File.Exists(flagPath))
        {
            CreatePlaceholderSprite(flagPath, 16, 16, GameColors.HotPink);
            AssetDatabase.Refresh();
        }

        Sprite poleSprite = AssetDatabase.LoadAssetAtPath<Sprite>(polePath);
        Sprite flagSprite = AssetDatabase.LoadAssetAtPath<Sprite>(flagPath);

        // Create gate structure
        GameObject gateGO = new GameObject("Gate");
        gateGO.layer = LayerMask.NameToLayer("Gate");

        // Add trigger collider
        BoxCollider2D col = gateGO.AddComponent<BoxCollider2D>();
        col.size = new Vector2(3f, 0.5f);
        col.isTrigger = true;

        // Left pole
        GameObject leftPole = new GameObject("LeftPole");
        leftPole.transform.SetParent(gateGO.transform);
        leftPole.transform.localPosition = new Vector3(-1f, 0, 0);
        SpriteRenderer leftSR = leftPole.AddComponent<SpriteRenderer>();
        leftSR.sprite = poleSprite;
        leftSR.sortingLayerName = "Gates";

        // Right pole
        GameObject rightPole = new GameObject("RightPole");
        rightPole.transform.SetParent(gateGO.transform);
        rightPole.transform.localPosition = new Vector3(1f, 0, 0);
        SpriteRenderer rightSR = rightPole.AddComponent<SpriteRenderer>();
        rightSR.sprite = poleSprite;
        rightSR.sortingLayerName = "Gates";

        // Flag
        GameObject flag = new GameObject("Flag");
        flag.transform.SetParent(gateGO.transform);
        flag.transform.localPosition = new Vector3(0, 1f, 0);
        SpriteRenderer flagSR = flag.AddComponent<SpriteRenderer>();
        flagSR.sprite = flagSprite;
        flagSR.sortingLayerName = "Gates";

        // Add GateTrigger and set references
        GateTrigger gateTrigger = gateGO.AddComponent<GateTrigger>();
        gateTrigger.SetVisualReferences(leftSR, rightSR, flagSR);

        // Add GateEffects for visual/audio feedback
        gateGO.AddComponent<GateEffects>();

        string prefabPath = "Assets/Prefabs/Gates/Gate.prefab";
        PrefabUtility.SaveAsPrefabAsset(gateGO, prefabPath);
        DestroyImmediate(gateGO);

        Debug.Log($"Gate prefab created at {prefabPath}");
    }

    [MenuItem("Ski Free Or Die/Create Prefabs/Create Yeti Prefab")]
    public static void CreateYetiPrefab()
    {
        EnsureDirectoryExists("Assets/Prefabs/Yeti");
        EnsureDirectoryExists("Assets/Sprites/Yeti");

        // Create Yeti sprite (larger, menacing)
        string spritePath = "Assets/Sprites/Yeti/yeti_placeholder.png";
        if (!File.Exists(spritePath))
        {
            CreatePlaceholderSprite(spritePath, 32, 48, GameColors.SnowWhite);
            AssetDatabase.Refresh();
        }

        Sprite yetiSprite = AssetDatabase.LoadAssetAtPath<Sprite>(spritePath);

        // Create GameObject
        GameObject yetiGO = new GameObject("Yeti");

        // Add SpriteRenderer
        SpriteRenderer sr = yetiGO.AddComponent<SpriteRenderer>();
        sr.sprite = yetiSprite;
        sr.sortingLayerName = "Effects"; // Render above everything

        // Add YetiController and YetiAnimator
        yetiGO.AddComponent<YetiController>();
        yetiGO.AddComponent<YetiAnimator>();

        string prefabPath = "Assets/Prefabs/Yeti/Yeti.prefab";
        PrefabUtility.SaveAsPrefabAsset(yetiGO, prefabPath);
        DestroyImmediate(yetiGO);

        Debug.Log($"Yeti prefab created at {prefabPath}");
    }

    private static void CreatePlaceholderSprite(string path, int width, int height, Color color)
    {
        Texture2D texture = new Texture2D(width, height);
        Color[] pixels = new Color[width * height];
        for (int i = 0; i < pixels.Length; i++)
        {
            pixels[i] = color;
        }
        texture.SetPixels(pixels);
        texture.Apply();

        byte[] bytes = texture.EncodeToPNG();
        File.WriteAllBytes(path, bytes);
        Object.DestroyImmediate(texture);
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
