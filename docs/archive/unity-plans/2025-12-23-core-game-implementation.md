# Core Game Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a playable skiing game with physics-based movement, procedural obstacles, and a timed finish line.

**Architecture:** Unity 2D project with top-down scrolling view. Skier stays centered, world scrolls. Tile-based procedural generation spawns chunks ahead of the player and despawns behind. Physics uses Unity's Rigidbody2D with custom acceleration/turning logic.

**Tech Stack:** Unity 2022.3 LTS, C#, Unity Test Framework, 2D URP (optional for effects later)

---

## Phase: Project Setup

### Task 1: Create Unity Project and Configure Settings

**Files:**
- Create: Unity project at `/Users/paulsena/Documents/coding/SkiFreeOrDie/SkiFreeOrDie/`
- Create: `Assets/Editor/ProjectSetup.cs`
- Create: `Assets/Editor/SpriteImportSettings.cs`
- Create: `Assets/Editor/CameraSetup.cs`
- Create: `Assets/Scripts/Core/GameColors.cs`

**Step 1: Create new Unity 2D project**

```bash
# Using Unity Hub CLI or manually create via Unity Hub
# Project name: SkiFreeOrDie
# Template: 2D (Built-in Render Pipeline)
# Location: /Users/paulsena/Documents/coding/SkiFreeOrDie/
```

**Step 2: Verify project structure exists**

Expected folders:
- `SkiFreeOrDie/Assets/`
- `SkiFreeOrDie/Packages/`
- `SkiFreeOrDie/ProjectSettings/`

**Step 3: Create folder structure**

Create these folders in Assets:
```
Assets/
├── Editor/
├── Scripts/
│   ├── Player/
│   ├── World/
│   ├── Obstacles/
│   └── Core/
├── Prefabs/
│   ├── Player/
│   ├── Obstacles/
│   ├── Gates/
│   └── Tiles/
├── Scenes/
├── Sprites/
│   ├── Player/
│   ├── Obstacles/
│   ├── Gates/
│   └── Environment/
├── Tests/
│   ├── EditMode/
│   └── PlayMode/
└── Config/
```

**Step 4: Create Editor setup scripts**

Create `Assets/Editor/ProjectSetup.cs`:

```csharp
// Assets/Editor/ProjectSetup.cs
using UnityEngine;
using UnityEditor;

public class ProjectSetup : EditorWindow
{
    [MenuItem("Ski Free Or Die/Setup Project")]
    public static void SetupProject()
    {
        SetupLayers();
        SetupSortingLayers();
        SetupPhysics2D();
        SetupQualitySettings();

        Debug.Log("Project setup complete!");
        EditorUtility.DisplayDialog("Setup Complete",
            "Project configured successfully.\n\n" +
            "- Layers created\n" +
            "- Sorting layers created\n" +
            "- Physics2D configured\n" +
            "- Quality settings applied", "OK");
    }

    private static void SetupLayers()
    {
        SerializedObject tagManager = new SerializedObject(
            AssetDatabase.LoadAllAssetsAtPath("ProjectSettings/TagManager.asset")[0]);
        SerializedProperty layers = tagManager.FindProperty("layers");

        SetLayer(layers, 6, "Player");
        SetLayer(layers, 7, "Obstacle");
        SetLayer(layers, 8, "Gate");
        SetLayer(layers, 9, "Terrain");
        SetLayer(layers, 10, "Trigger");

        tagManager.ApplyModifiedProperties();
        Debug.Log("Layers configured: Player(6), Obstacle(7), Gate(8), Terrain(9), Trigger(10)");
    }

    private static void SetLayer(SerializedProperty layers, int index, string name)
    {
        SerializedProperty layer = layers.GetArrayElementAtIndex(index);
        if (string.IsNullOrEmpty(layer.stringValue))
        {
            layer.stringValue = name;
        }
    }

    private static void SetupSortingLayers()
    {
        SerializedObject tagManager = new SerializedObject(
            AssetDatabase.LoadAllAssetsAtPath("ProjectSettings/TagManager.asset")[0]);
        SerializedProperty sortingLayers = tagManager.FindProperty("m_SortingLayers");

        string[] layerNames = { "Background", "Terrain", "Obstacles", "Gates", "Player", "Effects" };

        while (sortingLayers.arraySize > 1)
        {
            sortingLayers.DeleteArrayElementAtIndex(sortingLayers.arraySize - 1);
        }

        foreach (string layerName in layerNames)
        {
            sortingLayers.InsertArrayElementAtIndex(sortingLayers.arraySize);
            SerializedProperty newLayer = sortingLayers.GetArrayElementAtIndex(sortingLayers.arraySize - 1);
            newLayer.FindPropertyRelative("name").stringValue = layerName;
            newLayer.FindPropertyRelative("uniqueID").intValue = layerName.GetHashCode();
        }

        tagManager.ApplyModifiedProperties();
        Debug.Log("Sorting layers configured: Background, Terrain, Obstacles, Gates, Player, Effects");
    }

    private static void SetupPhysics2D()
    {
        Physics2D.gravity = Vector2.zero;

        int playerLayer = 6;
        int obstacleLayer = 7;
        int gateLayer = 8;
        int terrainLayer = 9;
        int triggerLayer = 10;

        for (int i = 6; i <= 10; i++)
        {
            for (int j = 6; j <= 10; j++)
            {
                Physics2D.IgnoreLayerCollision(i, j, true);
            }
        }

        Physics2D.IgnoreLayerCollision(playerLayer, obstacleLayer, false);
        Physics2D.IgnoreLayerCollision(playerLayer, gateLayer, false);
        Physics2D.IgnoreLayerCollision(playerLayer, terrainLayer, false);
        Physics2D.IgnoreLayerCollision(playerLayer, triggerLayer, false);

        Debug.Log("Physics2D configured: Gravity=0, Player collides with Obstacle/Gate/Terrain/Trigger");
    }

    private static void SetupQualitySettings()
    {
        QualitySettings.pixelLightCount = 0;
        QualitySettings.anisotropicFiltering = AnisotropicFiltering.Disable;
        QualitySettings.antiAliasing = 0;
        QualitySettings.vSyncCount = 1;

        Debug.Log("Quality settings configured: No pixel lights, no AA, VSync on");
    }
}
```

Create `Assets/Editor/SpriteImportSettings.cs`:

```csharp
// Assets/Editor/SpriteImportSettings.cs
using UnityEditor;
using UnityEngine;

public class SpriteImportSettings : AssetPostprocessor
{
    void OnPreprocessTexture()
    {
        if (assetPath.Contains("Sprites"))
        {
            TextureImporter importer = (TextureImporter)assetImporter;
            importer.textureType = TextureImporterType.Sprite;
            importer.spritePixelsPerUnit = 16;
            importer.filterMode = FilterMode.Point;
            importer.textureCompression = TextureImporterCompression.Uncompressed;
            importer.mipmapEnabled = false;
        }
    }
}
```

Create `Assets/Editor/CameraSetup.cs`:

```csharp
// Assets/Editor/CameraSetup.cs
using UnityEngine;
using UnityEditor;

public class CameraSetup : EditorWindow
{
    [MenuItem("Ski Free Or Die/Setup Main Camera")]
    public static void SetupCamera()
    {
        Camera cam = Camera.main;
        if (cam == null)
        {
            Debug.LogError("No Main Camera found in scene!");
            return;
        }

        cam.orthographic = true;
        cam.orthographicSize = 5.625f;
        cam.backgroundColor = new Color(0.529f, 0.808f, 0.922f); // #87CEEB Sky Blue
        cam.clearFlags = CameraClearFlags.SolidColor;

        Debug.Log("Main Camera configured: Orthographic, size 5.625, sky blue background");
    }
}
```

Create `Assets/Scripts/Core/GameColors.cs`:

