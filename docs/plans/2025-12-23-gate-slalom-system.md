# Gate & Slalom System Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement slalom gates that players must ski through, with time penalties for misses and visual/audio feedback.

**Architecture:** Gates are trigger colliders placed in pairs (left pole, right pole) with a detection zone between them. The GateManager tracks gate order and whether each was passed or missed. Missed gates add +3 seconds to the timer. Visual feedback uses color changes and particle effects.

**Tech Stack:** Unity 2022.3 LTS, C#, Unity Test Framework

**Prerequisites:** Complete Tasks 1-6 from `core-game-implementation.md` (player movement working)

**Reference:** `unity-project-config.md` for sprite specs, colors, and layer setup

---

## Phase: Gate Data Model

### Task 1: Create Gate Data Structures

**Files:**
- Create: `Assets/Scripts/Gates/GateData.cs`
- Create: `Assets/Tests/EditMode/GateDataTests.cs`

**Step 1: Write failing tests for gate state**

```csharp
// Assets/Tests/EditMode/GateDataTests.cs
using NUnit.Framework;

public class GateDataTests
{
    [Test]
    public void NewGate_StartsAsPending()
    {
        var gate = new GateData(gateIndex: 0, positionY: -50f);
        Assert.AreEqual(GateState.Pending, gate.State);
    }

    [Test]
    public void MarkPassed_ChangesStateToPassed()
    {
        var gate = new GateData(gateIndex: 0, positionY: -50f);
        gate.MarkPassed();
        Assert.AreEqual(GateState.Passed, gate.State);
    }

    [Test]
    public void MarkMissed_ChangesStateToMissed()
    {
        var gate = new GateData(gateIndex: 0, positionY: -50f);
        gate.MarkMissed();
        Assert.AreEqual(GateState.Missed, gate.State);
    }

    [Test]
    public void CannotChangeState_AfterAlreadySet()
    {
        var gate = new GateData(gateIndex: 0, positionY: -50f);
        gate.MarkPassed();
        gate.MarkMissed(); // Should not change
        Assert.AreEqual(GateState.Passed, gate.State);
    }

    [Test]
    public void TimePenalty_IsZeroForPassed()
    {
        var gate = new GateData(gateIndex: 0, positionY: -50f);
        gate.MarkPassed();
        Assert.AreEqual(0f, gate.TimePenalty);
    }

    [Test]
    public void TimePenalty_IsThreeSecondsForMissed()
    {
        var gate = new GateData(gateIndex: 0, positionY: -50f);
        gate.MarkMissed();
        Assert.AreEqual(3f, gate.TimePenalty);
    }
}
```

**Step 2: Run tests to verify they fail**

Open Unity Test Runner (Window > General > Test Runner).
Expected: Compilation error - `GateData`, `GateState` not defined.

**Step 3: Implement gate data structures**

```csharp
// Assets/Scripts/Gates/GateData.cs
using UnityEngine;

public enum GateState
{
    Pending,    // Not yet reached
    Passed,     // Successfully passed through
    Missed      // Skipped or went around
}

[System.Serializable]
public class GateData
{
    public const float MISS_PENALTY = 3f;

    [SerializeField] private int gateIndex;
    [SerializeField] private float positionY;
    [SerializeField] private GateState state;

    public int GateIndex => gateIndex;
    public float PositionY => positionY;
    public GateState State => state;

    public float TimePenalty => state == GateState.Missed ? MISS_PENALTY : 0f;

    public GateData(int gateIndex, float positionY)
    {
        this.gateIndex = gateIndex;
        this.positionY = positionY;
        this.state = GateState.Pending;
    }

    public void MarkPassed()
    {
        if (state == GateState.Pending)
        {
            state = GateState.Passed;
        }
    }

    public void MarkMissed()
    {
        if (state == GateState.Pending)
        {
            state = GateState.Missed;
        }
    }
}
```

**Step 4: Run tests to verify they pass**

Expected: All 6 tests PASS.

**Step 5: Commit**

```bash
git add Assets/Scripts/Gates/GateData.cs Assets/Tests/EditMode/GateDataTests.cs
git commit -m "feat: add GateData with state tracking and time penalty"
```

