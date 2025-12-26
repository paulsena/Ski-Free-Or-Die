# Endless Mode & Yeti Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement the "Endless Descent" mode where the map generates infinitely and a "Yeti" entity chases the player with increasing speed.

**Architecture:** 
- `GameMode` enum to switch between Time Trial and Endless.
- `WorldManager` adapted to spawn tiles indefinitely in Endless mode.
- `YetiController` calculates virtual position behind player and handles "catch" logic.
- `YetiEffectManager` handles visual/audio tension (screen tint, vignette).

**Prerequisites:** Complete Tasks 1-15 from `core-game-implementation.md`.

**Reference:** `yeti-mechanic-design.md` for specific speed scaling and zone definitions.

---

## Phase: Endless World Generation

### Task 16: Implement Game Mode Architecture

**Files:**
- Create: `Assets/Scripts/Core/GameMode.cs`
- Modify: `Assets/Scripts/Core/GameManager.cs`

**Step 1: Create GameMode enum**

```csharp
// Assets/Scripts/Core/GameMode.cs
public enum GameMode
{
    TimeTrial,  // Fixed length, race against clock
    Endless     // Infinite length, survive the Yeti
}
```

**Step 2: Update GameManager to support modes**

Modify `Assets/Scripts/Core/GameManager.cs`:

```csharp
// Add fields
[Header("Game Mode")]
[SerializeField] private GameMode currentMode = GameMode.TimeTrial;

public GameMode CurrentMode => currentMode;

// Modify SetupFinishLine to be conditional
private void SetupFinishLine()
{
    if (currentMode == GameMode.Endless) return; // No finish line in endless

    // ... existing finish line code ...
}

// Add method to handle endless game over
public void TriggerGameOver(string reason)
{
    if (isFinished) return;

    isFinished = true;
    isRunning = false;
    
    Debug.Log($"Game Over: {reason} - Time: {elapsedTime:F2}s");
    OnGameFinish?.Invoke(elapsedTime);
}
```

**Step 3: Commit**

```bash
git add Assets/Scripts/Core/GameMode.cs Assets/Scripts/Core/GameManager.cs
git commit -m "feat: add GameMode enum and support for endless state"
```

---

### Task 17: Infinite Tile Spawning

**Files:**
- Modify: `Assets/Scripts/World/WorldManager.cs`
- Modify: `Assets/Scripts/World/TileGenerator.cs`

**Step 1: Update WorldManager for infinite scrolling**

Modify `Assets/Scripts/World/WorldManager.cs`:

```csharp
// Modify ManageActiveTiles
private void ManageActiveTiles()
{
    // ... existing bounds calculation ...
    
    // In Endless mode, extend maxTile as player moves
    if (GameManager.Instance.CurrentMode == GameMode.Endless)
    {
        // Ensure we always have tiles ahead
        // We don't cap at totalTiles
        maxTile = currentTileIndex + tilesAhead;
    }
    else 
    {
        maxTile = Mathf.Min(totalTiles - 1, currentTileIndex + tilesAhead);
    }

    // Spawn new tiles
    for (int i = minTile; i <= maxTile; i++)
    {
        if (!activeTiles.ContainsKey(i))
        {
            SpawnTile(i);
        }
    }
    
    // ... existing cleanup code ...
}

// Modify SpawnTile to generate data on the fly if needed
private void SpawnTile(int index)
{
    if (activeTiles.ContainsKey(index)) return;

    // Check if we need to generate more data (Endless mode)
    if (index >= courseData.Count)
    {
        if (GameManager.Instance.CurrentMode == GameMode.Endless)
        {
            ExtendCourse(index + 10); // Generate a buffer
        }
        else
        {
            return; // Out of bounds for Time Trial
        }
    }

    // ... existing instantiation code ...
}

private void ExtendCourse(int targetCount)
{
    int currentCount = courseData.Count;
    int needed = targetCount - currentCount;
    if (needed <= 0) return;

    var newTiles = generator.GenerateAdditionalTiles(needed);
    courseData.AddRange(newTiles);
}
```

**Step 2: Update TileGenerator to support continuous generation**

Modify `Assets/Scripts/World/TileGenerator.cs`:

```csharp
// Store state
private TileType lastType = TileType.Warmup;
private int consecutiveHardTiles = 0;
private float totalProgress = 0f;

// Modify GenerateCourse to use internal state
public List<TileData> GenerateCourse(int tileCount)
{
    var tiles = new List<TileData>();
    
    for (int i = 0; i < tileCount; i++)
    {
        // In fixed mode, progress is 0-1. In endless, it keeps increasing.
        float progress = (float)i / tileCount; 
        
        var tile = GenerateTile(progress, ref lastType, ref consecutiveHardTiles);
        tiles.Add(tile);
    }
    return tiles;
}

// Add method for endless extensions
public List<TileData> GenerateAdditionalTiles(int count)
{
    var tiles = new List<TileData>();
    
    for (int i = 0; i < count; i++)
    {
        // For endless, progress increases difficulty then caps
        // Assume "1.0" difficulty is reached at tile 50 (~2 mins)
        totalProgress += 0.02f; 
        float effectiveProgress = Mathf.Min(totalProgress, 1.5f); // Allow exceeding 1.0 slightly
        
        var tile = GenerateTile(effectiveProgress, ref lastType, ref consecutiveHardTiles);
        tiles.Add(tile);
    }
    return tiles;
}
```

**Step 3: Commit**

```bash
git add Assets/Scripts/World/WorldManager.cs Assets/Scripts/World/TileGenerator.cs
git commit -m "feat: implement infinite tile generation for endless mode"
```

---

## Phase: The Yeti

### Task 18: Create Yeti Logic & Data

**Files:**
- Create: `Assets/Scripts/Yeti/YetiData.cs`
- Create: `Assets/Tests/EditMode/YetiTests.cs`

**Step 1: Write failing tests**

```csharp
// Assets/Tests/EditMode/YetiTests.cs
using NUnit.Framework;

public class YetiTests
{
    [Test]
    public void Distance_CalculatedCorrectly()
    {
        // Yeti at 0, Player at -100
        var yeti = new YetiLogic(startPosition: 0f);
        yeti.Update(deltaTime: 1f, playerY: -100f);
        
        // Distance should be positive (Player is 100 units ahead)
        // Note: In our coordinate system, Down is Negative.
        // Player @ -100 is "below" Yeti @ 0.
        // Distance = Yeti.Y - Player.Y = 0 - (-100) = 100.
        Assert.AreEqual(100f, yeti.DistanceToPlayer);
    }

    [Test]
    public void Speed_ScalesWithTime()
    {
        var yeti = new YetiLogic(baseSpeed: 10f);
        
        // At 0 seconds, speed = base
        Assert.AreEqual(10f, yeti.CurrentSpeed);
        
        // At 60 seconds, speed should be higher (+15%)
        yeti.Update(deltaTime: 60f, playerY: -1000f);
        Assert.Greater(yeti.CurrentSpeed, 11f);
    }

    [Test]
    public void Zone_UpdatesBasedOnDistance()
    {
        var yeti = new YetiLogic();
        
        // Far away (Safe)
        yeti.SetDistance(200f); // ~10s at speed 20
        Assert.AreEqual(YetiZone.Safe, yeti.CurrentZone);
        
        // Close (Critical)
        yeti.SetDistance(10f); // ~0.5s at speed 20
        Assert.AreEqual(YetiZone.Critical, yeti.CurrentZone);
    }
}
```

**Step 2: Implement Yeti Logic**

```csharp
// Assets/Scripts/Yeti/YetiData.cs
using UnityEngine;

public enum YetiZone
{
    Safe,       // > 5s behind
    Warning,    // 3-5s behind
    Danger,     // 1-3s behind
    Critical,   // < 1s behind
    Caught      // 0 or negative
}

public class YetiLogic
{
    private float currentY;
    private float elapsedTime;
    private float baseSpeed;
    private float distanceToPlayer;
    
    public float CurrentY => currentY;
    public float CurrentSpeed { get; private set; }
    public float DistanceToPlayer => distanceToPlayer;
    public YetiZone CurrentZone { get; private set; }

    public YetiLogic(float startPosition = 200f, float baseSpeed = 25f) // Start 200 units above
    {
        this.currentY = startPosition;
        this.baseSpeed = baseSpeed;
        this.currentY = startPosition;
    }

    public void Update(float deltaTime, float playerY)
    {
        elapsedTime += deltaTime;
        
        // Update Speed: +15% every 60 seconds
        float scalingFactor = 1f + (elapsedTime / 60f) * 0.15f;
        CurrentSpeed = baseSpeed * scalingFactor;
        
        // Move Yeti Down (Negative Y)
        currentY -= CurrentSpeed * deltaTime;
        
        // Calculate Distance
        // Yeti is at e.g. -500, Player at -600. Distance is 100.
        distanceToPlayer = currentY - playerY;
        
        UpdateZone();
    }
    
    // Helper for testing
    public void SetDistance(float dist)
    {
        distanceToPlayer = dist;
        UpdateZone();
    }

    private void UpdateZone()
    {
        // Convert distance to time based on current speed
        float timeBehind = distanceToPlayer / CurrentSpeed;
        
        if (timeBehind <= 0) CurrentZone = YetiZone.Caught;
        else if (timeBehind < 1f) CurrentZone = YetiZone.Critical;
        else if (timeBehind < 3f) CurrentZone = YetiZone.Danger;
        else if (timeBehind < 5f) CurrentZone = YetiZone.Warning;
        else CurrentZone = YetiZone.Safe;
    }
}
```