```csharp
// Assets/Scripts/Core/GameColors.cs
using UnityEngine;

/// <summary>
/// 80s "Windbreaker" color palette for Ski Free Or Die.
/// Reference these constants instead of hardcoding hex values.
/// </summary>
public static class GameColors
{
    // Primary Palette
    public static readonly Color HotPink = new Color(1f, 0.078f, 0.576f);           // #FF1493
    public static readonly Color ElectricBlue = new Color(0f, 1f, 1f);               // #00FFFF
    public static readonly Color BrightYellow = new Color(1f, 0.843f, 0f);           // #FFD700
    public static readonly Color MintGreen = new Color(0f, 1f, 0.498f);              // #00FF7F
    public static readonly Color SnowWhite = new Color(1f, 0.98f, 0.98f);            // #FFFAFA

    // Secondary Palette
    public static readonly Color DeepPurple = new Color(0.58f, 0f, 0.827f);          // #9400D3
    public static readonly Color SunsetOrange = new Color(1f, 0.271f, 0f);           // #FF4500
    public static readonly Color SkyBlue = new Color(0.529f, 0.808f, 0.922f);        // #87CEEB
    public static readonly Color PineGreen = new Color(0.133f, 0.545f, 0.133f);      // #228B22
    public static readonly Color RockGray = new Color(0.412f, 0.412f, 0.412f);       // #696969
    public static readonly Color CabinBrown = new Color(0.545f, 0.271f, 0.075f);     // #8B4513

    // UI Colors
    public static readonly Color UIPanelBackground = new Color(0f, 0f, 0f, 0.8f);    // #000000CC

    // Gate States
    public static readonly Color GatePending = HotPink;
    public static readonly Color GatePassed = MintGreen;
    public static readonly Color GateMissed = RockGray;
}
```

**Step 5: Create main scene**

- Create `Assets/Scenes/Game.unity`
- Set as default scene in Build Settings

**Step 6: Run setup scripts**

In Unity Editor:
1. Menu > Ski Free Or Die > Setup Project
2. Menu > Ski Free Or Die > Setup Main Camera

**Step 7: Verification**

- [ ] Check Edit > Project Settings > Tags and Layers - should show Player(6), Obstacle(7), Gate(8), Terrain(9), Trigger(10)
- [ ] Check Edit > Project Settings > Physics 2D - gravity should be (0,0)
- [ ] Check sorting layers exist: Background, Terrain, Obstacles, Gates, Player, Effects
- [ ] Select Main Camera - orthographic size should be 5.625

**Step 8: Commit**

```bash
git add .
git commit -m "feat: initialize Unity project with automated setup scripts"
```

---

### Task 2: Configure Unity Test Framework

**Files:**
- Create: `Assets/Tests/EditMode/EditModeTests.asmdef`
- Create: `Assets/Tests/PlayMode/PlayModeTests.asmdef`

**Step 1: Create Edit Mode test assembly**

In Unity Editor:
1. Right-click `Assets/Tests/EditMode/`
2. Create > Assembly Definition
3. Name: `EditModeTests`
4. In Inspector, check "Test Assemblies" under "Define Constraints"
5. Add platform: Editor only

**Step 2: Create Play Mode test assembly**

1. Right-click `Assets/Tests/PlayMode/`
2. Create > Assembly Definition
3. Name: `PlayModeTests`
4. Check "Test Assemblies"
5. Add reference to main game assembly (after we create it)

**Step 3: Create main scripts assembly**

Create `Assets/Scripts/SkiFreeOrDie.asmdef`:
- Name: `SkiFreeOrDie`
- No special settings needed

**Step 4: Verify test runner works**

1. Window > General > Test Runner
2. Should show EditMode and PlayMode tabs
3. No tests yet (expected)

**Step 5: Commit**

```bash
git add .
git commit -m "feat: configure Unity Test Framework"
```

---

## Phase: Core Player Movement

### Task 3: Create Skier Data Model

**Files:**
- Create: `Assets/Scripts/Player/SkierStats.cs`
- Create: `Assets/Tests/EditMode/SkierStatsTests.cs`

**Step 1: Write failing test for speed calculation**

```csharp
// Assets/Tests/EditMode/SkierStatsTests.cs
using NUnit.Framework;

public class SkierStatsTests
{
    [Test]
    public void BaseSpeed_ReturnsConfiguredValue()
    {
        var stats = new SkierStats(baseSpeed: 10f);
        Assert.AreEqual(10f, stats.BaseSpeed);
    }

    [Test]
    public void TuckSpeedMultiplier_IsWithinDesignRange()
    {
        var stats = new SkierStats(baseSpeed: 10f, tuckBonus: 0.12f);
        // Design spec: 10-15% boost
        Assert.GreaterOrEqual(stats.TuckBonus, 0.10f);
        Assert.LessOrEqual(stats.TuckBonus, 0.15f);
    }

    [Test]
    public void GetEffectiveSpeed_WithTuck_AppliesBonus()
    {
        var stats = new SkierStats(baseSpeed: 100f, tuckBonus: 0.12f);
        float tuckedSpeed = stats.GetEffectiveSpeed(isTucking: true, slopeMultiplier: 1f);
        Assert.AreEqual(112f, tuckedSpeed, 0.01f);
    }

    [Test]
    public void GetEffectiveSpeed_WithSteepSlope_IncreasesSpeed()
    {
        var stats = new SkierStats(baseSpeed: 100f, tuckBonus: 0.12f);
        float steepSpeed = stats.GetEffectiveSpeed(isTucking: false, slopeMultiplier: 1.3f);
        Assert.AreEqual(130f, steepSpeed, 0.01f);
    }
}
```

**Step 2: Run test to verify it fails**

Run via Test Runner window.
Expected: Compilation error - `SkierStats` not defined.

**Step 3: Write minimal implementation**

```csharp
// Assets/Scripts/Player/SkierStats.cs
using UnityEngine;

[System.Serializable]
public class SkierStats
{
    [SerializeField] private float baseSpeed;
    [SerializeField] private float tuckBonus;

    public float BaseSpeed => baseSpeed;
    public float TuckBonus => tuckBonus;

    public SkierStats(float baseSpeed, float tuckBonus = 0.12f)
    {
        this.baseSpeed = baseSpeed;
        this.tuckBonus = tuckBonus;
    }

    public float GetEffectiveSpeed(bool isTucking, float slopeMultiplier)
    {
        float speed = baseSpeed * slopeMultiplier;
        if (isTucking)
        {
            speed *= (1f + tuckBonus);
        }
        return speed;
    }
}
```

**Step 4: Run tests to verify they pass**

Expected: All 4 tests PASS.

**Step 5: Commit**

```bash
git add Assets/Scripts/Player/SkierStats.cs Assets/Tests/EditMode/SkierStatsTests.cs
git commit -m "feat: add SkierStats data model with tuck bonus"
```

---

### Task 4: Create Skier Turn Model

**Files:**
- Create: `Assets/Scripts/Player/TurnCalculator.cs`
- Create: `Assets/Tests/EditMode/TurnCalculatorTests.cs`

**Step 1: Write failing tests for hybrid turning**

```csharp
// Assets/Tests/EditMode/TurnCalculatorTests.cs
using NUnit.Framework;

public class TurnCalculatorTests
{
    [Test]
    public void AtLowSpeed_TurningIsDirect()
    {
        var calc = new TurnCalculator(
            lowSpeedThreshold: 40f,
            highSpeedThreshold: 60f,
            maxSpeed: 100f
        );

        // At 20% speed (low), should get near-instant response
        float response = calc.GetTurnResponse(currentSpeed: 20f);
        Assert.GreaterOrEqual(response, 0.9f); // Near 1.0 = direct
    }

    [Test]
    public void AtHighSpeed_TurningIsMomentumBased()
    {
        var calc = new TurnCalculator(
            lowSpeedThreshold: 40f,
            highSpeedThreshold: 60f,
            maxSpeed: 100f
        );

        // At 80% speed (high), should get sluggish response
        float response = calc.GetTurnResponse(currentSpeed: 80f);
        Assert.LessOrEqual(response, 0.5f); // Low = momentum-based
    }

    [Test]
    public void AtMidSpeed_TurningIsBlended()
    {
        var calc = new TurnCalculator(
            lowSpeedThreshold: 40f,
            highSpeedThreshold: 60f,
            maxSpeed: 100f
        );

        // At 50% speed (transition zone), should be blended
        float response = calc.GetTurnResponse(currentSpeed: 50f);
        Assert.Greater(response, 0.5f);
        Assert.Less(response, 0.9f);
    }

    [Test]
    public void WhenTucking_TurnRadiusIsWider()
    {
        var calc = new TurnCalculator(
            lowSpeedThreshold: 40f,
            highSpeedThreshold: 60f,
            maxSpeed: 100f,
            tuckTurnPenalty: 0.6f
        );

        float normalRadius = calc.GetTurnRadius(isTucking: false);
        float tuckRadius = calc.GetTurnRadius(isTucking: true);

        Assert.Greater(tuckRadius, normalRadius);
    }
}
```