---

### Task 2: Create Gate Manager

**Files:**
- Create: `Assets/Scripts/Gates/GateManager.cs`
- Create: `Assets/Tests/EditMode/GateManagerTests.cs`

**Step 1: Write failing tests for gate tracking**

```csharp
// Assets/Tests/EditMode/GateManagerTests.cs
using NUnit.Framework;
using System.Collections.Generic;

public class GateManagerTests
{
    [Test]
    public void RegisterGate_AddsToList()
    {
        var manager = new GateManagerLogic();
        manager.RegisterGate(0, -50f);
        manager.RegisterGate(1, -100f);

        Assert.AreEqual(2, manager.GateCount);
    }

    [Test]
    public void GetNextGateIndex_ReturnsZeroInitially()
    {
        var manager = new GateManagerLogic();
        manager.RegisterGate(0, -50f);
        manager.RegisterGate(1, -100f);

        Assert.AreEqual(0, manager.NextGateIndex);
    }

    [Test]
    public void PassGate_AdvancesNextGateIndex()
    {
        var manager = new GateManagerLogic();
        manager.RegisterGate(0, -50f);
        manager.RegisterGate(1, -100f);

        manager.PassGate(0);

        Assert.AreEqual(1, manager.NextGateIndex);
    }

    [Test]
    public void PlayerPassedGateY_WithoutPassing_MarksMissed()
    {
        var manager = new GateManagerLogic();
        manager.RegisterGate(0, -50f);
        manager.RegisterGate(1, -100f);

        // Player at Y=-60 (past gate 0 at -50) without passing
        manager.UpdatePlayerPosition(-60f);

        Assert.AreEqual(GateState.Missed, manager.GetGateState(0));
        Assert.AreEqual(1, manager.NextGateIndex);
    }

    [Test]
    public void TotalPenalty_SumsAllMissedGates()
    {
        var manager = new GateManagerLogic();
        manager.RegisterGate(0, -50f);
        manager.RegisterGate(1, -100f);
        manager.RegisterGate(2, -150f);

        manager.UpdatePlayerPosition(-60f);  // Miss gate 0
        manager.PassGate(1);                  // Pass gate 1
        manager.UpdatePlayerPosition(-160f); // Miss gate 2

        Assert.AreEqual(6f, manager.TotalPenalty); // 3 + 0 + 3
    }

    [Test]
    public void GatesPassed_CountsOnlyPassed()
    {
        var manager = new GateManagerLogic();
        manager.RegisterGate(0, -50f);
        manager.RegisterGate(1, -100f);
        manager.RegisterGate(2, -150f);

        manager.PassGate(0);
        manager.UpdatePlayerPosition(-110f); // Miss gate 1
        manager.PassGate(2);

        Assert.AreEqual(2, manager.GatesPassed);
        Assert.AreEqual(1, manager.GatesMissed);
    }
}
```

**Step 2: Run tests to verify they fail**

Expected: Compilation error - `GateManagerLogic` not defined.

**Step 3: Implement gate manager logic**