**Step 3: Commit**

```bash
git add Assets/Scripts/Yeti/YetiData.cs Assets/Tests/EditMode/YetiTests.cs
git commit -m "feat: add Yeti logic core and tests"
```

---

### Task 19: Create Yeti Controller (MonoBehaviour)

**Files:**
- Create: `Assets/Scripts/Yeti/YetiController.cs`
- Create: `Assets/Prefabs/Yeti/Yeti.prefab` (via script)

**Step 1: Create Yeti Controller**

```csharp
// Assets/Scripts/Yeti/YetiController.cs
using UnityEngine;

public class YetiController : MonoBehaviour
{
    [Header("Settings")]
    [SerializeField] private float startOffset = 50f; // Start 50 units behind player
    [SerializeField] private float baseSpeed = 25f;   // Match "Moderate" skier speed
    
    [Header("Visuals")]
    [SerializeField] private SpriteRenderer spriteRenderer;
    [SerializeField] private Animator animator;
    
    [Header("References")]
    [SerializeField] private Transform player;
    [SerializeField] private GameManager gameManager;

    private YetiLogic logic;
    private bool isActive;

    public YetiZone CurrentZone => logic != null ? logic.CurrentZone : YetiZone.Safe;
    public float Distance => logic != null ? logic.DistanceToPlayer : 100f;

    private void Start()
    {
        if (gameManager.CurrentMode != GameMode.Endless)
        {
            gameObject.SetActive(false);
            return;
        }

        float startY = player.position.y + startOffset;
        logic = new YetiLogic(startY, baseSpeed);
        isActive = true;
        
        // Move visual to start
        transform.position = new Vector3(0, startY, 0);
    }

    private void Update()
    {
        if (!isActive || player == null) return;

        logic.Update(Time.deltaTime, player.position.y);
        
        // Update visual position (keep X aligned with player for dramatic effect, or center?)
        // Let's center X but jitter if close? For now, center.
        transform.position = new Vector3(0, logic.CurrentY, 0);
        
        CheckCatch();
        UpdateVisuals();
    }

    private void CheckCatch()
    {
        if (logic.CurrentZone == YetiZone.Caught)
        {
            isActive = false;
            Debug.Log("YETI CAUGHT PLAYER!");
            gameManager.TriggerGameOver("Eaten by Yeti");
            // Play catch animation/sound here
        }
    }
    
    private void UpdateVisuals()
    {
        // Scale sprite based on proximity? 
        // Or just let camera follow player and Yeti comes into view naturally?
        // Since camera follows player, Yeti will naturally appear when close.
        
        if (logic.CurrentZone == YetiZone.Critical)
        {
            // Reach animation trigger
             if (animator) animator.SetBool("Reaching", true);
        }
    }
}
```

**Step 2: Create Yeti Prefab via Script**

Modify `Assets/Editor/PrefabCreator.cs` to add:

```csharp
[MenuItem("Ski Free Or Die/Create Prefabs/Create Yeti Prefab")]
public static void CreateYetiPrefab()
{
    EnsureDirectoryExists("Assets/Prefabs/Yeti");
    EnsureDirectoryExists("Assets/Sprites/Yeti");

    // Create placeholder sprite
    string spritePath = "Assets/Sprites/Yeti/yeti_placeholder.png";
    if (!System.IO.File.Exists(spritePath))
    {
        CreatePlaceholderSprite(spritePath, 32, 48, Color.white); // Big white block
        AssetDatabase.Refresh();
    }

    GameObject go = new GameObject("Yeti");
    var sr = go.AddComponent<SpriteRenderer>();
    sr.sprite = AssetDatabase.LoadAssetAtPath<Sprite>(spritePath);
    sr.sortingLayerName = "Obstacles"; 
    sr.sortingOrder = 10; // On top of trees

    // Add Controller
    var controllerType = System.Type.GetType("YetiController, Assembly-CSharp");
    if (controllerType != null) go.AddComponent(controllerType);

    string path = "Assets/Prefabs/Yeti/Yeti.prefab";
    PrefabUtility.SaveAsPrefabAsset(go, path);
    DestroyImmediate(go);
    Debug.Log($"Created Yeti prefab at {path}");
}
```

**Step 3: Commit**

```bash
git add Assets/Scripts/Yeti/YetiController.cs Assets/Editor/PrefabCreator.cs
git commit -m "feat: add YetiController and prefab generation"
```

---

### Task 20: Visual & Audio Feedback (Tension System)

**Files:**
- Create: `Assets/Scripts/Yeti/YetiEffectManager.cs`
- Modify: `Assets/Scripts/UI/GameHUD.cs`

**Step 1: Create Effect Manager**

```csharp
// Assets/Scripts/Yeti/YetiEffectManager.cs
using UnityEngine;
using UnityEngine.UI;

public class YetiEffectManager : MonoBehaviour
{
    [Header("References")]
    [SerializeField] private YetiController yeti;
    [SerializeField] private Image dangerVignette; // Red screen edge overlay
    [SerializeField] private Image frostVignette;  // Blue top edge overlay
    
    private void Update()
    {
        if (yeti == null || !yeti.gameObject.activeSelf) return;

        UpdateVignettes(yeti.CurrentZone);
    }

    private void UpdateVignettes(YetiZone zone)
    {
        if (dangerVignette == null || frostVignette == null) return;

        // Reset
        var dangerColor = dangerVignette.color;
        var frostColor = frostVignette.color;
        
        switch (zone)
        {
            case YetiZone.Safe:
                frostColor.a = 0.1f;
                dangerColor.a = 0f;
                break;
            case YetiZone.Warning:
                frostColor.a = 0.3f;
                dangerColor.a = 0f;
                break;
            case YetiZone.Danger:
                frostColor.a = 0f;
                dangerColor.a = Mathf.PingPong(Time.time * 2f, 0.5f); // Pulse
                break;
            case YetiZone.Critical:
                frostColor.a = 0f;
                dangerColor.a = 0.8f + Mathf.PingPong(Time.time * 5f, 0.2f); // Fast pulse
                break;
        }

        dangerVignette.color = dangerColor;
        frostVignette.color = frostColor;
    }
}
```

**Step 2: Update HUD for Endless Scoring**

Modify `GameHUD.cs` to show distance if in Endless mode:

```csharp
// Update UpdateTimer method
private void UpdateTimer()
{
    if (gameManager.CurrentMode == GameMode.Endless)
    {
        // Show distance instead of time? Or both?
        // Let's show Distance Traveled in meters
        float distance = Mathf.Abs(skier.transform.position.y);
        timerText.text = $"{distance:F0}m";
    }
    else
    {
        // Existing time logic
    }
}
```

**Step 3: Commit**

```bash
git add Assets/Scripts/Yeti/YetiEffectManager.cs Assets/Scripts/UI/GameHUD.cs
git commit -m "feat: add visual tension effects and endless HUD updates"
```

---

## Summary

**Endless Mode Logic:**
- `GameMode` switch ensures core mechanics work for both types.
- `WorldManager` now generates infinite terrain on demand.
- `TileGenerator` scales difficulty indefinitely.

**Yeti Mechanics:**
- `YetiLogic` handles the math (speed scaling, zone calculation) purely.
- `YetiController` manages the GameObject and triggers Game Over.
- `YetiEffectManager` provides crucial feedback so death isn't a surprise.

**Files Created:**
```
Assets/Scripts/Core/GameMode.cs
Assets/Scripts/Yeti/YetiData.cs
Assets/Scripts/Yeti/YetiController.cs
Assets/Scripts/Yeti/YetiEffectManager.cs
Assets/Tests/EditMode/YetiTests.cs
Assets/Prefabs/Yeti/Yeti.prefab
```

**Integration Points:**
- `GameManager` (Modes, Game Over)
- `WorldManager` (Infinite Spawning)
- `GameHUD` (Scoring)