**Step 2: Run tests to verify they fail**

Expected: Compilation error - `TurnCalculator` not defined.

**Step 3: Write minimal implementation**

```csharp
// Assets/Scripts/Player/TurnCalculator.cs
using UnityEngine;

public class TurnCalculator
{
    private readonly float lowSpeedThreshold;
    private readonly float highSpeedThreshold;
    private readonly float maxSpeed;
    private readonly float tuckTurnPenalty;
    private readonly float baseTurnRadius;

    public TurnCalculator(
        float lowSpeedThreshold,
        float highSpeedThreshold,
        float maxSpeed,
        float tuckTurnPenalty = 0.6f,
        float baseTurnRadius = 1f)
    {
        this.lowSpeedThreshold = lowSpeedThreshold;
        this.highSpeedThreshold = highSpeedThreshold;
        this.maxSpeed = maxSpeed;
        this.tuckTurnPenalty = tuckTurnPenalty;
        this.baseTurnRadius = baseTurnRadius;
    }

    /// <summary>
    /// Returns turn responsiveness from 0 (sluggish) to 1 (instant).
    /// </summary>
    public float GetTurnResponse(float currentSpeed)
    {
        if (currentSpeed <= lowSpeedThreshold)
        {
            return 1f; // Direct control at low speed
        }
        else if (currentSpeed >= highSpeedThreshold)
        {
            // Momentum-based at high speed (0.3 to 0.5 range)
            float highSpeedFactor = Mathf.InverseLerp(highSpeedThreshold, maxSpeed, currentSpeed);
            return Mathf.Lerp(0.5f, 0.3f, highSpeedFactor);
        }
        else
        {
            // Blend in transition zone
            float t = Mathf.InverseLerp(lowSpeedThreshold, highSpeedThreshold, currentSpeed);
            return Mathf.Lerp(1f, 0.5f, t);
        }
    }

    /// <summary>
    /// Returns turn radius multiplier. Higher = wider turns.
    /// </summary>
    public float GetTurnRadius(bool isTucking)
    {
        if (isTucking)
        {
            return baseTurnRadius / tuckTurnPenalty; // Wider radius when tucking
        }
        return baseTurnRadius;
    }
}
```

**Step 4: Run tests to verify they pass**

Expected: All 4 tests PASS.

**Step 5: Commit**

```bash
git add Assets/Scripts/Player/TurnCalculator.cs Assets/Tests/EditMode/TurnCalculatorTests.cs
git commit -m "feat: add TurnCalculator with hybrid response model"
```

---

### Task 5: Create Skier Controller (MonoBehaviour)

**Files:**
- Create: `Assets/Scripts/Player/SkierController.cs`

**Step 1: Create the skier controller**

```csharp
// Assets/Scripts/Player/SkierController.cs
using UnityEngine;

[RequireComponent(typeof(Rigidbody2D))]
public class SkierController : MonoBehaviour
{
    [Header("Stats")]
    [SerializeField] private float baseSpeed = 100f;
    [SerializeField] private float tuckBonus = 0.12f;
    [SerializeField] private float maxSpeed = 200f;

    [Header("Turning")]
    [SerializeField] private float lowSpeedThreshold = 40f;
    [SerializeField] private float highSpeedThreshold = 60f;
    [SerializeField] private float tuckTurnPenalty = 0.6f;
    [SerializeField] private float turnSpeed = 180f; // Degrees per second

    [Header("Current State")]
    [SerializeField] private bool isTucking;
    [SerializeField] private float currentSpeed;
    [SerializeField] private float currentSlopeMultiplier = 1f;

    private Rigidbody2D rb;
    private SkierStats stats;
    private TurnCalculator turnCalculator;
    private float targetAngle;

    public bool IsTucking => isTucking;
    public float CurrentSpeed => currentSpeed;

    private void Awake()
    {
        rb = GetComponent<Rigidbody2D>();
        rb.gravityScale = 0; // We handle movement manually

        stats = new SkierStats(baseSpeed, tuckBonus);
        turnCalculator = new TurnCalculator(
            lowSpeedThreshold,
            highSpeedThreshold,
            maxSpeed,
            tuckTurnPenalty
        );

        targetAngle = 0f; // Facing down
    }

    private void Update()
    {
        HandleInput();
    }

    private void FixedUpdate()
    {
        UpdateMovement();
    }

    private void HandleInput()
    {
        // Tuck: Hold down arrow or left shift
        isTucking = Input.GetKey(KeyCode.DownArrow) || Input.GetKey(KeyCode.LeftShift);

        // Turn: Left/Right arrows or A/D
        float turnInput = 0f;
        if (Input.GetKey(KeyCode.LeftArrow) || Input.GetKey(KeyCode.A))
        {
            turnInput = 1f; // Turn left (positive rotation in Unity 2D)
        }
        else if (Input.GetKey(KeyCode.RightArrow) || Input.GetKey(KeyCode.D))
        {
            turnInput = -1f; // Turn right (negative rotation)
        }

        // Apply turn with response factor
        float turnResponse = turnCalculator.GetTurnResponse(currentSpeed);
        float radiusMultiplier = turnCalculator.GetTurnRadius(isTucking);
        float effectiveTurnSpeed = turnSpeed * turnResponse / radiusMultiplier;

        targetAngle += turnInput * effectiveTurnSpeed * Time.deltaTime;
        targetAngle = Mathf.Clamp(targetAngle, -80f, 80f); // Limit turning angle
    }

    private void UpdateMovement()
    {
        // Calculate effective speed
        currentSpeed = stats.GetEffectiveSpeed(isTucking, currentSlopeMultiplier);
        currentSpeed = Mathf.Min(currentSpeed, maxSpeed);

        // Convert angle to direction (0 = down, positive = left, negative = right)
        float radians = (targetAngle - 90f) * Mathf.Deg2Rad;
        Vector2 direction = new Vector2(Mathf.Cos(radians), Mathf.Sin(radians));

        // Apply velocity
        rb.linearVelocity = direction * currentSpeed;

        // Rotate sprite to match direction
        transform.rotation = Quaternion.Euler(0, 0, targetAngle);
    }

    /// <summary>
    /// Called by tile system to update slope intensity.
    /// </summary>
    public void SetSlopeMultiplier(float multiplier)
    {
        currentSlopeMultiplier = multiplier;
    }
}
```

**Step 2: Create PrefabCreator Editor script**

Create `Assets/Editor/PrefabCreator.cs`:

```csharp
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

        // Add SkierController if it exists
        var skierControllerType = System.Type.GetType("SkierController, Assembly-CSharp");
        if (skierControllerType != null)
        {
            skierGO.AddComponent(skierControllerType);
        }

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

        // Add Obstacle component if it exists
        var obstacleComponentType = System.Type.GetType("Obstacle, Assembly-CSharp");
        if (obstacleComponentType != null)
        {
            var obstacle = go.AddComponent(obstacleComponentType);
            // Use reflection to set the obstacle type
            var typeField = obstacleComponentType.GetField("obstacleType",
                System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
            if (typeField != null)
            {
                typeField.SetValue(obstacle, obstacleType);
            }
        }

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

        // Add TileInstance component if it exists
        var tileInstanceType = System.Type.GetType("TileInstance, Assembly-CSharp");
        if (tileInstanceType != null)
        {
            tileGO.AddComponent(tileInstanceType);
        }

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

        // Add GateTrigger component if it exists
        var gateTriggerType = System.Type.GetType("GateTrigger, Assembly-CSharp");
        if (gateTriggerType != null)
        {
            var gateTrigger = gateGO.AddComponent(gateTriggerType);
            // Use reflection to set references
            var leftPoleField = gateTriggerType.GetField("leftPole",
                System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
            var rightPoleField = gateTriggerType.GetField("rightPole",
                System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
            var flagField = gateTriggerType.GetField("flag",
                System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);

            leftPoleField?.SetValue(gateTrigger, leftSR);
            rightPoleField?.SetValue(gateTrigger, rightSR);
            flagField?.SetValue(gateTrigger, flagSR);
        }

        string prefabPath = "Assets/Prefabs/Gates/Gate.prefab";
        PrefabUtility.SaveAsPrefabAsset(gateGO, prefabPath);
        DestroyImmediate(gateGO);

        Debug.Log($"Gate prefab created at {prefabPath}");
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
        DestroyImmediate(texture);
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
```

**Step 3: Create Skier prefab via script**

In Unity Editor:
1. Menu > Ski Free Or Die > Create Prefabs > Create Skier Prefab

**Step 4: Test in scene**

1. Drag Skier prefab from `Assets/Prefabs/Player/` to Game scene
2. Hit Play
3. Arrow keys should turn left/right
4. Down arrow should tuck (observe speed change in Inspector)

**Step 5: Verification**

- [ ] Skier prefab exists at `Assets/Prefabs/Player/Skier.prefab`
- [ ] Skier has SkierController, Rigidbody2D, CircleCollider2D components
- [ ] Skier is on "Player" layer
- [ ] Arrow keys control turning
- [ ] Down arrow activates tuck (currentSpeed increases in Inspector)

**Step 6: Commit**

```bash
git add Assets/Scripts/Player/SkierController.cs Assets/Editor/PrefabCreator.cs Assets/Prefabs/Player/ Assets/Sprites/Player/
git commit -m "feat: add SkierController with input and physics"
```

---

### Task 6: Create Camera Follow System

**Files:**
- Create: `Assets/Scripts/Core/CameraFollow.cs`

**Step 1: Create camera follow script**

```csharp
// Assets/Scripts/Core/CameraFollow.cs
using UnityEngine;

public class CameraFollow : MonoBehaviour
{
    [SerializeField] private Transform target;
    [SerializeField] private Vector3 offset = new Vector3(0, 2f, -10f);
    [SerializeField] private float smoothSpeed = 10f;

    private void LateUpdate()
    {
        if (target == null) return;

        Vector3 desiredPosition = target.position + offset;
        Vector3 smoothedPosition = Vector3.Lerp(transform.position, desiredPosition, smoothSpeed * Time.deltaTime);
        transform.position = smoothedPosition;
    }

    public void SetTarget(Transform newTarget)
    {
        target = newTarget;
    }
}
```

**Step 2: Attach to Main Camera**

1. Select Main Camera in scene
2. Add CameraFollow component
3. Drag Skier prefab to Target field
4. Adjust Offset (0, 3, -10) so skier appears in lower portion of screen

**Step 3: Test camera follow**

1. Play the scene
2. Camera should smoothly follow skier
3. Turning should feel natural with camera

**Step 4: Commit**

```bash
git add Assets/Scripts/Core/CameraFollow.cs
git commit -m "feat: add camera follow system"
```

---

## Phase: Obstacles & Collision

### Task 7: Create Obstacle Base Class

**Files:**
- Create: `Assets/Scripts/Obstacles/Obstacle.cs`
- Create: `Assets/Scripts/Obstacles/ObstacleType.cs`

**Step 1: Create obstacle type enum**

```csharp
// Assets/Scripts/Obstacles/ObstacleType.cs
public enum ObstacleType
{
    SmallTree,   // Slight slowdown, no stop
    LargeTree,   // Major speed loss + deflection
    Rock,        // Full crash
    Cabin        // Full crash
}
```

**Step 2: Create obstacle base class**

```csharp
// Assets/Scripts/Obstacles/Obstacle.cs
using UnityEngine;

public class Obstacle : MonoBehaviour
{
    [SerializeField] private ObstacleType obstacleType;

    public ObstacleType Type => obstacleType;

    /// <summary>
    /// Returns speed multiplier on collision (1.0 = no change, 0 = full stop)
    /// </summary>
    public float GetSpeedPenalty()
    {
        return obstacleType switch
        {
            ObstacleType.SmallTree => 0.8f,   // 20% speed loss
            ObstacleType.LargeTree => 0.4f,   // 60% speed loss
            ObstacleType.Rock => 0f,          // Full stop
            ObstacleType.Cabin => 0f,         // Full stop
            _ => 1f
        };
    }

    /// <summary>
    /// Returns true if this obstacle causes a full crash.
    /// </summary>
    public bool CausesCrash()
    {
        return obstacleType == ObstacleType.Rock || obstacleType == ObstacleType.Cabin;
    }

    /// <summary>
    /// Returns deflection angle for non-crash collisions.
    /// </summary>
    public float GetDeflectionAngle()
    {
        return obstacleType switch
        {
            ObstacleType.LargeTree => 30f,
            _ => 0f
        };
    }
}
```

**Step 3: Commit**

```bash
git add Assets/Scripts/Obstacles/
git commit -m "feat: add Obstacle base class with collision properties"
```

---

### Task 8: Create Collision Handler

**Files:**
- Modify: `Assets/Scripts/Player/SkierController.cs`
- Create: `Assets/Scripts/Player/SkierCollisionHandler.cs`

**Step 1: Create collision handler**

```csharp
// Assets/Scripts/Player/SkierCollisionHandler.cs
using UnityEngine;
using System.Collections;

[RequireComponent(typeof(SkierController))]
public class SkierCollisionHandler : MonoBehaviour
{
    [Header("Crash Settings")]
    [SerializeField] private float crashRecoveryTime = 1.75f;

    [Header("State")]
    [SerializeField] private bool isCrashed;
    [SerializeField] private bool isRecovering;

    private SkierController skierController;

    public bool IsCrashed => isCrashed;
    public bool IsRecovering => isRecovering;

    public event System.Action OnCrash;
    public event System.Action OnRecover;

    private void Awake()
    {
        skierController = GetComponent<SkierController>();
    }

    private void OnCollisionEnter2D(Collision2D collision)
    {
        if (isRecovering) return;

        var obstacle = collision.gameObject.GetComponent<Obstacle>();
        if (obstacle == null) return;

        HandleObstacleCollision(obstacle, collision);
    }

    private void HandleObstacleCollision(Obstacle obstacle, Collision2D collision)
    {
        if (obstacle.CausesCrash())
        {
            StartCoroutine(CrashSequence());
        }
        else
        {
            // Apply speed penalty and deflection
            float penalty = obstacle.GetSpeedPenalty();
            float deflection = obstacle.GetDeflectionAngle();

            // Determine deflection direction based on collision normal
            Vector2 normal = collision.contacts[0].normal;
            float deflectionDirection = normal.x > 0 ? 1f : -1f;

            skierController.ApplySpeedPenalty(penalty);
            skierController.ApplyDeflection(deflection * deflectionDirection);
        }
    }

    private IEnumerator CrashSequence()
    {
        isCrashed = true;
        isRecovering = true;
        OnCrash?.Invoke();

        // Stop the skier
        skierController.SetCrashed(true);

        yield return new WaitForSeconds(crashRecoveryTime);

        // Recover
        skierController.SetCrashed(false);
        isCrashed = false;
        isRecovering = false;
        OnRecover?.Invoke();
    }
}
```

**Step 2: Replace SkierController.cs with crash support**

Replace the entire contents of `Assets/Scripts/Player/SkierController.cs`:

```csharp
// Assets/Scripts/Player/SkierController.cs
using UnityEngine;

[RequireComponent(typeof(Rigidbody2D))]
public class SkierController : MonoBehaviour
{
    [Header("Stats")]
    [SerializeField] private float baseSpeed = 100f;
    [SerializeField] private float tuckBonus = 0.12f;
    [SerializeField] private float maxSpeed = 200f;

    [Header("Turning")]
    [SerializeField] private float lowSpeedThreshold = 40f;
    [SerializeField] private float highSpeedThreshold = 60f;
    [SerializeField] private float tuckTurnPenalty = 0.6f;
    [SerializeField] private float turnSpeed = 180f; // Degrees per second

    [Header("Current State")]
    [SerializeField] private bool isTucking;
    [SerializeField] private float currentSpeed;
    [SerializeField] private float currentSlopeMultiplier = 1f;
    [SerializeField] private bool isCrashed;

    private Rigidbody2D rb;
    private SkierStats stats;
    private TurnCalculator turnCalculator;
    private float targetAngle;

    public bool IsTucking => isTucking;
    public float CurrentSpeed => currentSpeed;
    public bool IsCrashed => isCrashed;

    private void Awake()
    {
        rb = GetComponent<Rigidbody2D>();
        rb.gravityScale = 0; // We handle movement manually

        stats = new SkierStats(baseSpeed, tuckBonus);
        turnCalculator = new TurnCalculator(
            lowSpeedThreshold,
            highSpeedThreshold,
            maxSpeed,
            tuckTurnPenalty
        );

        targetAngle = 0f; // Facing down
    }

    private void Update()
    {
        HandleInput();
    }

    private void FixedUpdate()
    {
        UpdateMovement();
    }

    private void HandleInput()
    {
        if (isCrashed) return;

        // Tuck: Hold down arrow or left shift
        isTucking = Input.GetKey(KeyCode.DownArrow) || Input.GetKey(KeyCode.LeftShift);

        // Turn: Left/Right arrows or A/D
        float turnInput = 0f;
        if (Input.GetKey(KeyCode.LeftArrow) || Input.GetKey(KeyCode.A))
        {
            turnInput = 1f; // Turn left (positive rotation in Unity 2D)
        }
        else if (Input.GetKey(KeyCode.RightArrow) || Input.GetKey(KeyCode.D))
        {
            turnInput = -1f; // Turn right (negative rotation)
        }

        // Apply turn with response factor
        float turnResponse = turnCalculator.GetTurnResponse(currentSpeed);
        float radiusMultiplier = turnCalculator.GetTurnRadius(isTucking);
        float effectiveTurnSpeed = turnSpeed * turnResponse / radiusMultiplier;

        targetAngle += turnInput * effectiveTurnSpeed * Time.deltaTime;
        targetAngle = Mathf.Clamp(targetAngle, -80f, 80f); // Limit turning angle
    }

    private void UpdateMovement()
    {
        if (isCrashed) return;

        // Calculate effective speed
        currentSpeed = stats.GetEffectiveSpeed(isTucking, currentSlopeMultiplier);
        currentSpeed = Mathf.Min(currentSpeed, maxSpeed);

        // Convert angle to direction (0 = down, positive = left, negative = right)
        float radians = (targetAngle - 90f) * Mathf.Deg2Rad;
        Vector2 direction = new Vector2(Mathf.Cos(radians), Mathf.Sin(radians));

        // Apply velocity
        rb.linearVelocity = direction * currentSpeed;

        // Rotate sprite to match direction
        transform.rotation = Quaternion.Euler(0, 0, targetAngle);
    }

    /// <summary>
    /// Called by tile system to update slope intensity.
    /// </summary>
    public void SetSlopeMultiplier(float multiplier)
    {
        currentSlopeMultiplier = multiplier;
    }

    /// <summary>
    /// Called by collision handler to set crash state.
    /// </summary>
    public void SetCrashed(bool crashed)
    {
        isCrashed = crashed;
        if (crashed)
        {
            rb.linearVelocity = Vector2.zero;
            currentSpeed = 0f;
        }
    }

    /// <summary>
    /// Called by collision handler for non-crash collisions.
    /// </summary>
    public void ApplySpeedPenalty(float multiplier)
    {
        currentSpeed *= multiplier;
    }

    /// <summary>
    /// Called by collision handler for deflection on tree hits.
    /// </summary>
    public void ApplyDeflection(float angle)
    {
        targetAngle += angle;
        targetAngle = Mathf.Clamp(targetAngle, -80f, 80f);
    }
}
```

**Step 3: Update Skier prefab with collision handler**

In Unity Editor:
1. Menu > Ski Free Or Die > Create Prefabs > Create Skier Prefab (regenerates with updated script)
2. Select the Skier prefab in Project window
3. In Inspector, click "Open Prefab"
4. Add SkierCollisionHandler component
5. Save and close prefab

**Step 4: Create obstacle prefabs via script**

In Unity Editor:
1. Menu > Ski Free Or Die > Create Prefabs > Create Obstacle Prefabs

This creates:
- `Assets/Prefabs/Obstacles/SmallTree.prefab`
- `Assets/Prefabs/Obstacles/LargeTree.prefab`
- `Assets/Prefabs/Obstacles/Rock.prefab`
- `Assets/Prefabs/Obstacles/Cabin.prefab`

**Step 5: Test collision in scene**

1. Drag obstacle prefabs into scene at various Y positions below the skier
2. Play and ski into them
3. Small trees = 20% slowdown (continue skiing)
4. Large trees = 60% slowdown + deflection
5. Rocks/Cabins = full crash (1.75 second recovery)

**Step 6: Verification**

- [ ] All 4 obstacle prefabs exist in `Assets/Prefabs/Obstacles/`
- [ ] Each obstacle has Obstacle component with correct type set
- [ ] Each obstacle has appropriate collider
- [ ] Small tree collision slows but doesn't stop skier
- [ ] Rock collision causes full crash and recovery animation
- [ ] Console shows "Crash!" and recovery messages

**Step 7: Commit**

```bash
git add Assets/Scripts/Player/SkierCollisionHandler.cs Assets/Scripts/Player/SkierController.cs Assets/Prefabs/Obstacles/ Assets/Sprites/Obstacles/
git commit -m "feat: add collision handling with obstacle types"
```

---

## Phase: Procedural Generation

### Task 9: Create Tile Data Structure

**Files:**
- Create: `Assets/Scripts/World/TileData.cs`
- Create: `Assets/Scripts/World/TileType.cs`
- Create: `Assets/Tests/EditMode/TileDataTests.cs`

**Step 1: Write failing tests**

```csharp
// Assets/Tests/EditMode/TileDataTests.cs
using NUnit.Framework;
using System.Collections.Generic;

public class TileDataTests
{
    [Test]
    public void TileData_StoresObstaclePositions()
    {
        var obstacles = new List<ObstacleSpawn>
        {
            new ObstacleSpawn(ObstacleType.SmallTree, 0.2f, 0.5f),
            new ObstacleSpawn(ObstacleType.Rock, 0.8f, 0.3f)
        };

        var tile = new TileData(TileType.ObstacleField, SlopeIntensity.Moderate, obstacles);

        Assert.AreEqual(2, tile.Obstacles.Count);
        Assert.AreEqual(ObstacleType.SmallTree, tile.Obstacles[0].Type);
    }

    [Test]
    public void TileData_HasSlopeIntensity()
    {
        var tile = new TileData(TileType.Speed, SlopeIntensity.Steep, new List<ObstacleSpawn>());

        Assert.AreEqual(SlopeIntensity.Steep, tile.Slope);
        Assert.AreEqual(1.3f, tile.GetSlopeMultiplier(), 0.01f);
    }
}
```

**Step 2: Run tests to verify they fail**

Expected: Compilation errors.

**Step 3: Implement tile data structures**

```csharp
// Assets/Scripts/World/TileType.cs
public enum TileType
{
    Warmup,
    Slalom,
    ObstacleField,
    Speed,
    Ramp
}

public enum SlopeIntensity
{
    Gentle,
    Moderate,
    Steep
}
```