```csharp
// Assets/Scripts/Gates/GateManager.cs
using UnityEngine;
using System.Collections.Generic;

/// <summary>
/// Pure logic class for gate tracking (testable without MonoBehaviour).
/// </summary>
public class GateManagerLogic
{
    private List<GateData> gates = new List<GateData>();
    private int nextGateIndex = 0;

    public int GateCount => gates.Count;
    public int NextGateIndex => nextGateIndex;

    public int GatesPassed
    {
        get
        {
            int count = 0;
            foreach (var gate in gates)
            {
                if (gate.State == GateState.Passed) count++;
            }
            return count;
        }
    }

    public int GatesMissed
    {
        get
        {
            int count = 0;
            foreach (var gate in gates)
            {
                if (gate.State == GateState.Missed) count++;
            }
            return count;
        }
    }

    public float TotalPenalty
    {
        get
        {
            float total = 0f;
            foreach (var gate in gates)
            {
                total += gate.TimePenalty;
            }
            return total;
        }
    }

    public void RegisterGate(int index, float positionY)
    {
        gates.Add(new GateData(index, positionY));
        // Keep sorted by Y position (descending, since player moves negative Y)
        gates.Sort((a, b) => b.PositionY.CompareTo(a.PositionY));
    }

    public void PassGate(int gateIndex)
    {
        if (gateIndex >= 0 && gateIndex < gates.Count)
        {
            gates[gateIndex].MarkPassed();
            AdvanceToNextPendingGate();
        }
    }

    public void UpdatePlayerPosition(float playerY)
    {
        // Check if player has passed any pending gates without triggering them
        while (nextGateIndex < gates.Count)
        {
            var gate = gates[nextGateIndex];
            if (gate.State != GateState.Pending)
            {
                nextGateIndex++;
                continue;
            }

            // Player is below this gate (more negative Y)
            if (playerY < gate.PositionY - 2f) // 2 unit buffer
            {
                gate.MarkMissed();
                nextGateIndex++;
            }
            else
            {
                break;
            }
        }
    }

    public GateState GetGateState(int index)
    {
        if (index >= 0 && index < gates.Count)
        {
            return gates[index].State;
        }
        return GateState.Pending;
    }

    private void AdvanceToNextPendingGate()
    {
        while (nextGateIndex < gates.Count && gates[nextGateIndex].State != GateState.Pending)
        {
            nextGateIndex++;
        }
    }

    public void Clear()
    {
        gates.Clear();
        nextGateIndex = 0;
    }
}

/// <summary>
/// MonoBehaviour wrapper for scene integration.
/// </summary>
public class GateManager : MonoBehaviour
{
    private GateManagerLogic logic = new GateManagerLogic();

    [Header("References")]
    [SerializeField] private Transform player;

    [Header("Debug")]
    [SerializeField] private int gatesPassed;
    [SerializeField] private int gatesMissed;
    [SerializeField] private float totalPenalty;

    public int GatesPassed => logic.GatesPassed;
    public int GatesMissed => logic.GatesMissed;
    public float TotalPenalty => logic.TotalPenalty;
    public int NextGateIndex => logic.NextGateIndex;

    public event System.Action<int> OnGatePassed;
    public event System.Action<int> OnGateMissed;

    private void Update()
    {
        if (player != null)
        {
            int previousMissed = logic.GatesMissed;
            logic.UpdatePlayerPosition(player.position.y);

            // Fire events for newly missed gates
            if (logic.GatesMissed > previousMissed)
            {
                OnGateMissed?.Invoke(logic.NextGateIndex - 1);
            }
        }

        // Update debug display
        gatesPassed = logic.GatesPassed;
        gatesMissed = logic.GatesMissed;
        totalPenalty = logic.TotalPenalty;
    }

    public void RegisterGate(int index, float positionY)
    {
        logic.RegisterGate(index, positionY);
    }

    public void NotifyGatePassed(int gateIndex)
    {
        logic.PassGate(gateIndex);
        OnGatePassed?.Invoke(gateIndex);
    }

    public void Clear()
    {
        logic.Clear();
    }
}
```

**Step 4: Run tests to verify they pass**

Expected: All 6 tests PASS.

**Step 5: Commit**

```bash
git add Assets/Scripts/Gates/GateManager.cs Assets/Tests/EditMode/GateManagerTests.cs
git commit -m "feat: add GateManager with miss detection and penalty tracking"
```

---

## Phase: Gate Prefab & Detection

### Task 3: Create Gate Trigger Component

**Files:**
- Create: `Assets/Scripts/Gates/GateTrigger.cs`

**Step 1: Create gate trigger component**

```csharp
// Assets/Scripts/Gates/GateTrigger.cs
using UnityEngine;

[RequireComponent(typeof(BoxCollider2D))]
public class GateTrigger : MonoBehaviour
{
    [Header("Gate Identity")]
    [SerializeField] private int gateIndex;

    [Header("Visual References")]
    [SerializeField] private SpriteRenderer leftPole;
    [SerializeField] private SpriteRenderer rightPole;
    [SerializeField] private SpriteRenderer flag;

    [Header("Colors")]
    [SerializeField] private Color pendingColor = new Color(1f, 0.08f, 0.58f); // Hot Pink #FF1493
    [SerializeField] private Color passedColor = new Color(0f, 1f, 0.5f);      // Mint Green #00FF7F
    [SerializeField] private Color missedColor = new Color(0.5f, 0.5f, 0.5f);  // Gray

    [Header("State")]
    [SerializeField] private bool hasBeenTriggered;

    private GateManager gateManager;
    private BoxCollider2D triggerCollider;

    public int GateIndex => gateIndex;

    private void Awake()
    {
        triggerCollider = GetComponent<BoxCollider2D>();
        triggerCollider.isTrigger = true;

        // Find GateManager in scene
        gateManager = FindObjectOfType<GateManager>();
    }

    private void Start()
    {
        // Register with manager
        if (gateManager != null)
        {
            gateManager.RegisterGate(gateIndex, transform.position.y);
        }

        SetColor(pendingColor);
    }

    private void OnTriggerEnter2D(Collider2D other)
    {
        if (hasBeenTriggered) return;

        var skier = other.GetComponent<SkierController>();
        if (skier == null) return;

        hasBeenTriggered = true;

        if (gateManager != null)
        {
            gateManager.NotifyGatePassed(gateIndex);
        }

        SetColor(passedColor);
        PlayPassEffect();
    }

    public void SetGateIndex(int index)
    {
        gateIndex = index;
    }

    public void MarkAsMissed()
    {
        if (!hasBeenTriggered)
        {
            hasBeenTriggered = true;
            SetColor(missedColor);
            PlayMissEffect();
        }
    }

    private void SetColor(Color color)
    {
        if (leftPole != null) leftPole.color = color;
        if (rightPole != null) rightPole.color = color;
        if (flag != null) flag.color = color;
    }

    private void PlayPassEffect()
    {
        // TODO: Particle effect, sound
        Debug.Log($"Gate {gateIndex} PASSED!");
    }

    private void PlayMissEffect()
    {
        // TODO: Different particle effect, sound
        Debug.Log($"Gate {gateIndex} MISSED! +3 seconds");
    }
}
```

**Step 2: Verify component compiles**

Save and check Unity console for errors. Expected: No errors.

**Step 3: Commit**

```bash
git add Assets/Scripts/Gates/GateTrigger.cs
git commit -m "feat: add GateTrigger with visual feedback"
```

---

### Task 4: Create Gate Prefab

**Files:**
- Create: `Assets/Prefabs/Gates/Gate.prefab` (via PrefabCreator script)
- Create: `Assets/Sprites/Gates/gate_pole_placeholder.png` (auto-generated)
- Create: `Assets/Sprites/Gates/gate_flag_placeholder.png` (auto-generated)

**Step 1: Create Gate prefab via script**

In Unity Editor:
1. Menu > Ski Free Or Die > Create Prefabs > Create Gate Prefab

This automatically:
- Creates placeholder sprites (8x32 pole, 16x16 flag in Hot Pink)
- Builds the prefab structure with correct hierarchy
- Sets layer to "Gate"
- Sets sorting layer to "Gates"
- Adds BoxCollider2D trigger
- Wires up GateTrigger component references

**Gate prefab structure (created automatically):**

```
Gate (Empty GameObject)
├── GateTrigger (Component)
├── BoxCollider2D (isTrigger = true, size 3x0.5)
├── LeftPole (SpriteRenderer, position -1, 0)
│   └── gate_pole_placeholder sprite
├── RightPole (SpriteRenderer, position 1, 0)
│   └── gate_pole_placeholder sprite
└── Flag (SpriteRenderer, position 0, 1)
    └── gate_flag_placeholder sprite
```

**Step 2: Set up GateManager in scene**

1. Select GameManager object (or create one)
2. Add GateManager component
3. Assign player reference in Inspector

**Step 3: Test in scene**

1. Drag Gate prefab to scene at position (0, -30, 0)
2. Play scene
3. Ski through gate - should turn Mint Green, console logs "Gate 0 PASSED!"
4. Restart, ski around gate - should turn gray, console logs "Gate 0 MISSED! +3 seconds"