```csharp
// Assets/Scripts/World/TileData.cs
using System.Collections.Generic;

[System.Serializable]
public class ObstacleSpawn
{
    public ObstacleType Type;
    public float NormalizedX; // 0-1 across tile width
    public float NormalizedY; // 0-1 along tile height

    public ObstacleSpawn(ObstacleType type, float x, float y)
    {
        Type = type;
        NormalizedX = x;
        NormalizedY = y;
    }
}

[System.Serializable]
public class TileData
{
    public TileType Type;
    public SlopeIntensity Slope;
    public List<ObstacleSpawn> Obstacles;

    public TileData(TileType type, SlopeIntensity slope, List<ObstacleSpawn> obstacles)
    {
        Type = type;
        Slope = slope;
        Obstacles = obstacles ?? new List<ObstacleSpawn>();
    }

    public float GetSlopeMultiplier()
    {
        return Slope switch
        {
            SlopeIntensity.Gentle => 0.8f,
            SlopeIntensity.Moderate => 1.0f,
            SlopeIntensity.Steep => 1.3f,
            _ => 1.0f
        };
    }
}
```

**Step 4: Run tests to verify they pass**

Expected: All tests PASS.

**Step 5: Commit**

```bash
git add Assets/Scripts/World/ Assets/Tests/EditMode/TileDataTests.cs
git commit -m "feat: add TileData structure with slope intensity"
```

---

### Task 10: Create Seeded Random Generator

**Files:**
- Create: `Assets/Scripts/World/SeededRandom.cs`
- Create: `Assets/Tests/EditMode/SeededRandomTests.cs`

**Step 1: Write failing tests for determinism**

```csharp
// Assets/Tests/EditMode/SeededRandomTests.cs
using NUnit.Framework;

public class SeededRandomTests
{
    [Test]
    public void SameSeed_ProducesSameSequence()
    {
        var rng1 = new SeededRandom(12345);
        var rng2 = new SeededRandom(12345);

        for (int i = 0; i < 100; i++)
        {
            Assert.AreEqual(rng1.NextFloat(), rng2.NextFloat());
        }
    }

    [Test]
    public void DifferentSeeds_ProduceDifferentSequences()
    {
        var rng1 = new SeededRandom(12345);
        var rng2 = new SeededRandom(54321);

        // Very unlikely to match
        Assert.AreNotEqual(rng1.NextFloat(), rng2.NextFloat());
    }

    [Test]
    public void Range_ReturnsValuesInBounds()
    {
        var rng = new SeededRandom(42);

        for (int i = 0; i < 1000; i++)
        {
            float value = rng.Range(10f, 20f);
            Assert.GreaterOrEqual(value, 10f);
            Assert.LessOrEqual(value, 20f);
        }
    }
}
```

**Step 2: Run tests to verify they fail**

Expected: Compilation error.

**Step 3: Implement seeded random**

```csharp
// Assets/Scripts/World/SeededRandom.cs
using System;

public class SeededRandom
{
    private Random random;

    public SeededRandom(int seed)
    {
        random = new Random(seed);
    }

    public float NextFloat()
    {
        return (float)random.NextDouble();
    }

    public int NextInt(int maxExclusive)
    {
        return random.Next(maxExclusive);
    }

    public int NextInt(int minInclusive, int maxExclusive)
    {
        return random.Next(minInclusive, maxExclusive);
    }

    public float Range(float min, float max)
    {
        return min + NextFloat() * (max - min);
    }

    public T Choose<T>(T[] options)
    {
        return options[NextInt(options.Length)];
    }
}
```

**Step 4: Run tests to verify they pass**

Expected: All tests PASS.

**Step 5: Commit**

```bash
git add Assets/Scripts/World/SeededRandom.cs Assets/Tests/EditMode/SeededRandomTests.cs
git commit -m "feat: add SeededRandom for deterministic generation"
```

---

### Task 11: Create Tile Generator

**Files:**
- Create: `Assets/Scripts/World/TileGenerator.cs`
- Create: `Assets/Tests/EditMode/TileGeneratorTests.cs`

**Step 1: Write failing tests**

```csharp
// Assets/Tests/EditMode/TileGeneratorTests.cs
using NUnit.Framework;

public class TileGeneratorTests
{
    [Test]
    public void SameSeed_GeneratesSameTiles()
    {
        var gen1 = new TileGenerator(12345);
        var gen2 = new TileGenerator(12345);

        var tiles1 = gen1.GenerateCourse(10);
        var tiles2 = gen2.GenerateCourse(10);

        Assert.AreEqual(tiles1.Count, tiles2.Count);
        for (int i = 0; i < tiles1.Count; i++)
        {
            Assert.AreEqual(tiles1[i].Type, tiles2[i].Type);
            Assert.AreEqual(tiles1[i].Slope, tiles2[i].Slope);
        }
    }

    [Test]
    public void FirstTile_IsAlwaysWarmup()
    {
        var gen = new TileGenerator(99999);
        var tiles = gen.GenerateCourse(10);

        Assert.AreEqual(TileType.Warmup, tiles[0].Type);
        Assert.AreEqual(SlopeIntensity.Gentle, tiles[0].Slope);
    }

    [Test]
    public void DifficultyIncreases_OverCourse()
    {
        var gen = new TileGenerator(12345);
        var tiles = gen.GenerateCourse(20);

        // Count steep slopes in first half vs second half
        int steepFirstHalf = 0;
        int steepSecondHalf = 0;

        for (int i = 0; i < 10; i++)
        {
            if (tiles[i].Slope == SlopeIntensity.Steep) steepFirstHalf++;
        }
        for (int i = 10; i < 20; i++)
        {
            if (tiles[i].Slope == SlopeIntensity.Steep) steepSecondHalf++;
        }

        Assert.GreaterOrEqual(steepSecondHalf, steepFirstHalf);
    }
}
```

**Step 2: Run tests to verify they fail**

Expected: Compilation error.

**Step 3: Implement tile generator**