**Step 4: Verification**

- [ ] Gate prefab exists at `Assets/Prefabs/Gates/Gate.prefab`
- [ ] Gate has BoxCollider2D with isTrigger = true
- [ ] Gate is on "Gate" layer
- [ ] GateTrigger has references to LeftPole, RightPole, Flag SpriteRenderers
- [ ] Passing through gate changes color to green
- [ ] Missing gate changes color to gray
- [ ] GateManager tracks passed/missed counts

**Step 5: Commit**

```bash
git add Assets/Prefabs/Gates/ Assets/Sprites/Gates/
git commit -m "feat: add Gate prefab with trigger detection"
```

---

## Phase: Integration

### Task 5: Integrate Penalties with GameManager

**Files:**
- Modify: `Assets/Scripts/Core/GameManager.cs`

**Step 1: Update GameManager to use gate penalties**

Add to `GameManager.cs`:

```csharp
// Add field
[SerializeField] private GateManager gateManager;

// Add properties
public float TotalTime => elapsedTime + (gateManager != null ? gateManager.TotalPenalty : 0f);
public float Penalties => gateManager != null ? gateManager.TotalPenalty : 0f;
public int GatesPassed => gateManager != null ? gateManager.GatesPassed : 0;
public int GatesMissed => gateManager != null ? gateManager.GatesMissed : 0;

// Modify HandleFinish
private void HandleFinish()
{
    if (isFinished) return;

    isFinished = true;
    isRunning = false;

    float penalties = gateManager != null ? gateManager.TotalPenalty : 0f;
    float totalTime = elapsedTime + penalties;

    OnGameFinish?.Invoke(totalTime);

    Debug.Log($"Finished! Raw: {elapsedTime:F2}s + Penalties: {penalties:F2}s = Total: {totalTime:F2}s");
}
```

**Step 2: Set up in scene**

1. Add GateManager component (if not already)
2. Assign to GameManager's gateManager field

**Step 3: Test integration**

1. Place 3 gates in scene
2. Play and intentionally miss 1 gate
3. Finish line should show raw time + 3 seconds penalty

**Step 4: Commit**

```bash
git add Assets/Scripts/Core/GameManager.cs
git commit -m "feat: integrate gate penalties with game timer"
```

---

### Task 6: Update HUD for Gate Display

**Files:**
- Modify: `Assets/Scripts/UI/GameHUD.cs`

**Step 1: Add gate display to HUD**

Add to `GameHUD.cs`:

```csharp
// Add fields
[SerializeField] private Text gateText;
[SerializeField] private Text penaltyText;

// Add to Update
private void UpdateGates()
{
    if (gateText == null || gameManager == null) return;

    gateText.text = $"GATES: {gameManager.GatesPassed}/{gameManager.GatesPassed + gameManager.GatesMissed}";
}

private void UpdatePenalty()
{
    if (penaltyText == null || gameManager == null) return;

    float penalties = gameManager.Penalties;
    if (penalties > 0)
    {
        penaltyText.text = $"+{penalties:F0}s";
        penaltyText.color = new Color(1f, 0.27f, 0f); // Sunset Orange
    }
    else
    {
        penaltyText.text = "";
    }
}

// Call in Update
private void Update()
{
    UpdateTimer();
    UpdateSpeed();
    UpdateGates();
    UpdatePenalty();
}

// Update ShowFinishScreen
private void ShowFinishScreen(float finalTime)
{
    if (finishPanel != null)
    {
        finishPanel.SetActive(true);
    }

    if (finishText != null)
    {
        float rawTime = gameManager.ElapsedTime;
        float penalties = gameManager.Penalties;
        int passed = gameManager.GatesPassed;
        int missed = gameManager.GatesMissed;

        string timeStr = FormatTime(finalTime);
        string penaltyStr = penalties > 0 ? $"\n+{penalties:F0}s PENALTY" : "";
        string gateStr = $"\nGATES: {passed}/{passed + missed}";

        finishText.text = $"FINISH!\n{timeStr}{penaltyStr}{gateStr}";
    }
}

private string FormatTime(float time)
{
    int minutes = Mathf.FloorToInt(time / 60f);
    int seconds = Mathf.FloorToInt(time % 60f);
    int milliseconds = Mathf.FloorToInt((time * 100f) % 100f);
    return $"{minutes:00}:{seconds:00}.{milliseconds:00}";
}
```

**Step 2: Add UI elements**

1. Create Text element for gates (position top-left)
2. Create Text element for penalty (position below timer, red when active)
3. Wire up references in GameHUD component

**Step 3: Test HUD**

1. Play scene
2. Gates passed should update
3. Penalty should show when gate missed
4. Finish screen should show breakdown

**Step 4: Commit**

```bash
git add Assets/Scripts/UI/GameHUD.cs
git commit -m "feat: add gate and penalty display to HUD"
```

---

## Phase: Gate Spawning in Tiles

### Task 7: Add Gate Spawning to TileInstance

**Files:**
- Modify: `Assets/Scripts/World/TileData.cs`
- Modify: `Assets/Scripts/World/TileInstance.cs`

**Step 1: Add gate spawn data to TileData**

Add to `TileData.cs`:

```csharp
[System.Serializable]
public class GateSpawn
{
    public float NormalizedX;     // 0-1 across tile width (center of gate)
    public float NormalizedY;     // 0-1 along tile height
    public float Width;           // Gate width (distance between poles)

    public GateSpawn(float x, float y, float width = 3f)
    {
        NormalizedX = x;
        NormalizedY = y;
        Width = width;
    }
}

// Add to TileData class
public List<GateSpawn> Gates;

// Update constructor
public TileData(TileType type, SlopeIntensity slope, List<ObstacleSpawn> obstacles, List<GateSpawn> gates = null)
{
    Type = type;
    Slope = slope;
    Obstacles = obstacles ?? new List<ObstacleSpawn>();
    Gates = gates ?? new List<GateSpawn>();
}
```

**Step 2: Update TileInstance to spawn gates**

Add to `TileInstance.cs`:

```csharp
// Add field
[SerializeField] private List<GateTrigger> spawnedGates = new List<GateTrigger>();

// Add parameter to Initialize
public void Initialize(TileData tileData, Dictionary<ObstacleType, GameObject> obstaclePrefabs, GameObject gatePrefab, ref int gateCounter)
{
    data = tileData;
    SpawnObstacles(obstaclePrefabs);
    SpawnGates(gatePrefab, ref gateCounter);
}

private void SpawnGates(GameObject gatePrefab, ref int gateCounter)
{
    if (gatePrefab == null) return;

    foreach (var spawn in data.Gates)
    {
        float x = (spawn.NormalizedX - 0.5f) * tileWidth;
        float y = (spawn.NormalizedY - 0.5f) * tileHeight;
        Vector3 localPos = new Vector3(x, y, 0);

        var gateObj = Instantiate(gatePrefab, transform);
        gateObj.transform.localPosition = localPos;

        var gateTrigger = gateObj.GetComponent<GateTrigger>();
        if (gateTrigger != null)
        {
            gateTrigger.SetGateIndex(gateCounter);
            gateCounter++;
        }

        spawnedGates.Add(gateTrigger);
    }
}

// Update Cleanup
public void Cleanup()
{
    foreach (var obstacle in spawnedObstacles)
    {
        if (obstacle != null) Destroy(obstacle);
    }
    spawnedObstacles.Clear();

    foreach (var gate in spawnedGates)
    {
        if (gate != null) Destroy(gate.gameObject);
    }
    spawnedGates.Clear();
}
```

**Step 3: Update WorldManager**

Add to `WorldManager.cs`:

```csharp
// Add field
[SerializeField] private GameObject gatePrefab;
private int gateCounter = 0;

// Update SpawnTile
private void SpawnTile(int index)
{
    // ... existing code ...
    tileInstance.Initialize(courseData[index], obstaclePrefabs, gatePrefab, ref gateCounter);
    // ...
}
```

**Step 4: Commit**

```bash
git add Assets/Scripts/World/TileData.cs Assets/Scripts/World/TileInstance.cs Assets/Scripts/World/WorldManager.cs
git commit -m "feat: add gate spawning to tile system"
```