```csharp
// Assets/Scripts/World/TileGenerator.cs
using System.Collections.Generic;

public class TileGenerator
{
    private readonly SeededRandom rng;

    public TileGenerator(int seed)
    {
        rng = new SeededRandom(seed);
    }

    public List<TileData> GenerateCourse(int tileCount)
    {
        var tiles = new List<TileData>();
        TileType previousType = TileType.Warmup;
        int hardTilesInRow = 0;

        for (int i = 0; i < tileCount; i++)
        {
            float progress = (float)i / tileCount;
            var tile = GenerateTile(progress, previousType, ref hardTilesInRow);
            tiles.Add(tile);
            previousType = tile.Type;
        }

        return tiles;
    }

    private TileData GenerateTile(float progress, TileType previousType, ref int hardTilesInRow)
    {
        // First tile is always warmup
        if (progress < 0.05f)
        {
            hardTilesInRow = 0;
            return new TileData(TileType.Warmup, SlopeIntensity.Gentle, GenerateObstacles(TileType.Warmup, 0));
        }

        // Determine difficulty based on progress
        int difficulty = GetDifficultyRating(progress);

        // Pacing rule: after hard tile, add a speed tile
        if (hardTilesInRow >= 2)
        {
            hardTilesInRow = 0;
            return new TileData(TileType.Speed, SlopeIntensity.Steep, GenerateObstacles(TileType.Speed, difficulty));
        }

        // Choose tile type based on difficulty
        TileType type = ChooseTileType(difficulty);
        SlopeIntensity slope = ChooseSlopeIntensity(difficulty);

        if (difficulty >= 4)
        {
            hardTilesInRow++;
        }
        else
        {
            hardTilesInRow = 0;
        }

        var obstacles = GenerateObstacles(type, difficulty);
        return new TileData(type, slope, obstacles);
    }

    private int GetDifficultyRating(float progress)
    {
        // 1-5 scale based on progress
        if (progress < 0.25f) return rng.NextInt(1, 3);
        if (progress < 0.50f) return rng.NextInt(2, 4);
        if (progress < 0.75f) return rng.NextInt(3, 5);
        return rng.NextInt(4, 6);
    }

    private TileType ChooseTileType(int difficulty)
    {
        TileType[] options = difficulty switch
        {
            1 or 2 => new[] { TileType.Warmup, TileType.Speed, TileType.ObstacleField },
            3 or 4 => new[] { TileType.ObstacleField, TileType.Slalom, TileType.Speed },
            _ => new[] { TileType.ObstacleField, TileType.Slalom, TileType.Ramp }
        };
        return rng.Choose(options);
    }

    private SlopeIntensity ChooseSlopeIntensity(int difficulty)
    {
        return difficulty switch
        {
            1 or 2 => SlopeIntensity.Gentle,
            3 => rng.NextFloat() > 0.5f ? SlopeIntensity.Moderate : SlopeIntensity.Gentle,
            4 => rng.NextFloat() > 0.5f ? SlopeIntensity.Steep : SlopeIntensity.Moderate,
            _ => SlopeIntensity.Steep
        };
    }

    private List<ObstacleSpawn> GenerateObstacles(TileType type, int difficulty)
    {
        var obstacles = new List<ObstacleSpawn>();

        int obstacleCount = type switch
        {
            TileType.Warmup => rng.NextInt(0, 2),
            TileType.Speed => rng.NextInt(0, 2),
            TileType.ObstacleField => rng.NextInt(3, 6) + difficulty,
            TileType.Slalom => rng.NextInt(1, 3),
            TileType.Ramp => rng.NextInt(1, 3),
            _ => 0
        };

        for (int i = 0; i < obstacleCount; i++)
        {
            ObstacleType obstacleType = ChooseObstacleType(difficulty);
            float x = rng.Range(0.1f, 0.9f);
            float y = rng.Range(0.1f, 0.9f);
            obstacles.Add(new ObstacleSpawn(obstacleType, x, y));
        }

        return obstacles;
    }

    private ObstacleType ChooseObstacleType(int difficulty)
    {
        float roll = rng.NextFloat();

        if (difficulty <= 2)
        {
            // Easy: mostly small trees
            return roll < 0.8f ? ObstacleType.SmallTree : ObstacleType.LargeTree;
        }
        else if (difficulty <= 4)
        {
            // Medium: mix
            if (roll < 0.4f) return ObstacleType.SmallTree;
            if (roll < 0.7f) return ObstacleType.LargeTree;
            return ObstacleType.Rock;
        }
        else
        {
            // Hard: more dangerous
            if (roll < 0.2f) return ObstacleType.SmallTree;
            if (roll < 0.5f) return ObstacleType.LargeTree;
            if (roll < 0.8f) return ObstacleType.Rock;
            return ObstacleType.Cabin;
        }
    }
}
```

**Step 4: Run tests to verify they pass**

Expected: All tests PASS.

**Step 5: Commit**

```bash
git add Assets/Scripts/World/TileGenerator.cs Assets/Tests/EditMode/TileGeneratorTests.cs
git commit -m "feat: add TileGenerator with difficulty progression"
```

---

### Task 12: Create World Manager (Runtime Spawning)

**Files:**
- Create: `Assets/Scripts/World/WorldManager.cs`
- Create: `Assets/Scripts/World/TileInstance.cs`

**Step 1: Create TileInstance component**

```csharp
// Assets/Scripts/World/TileInstance.cs
using UnityEngine;
using System.Collections.Generic;

public class TileInstance : MonoBehaviour
{
    [SerializeField] private TileData data;
    [SerializeField] private float tileHeight = 20f;
    [SerializeField] private float tileWidth = 15f;

    private List<GameObject> spawnedObstacles = new List<GameObject>();

    public float TileHeight => tileHeight;
    public float TopEdge => transform.position.y + tileHeight / 2f;
    public float BottomEdge => transform.position.y - tileHeight / 2f;
    public TileData Data => data;

    public void Initialize(TileData tileData, Dictionary<ObstacleType, GameObject> obstaclePrefabs)
    {
        data = tileData;
        SpawnObstacles(obstaclePrefabs);
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
    }
}
```

**Step 2: Create WorldManager**

```csharp
// Assets/Scripts/World/WorldManager.cs
using UnityEngine;
using System.Collections.Generic;

public class WorldManager : MonoBehaviour
{
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

    [Header("References")]
    [SerializeField] private Transform player;

    private TileGenerator generator;
    private List<TileData> courseData;
    private Dictionary<int, TileInstance> activeTiles = new Dictionary<int, TileInstance>();
    private Dictionary<ObstacleType, GameObject> obstaclePrefabs;
    private int currentTileIndex = 0;

    public int TotalTiles => totalTiles;
    public int CurrentTileIndex => currentTileIndex;

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
        courseData = generator.GenerateCourse(totalTiles);
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
        currentTileIndex = Mathf.Clamp(currentTileIndex, 0, totalTiles - 1);
    }

    private void ManageActiveTiles()
    {
        int minTile = Mathf.Max(0, currentTileIndex - tilesBehind);
        int maxTile = Mathf.Min(totalTiles - 1, currentTileIndex + tilesAhead);

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

    private void SpawnTile(int index)
    {
        if (index < 0 || index >= courseData.Count) return;
        if (activeTiles.ContainsKey(index)) return;

        Vector3 position = new Vector3(0, -index * tileHeight, 0);
        var tileGO = Instantiate(tilePrefab, position, Quaternion.identity, transform);
        var tileInstance = tileGO.GetComponent<TileInstance>();

        if (tileInstance == null)
        {
            tileInstance = tileGO.AddComponent<TileInstance>();
        }

        tileInstance.Initialize(courseData[index], obstaclePrefabs);
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
}
```

**Step 3: Create Tile prefab via script**

In Unity Editor:
1. Menu > Ski Free Or Die > Create Prefabs > Create Tile Prefab

This creates `Assets/Prefabs/Tiles/Tile.prefab` with TileInstance component.

**Step 4: Set up WorldManager in scene**

1. Create empty GameObject named "WorldManager" in the Game scene
2. Add WorldManager component
3. Assign references in Inspector:
   - Player: drag Skier from scene
   - Tile Prefab: drag `Assets/Prefabs/Tiles/Tile.prefab`
   - Small Tree Prefab: drag `Assets/Prefabs/Obstacles/SmallTree.prefab`
   - Large Tree Prefab: drag `Assets/Prefabs/Obstacles/LargeTree.prefab`
   - Rock Prefab: drag `Assets/Prefabs/Obstacles/Rock.prefab`
   - Cabin Prefab: drag `Assets/Prefabs/Obstacles/Cabin.prefab`
4. Set seed to any number (e.g., 12345)

**Step 5: Test procedural generation**

1. Play the scene
2. Tiles should spawn ahead of player
3. Obstacles should appear based on seed
4. Old tiles should despawn behind player
5. Same seed = same obstacle positions every time

**Step 6: Verification**

- [ ] Tile prefab exists at `Assets/Prefabs/Tiles/Tile.prefab`
- [ ] WorldManager has all prefab references assigned
- [ ] Tiles spawn as player moves down
- [ ] Obstacles appear on tiles
- [ ] Tiles behind player are destroyed (check Hierarchy)
- [ ] Running with same seed twice produces identical layout

**Step 7: Commit**

```bash
git add Assets/Scripts/World/WorldManager.cs Assets/Scripts/World/TileInstance.cs Assets/Prefabs/Tiles/
git commit -m "feat: add WorldManager with runtime tile spawning"
```

---

## Phase: Game Loop

### Task 13: Create Game Timer and Finish Line

**Files:**
- Create: `Assets/Scripts/Core/GameManager.cs`
- Create: `Assets/Scripts/Core/FinishLine.cs`

**Step 1: Create FinishLine trigger**

```csharp
// Assets/Scripts/Core/FinishLine.cs
using UnityEngine;

public class FinishLine : MonoBehaviour
{
    public event System.Action OnPlayerFinished;

    private void OnTriggerEnter2D(Collider2D other)
    {
        if (other.GetComponent<SkierController>() != null)
        {
            OnPlayerFinished?.Invoke();
        }
    }
}
```