---

### Task 8: Update TileGenerator for Slalom Tiles

**Files:**
- Modify: `Assets/Scripts/World/TileGenerator.cs`

**Step 1: Add gate generation to slalom tiles**

Update `TileGenerator.cs`:

```csharp
private TileData GenerateTile(float progress, TileType previousType, ref int hardTilesInRow)
{
    // ... existing type selection code ...

    var obstacles = GenerateObstacles(type, difficulty);
    var gates = GenerateGates(type, difficulty);
    return new TileData(type, slope, obstacles, gates);
}

private List<GateSpawn> GenerateGates(TileType type, int difficulty)
{
    var gates = new List<GateSpawn>();

    if (type != TileType.Slalom) return gates;

    // Number of gates based on difficulty
    int gateCount = difficulty switch
    {
        1 or 2 => 2,
        3 or 4 => 3,
        _ => 4
    };

    // Gate width (distance between poles) - narrower at higher difficulty
    float gateWidth = difficulty switch
    {
        1 or 2 => 4f,  // Wide, forgiving
        3 or 4 => 3f,  // Standard
        _ => 2.5f      // Tight
    };

    // Generate alternating left-right pattern
    float ySpacing = 1f / (gateCount + 1);

    for (int i = 0; i < gateCount; i++)
    {
        // Alternate sides: 0.3 (left), 0.7 (right), 0.3, 0.7...
        float baseX = (i % 2 == 0) ? 0.35f : 0.65f;

        // Add some randomness
        float xOffset = rng.Range(-0.1f, 0.1f);
        float x = Mathf.Clamp(baseX + xOffset, 0.2f, 0.8f);

        float y = ySpacing * (i + 1);

        gates.Add(new GateSpawn(x, y, gateWidth));
    }

    return gates;
}
```

**Step 2: Update TileDataTests**

Add to `TileDataTests.cs`:

```csharp
[Test]
public void TileData_StoresGatePositions()
{
    var gates = new List<GateSpawn>
    {
        new GateSpawn(0.3f, 0.25f, 3f),
        new GateSpawn(0.7f, 0.75f, 3f)
    };

    var tile = new TileData(TileType.Slalom, SlopeIntensity.Moderate, new List<ObstacleSpawn>(), gates);

    Assert.AreEqual(2, tile.Gates.Count);
    Assert.AreEqual(0.3f, tile.Gates[0].NormalizedX, 0.01f);
}
```

**Step 3: Run tests**

Expected: All tests pass.

**Step 4: Test full integration**

1. Play scene
2. Slalom tiles should spawn with gates
3. Gates should be in alternating left-right pattern
4. Passing through gates turns them green
5. Missing gates adds penalty

**Step 5: Commit**

```bash
git add Assets/Scripts/World/TileGenerator.cs Assets/Tests/EditMode/TileDataTests.cs
git commit -m "feat: generate gates for slalom tiles"
```

---

## Summary

**Gate System Complete:**
- GateData tracks individual gate state and penalty
- GateManager tracks all gates, detects misses by position
- GateTrigger handles collision detection and visual feedback
- Gate prefab with poles and flag
- GameManager integrates penalties into final time
- HUD shows gates passed and penalty time
- TileGenerator spawns gates in slalom tiles

**Files Created:**
```
Assets/
├── Scripts/
│   └── Gates/
│       ├── GateData.cs
│       ├── GateManager.cs
│       └── GateTrigger.cs
├── Tests/
│   └── EditMode/
│       ├── GateDataTests.cs
│       └── GateManagerTests.cs
├── Prefabs/
│   └── Gates/
│       └── Gate.prefab
└── Sprites/
    └── Gates/
        ├── gate_pole.png
        └── gate_flag.png
```

**Integration Points:**
- `GameManager.cs` - Penalty integration
- `GameHUD.cs` - Gate display
- `TileData.cs` - Gate spawn data
- `TileInstance.cs` - Gate instantiation
- `TileGenerator.cs` - Gate placement logic
- `WorldManager.cs` - Gate prefab reference