**Step 2: Create GameManager**

```csharp
// Assets/Scripts/Core/GameManager.cs
using UnityEngine;

public class GameManager : MonoBehaviour
{
    [Header("References")]
    [SerializeField] private WorldManager worldManager;
    [SerializeField] private SkierController player;
    [SerializeField] private FinishLine finishLine;

    [Header("State")]
    [SerializeField] private float elapsedTime;
    [SerializeField] private bool isRunning;
    [SerializeField] private bool isFinished;

    public float ElapsedTime => elapsedTime;
    public bool IsRunning => isRunning;
    public bool IsFinished => isFinished;

    public event System.Action OnGameStart;
    public event System.Action<float> OnGameFinish;

    private void Start()
    {
        SetupFinishLine();
        StartGame();
    }

    private void Update()
    {
        if (isRunning && !isFinished)
        {
            elapsedTime += Time.deltaTime;
        }
    }

    private void SetupFinishLine()
    {
        if (finishLine == null)
        {
            // Create finish line at end of course
            float finishY = -(worldManager.TotalTiles - 1) * 20f - 10f; // Last tile position
            var finishGO = new GameObject("FinishLine");
            finishGO.transform.position = new Vector3(0, finishY, 0);

            var collider = finishGO.AddComponent<BoxCollider2D>();
            collider.size = new Vector2(20f, 2f);
            collider.isTrigger = true;

            finishLine = finishGO.AddComponent<FinishLine>();
        }

        finishLine.OnPlayerFinished += HandleFinish;
    }

    private void StartGame()
    {
        elapsedTime = 0f;
        isRunning = true;
        isFinished = false;
        OnGameStart?.Invoke();
    }

    private void HandleFinish()
    {
        if (isFinished) return;

        isFinished = true;
        isRunning = false;
        OnGameFinish?.Invoke(elapsedTime);

        Debug.Log($"Finished! Time: {elapsedTime:F2} seconds");
    }

    public void RestartGame()
    {
        // Reload scene for now
        UnityEngine.SceneManagement.SceneManager.LoadScene(
            UnityEngine.SceneManagement.SceneManager.GetActiveScene().name
        );
    }
}
```

**Step 3: Set up GameManager in scene**

1. Create empty GameObject named "GameManager"
2. Add GameManager component
3. Assign references

**Step 4: Test game loop**

1. Play the scene
2. Ski to the bottom
3. Console should log finish time

**Step 5: Commit**

```bash
git add Assets/Scripts/Core/GameManager.cs Assets/Scripts/Core/FinishLine.cs
git commit -m "feat: add GameManager with timer and finish line"
```

---

### Task 14: Create Basic HUD

**Files:**
- Create: `Assets/Scripts/UI/GameHUD.cs`

**Step 1: Create HUD script**

```csharp
// Assets/Scripts/UI/GameHUD.cs
using UnityEngine;
using UnityEngine.UI;

public class GameHUD : MonoBehaviour
{
    [Header("References")]
    [SerializeField] private GameManager gameManager;
    [SerializeField] private SkierController skier;

    [Header("UI Elements")]
    [SerializeField] private Text timerText;
    [SerializeField] private Text speedText;
    [SerializeField] private Text finishText;
    [SerializeField] private GameObject finishPanel;

    private void Start()
    {
        if (finishPanel != null)
        {
            finishPanel.SetActive(false);
        }

        if (gameManager != null)
        {
            gameManager.OnGameFinish += ShowFinishScreen;
        }
    }

    private void Update()
    {
        UpdateTimer();
        UpdateSpeed();
    }

    private void UpdateTimer()
    {
        if (timerText == null || gameManager == null) return;

        float time = gameManager.ElapsedTime;
        int minutes = Mathf.FloorToInt(time / 60f);
        int seconds = Mathf.FloorToInt(time % 60f);
        int milliseconds = Mathf.FloorToInt((time * 100f) % 100f);

        timerText.text = $"{minutes:00}:{seconds:00}.{milliseconds:00}";
    }

    private void UpdateSpeed()
    {
        if (speedText == null || skier == null) return;

        speedText.text = $"{skier.CurrentSpeed:F0} km/h";
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
            finishText.text = $"FINISH!\n{minutes:00}:{seconds:00}.{milliseconds:00}";
        }
    }
}
```

**Step 2: Create UI Canvas**

1. Create UI > Canvas
2. Set Canvas Scaler to "Scale With Screen Size"
3. Add GameHUD component
4. Create Text elements for timer and speed
5. Create finish panel (hidden by default)

**Step 3: Style with placeholder 80s fonts**

- Use bold, blocky font
- Hot pink or electric blue colors
- Position timer at top center

**Step 4: Test HUD**

1. Play the scene
2. Timer should count up
3. Speed should update
4. Finish panel should appear at end

**Step 5: Commit**

```bash
git add Assets/Scripts/UI/GameHUD.cs
git commit -m "feat: add basic game HUD with timer"
```

---

### Task 15: Create Seed Configuration

**Files:**
- Create: `Assets/Config/seeds.json`
- Create: `Assets/Scripts/Core/SeedLoader.cs`

**Step 1: Create seeds config file**

```json
// Assets/Config/seeds.json
{
    "weeklySeed": 20251223,
    "testSeeds": [
        12345,
        54321,
        99999
    ]
}
```

**Step 2: Create seed loader**

```csharp
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
```

**Step 3: Integrate with WorldManager**

Update WorldManager to use SeedLoader:

```csharp
// Add to WorldManager.cs
[SerializeField] private SeedLoader seedLoader;

private void Start()
{
    if (seedLoader != null)
    {
        seed = seedLoader.WeeklySeed;
    }
    GenerateCourse();
    SpawnInitialTiles();
}
```

**Step 4: Set up in scene**

1. Add SeedLoader to GameManager object
2. Assign seeds.json as TextAsset
3. Reference SeedLoader in WorldManager

**Step 5: Test seed loading**

1. Change weeklySeed in JSON
2. Play scene
3. Course should change based on seed

**Step 6: Commit**

```bash
git add Assets/Config/seeds.json Assets/Scripts/Core/SeedLoader.cs Assets/Scripts/World/WorldManager.cs
git commit -m "feat: add local seed configuration system"
```

---

## Summary

**Core Game Complete:**
- Skier with physics-based movement
- Tuck mechanic with speed/control tradeoff
- Hybrid turning (direct at low speed, momentum at high)
- Obstacle collision with severity hierarchy
- Procedural tile generation from seed
- Timer and finish line
- Basic HUD

**Ready for Layer 1:**
- Gates and slalom scoring
- All 7 tile types
- Ramps and tricks

**Files Created:**
```
Assets/
├── Scripts/
│   ├── Player/
│   │   ├── SkierStats.cs
│   │   ├── SkierController.cs
│   │   ├── TurnCalculator.cs
│   │   └── SkierCollisionHandler.cs
│   ├── World/
│   │   ├── TileType.cs
│   │   ├── TileData.cs
│   │   ├── TileGenerator.cs
│   │   ├── TileInstance.cs
│   │   ├── WorldManager.cs
│   │   └── SeededRandom.cs
│   ├── Obstacles/
│   │   ├── ObstacleType.cs
│   │   └── Obstacle.cs
│   ├── Core/
│   │   ├── CameraFollow.cs
│   │   ├── GameManager.cs
│   │   ├── FinishLine.cs
│   │   └── SeedLoader.cs
│   └── UI/
│       └── GameHUD.cs
├── Tests/
│   └── EditMode/
│       ├── SkierStatsTests.cs
│       ├── TurnCalculatorTests.cs
│       ├── TileDataTests.cs
│       ├── TileGeneratorTests.cs
│       └── SeededRandomTests.cs
├── Config/
│   └── seeds.json
└── Prefabs/
    ├── Player/Skier.prefab
    ├── Obstacles/[SmallTree, LargeTree, Rock, Cabin].prefab
    └── Tiles/Tile.prefab
```
