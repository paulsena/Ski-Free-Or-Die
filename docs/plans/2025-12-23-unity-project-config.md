# Unity Project Configuration & Art Specifications

> **For Claude:** Reference this document when setting up the Unity project or creating sprites. These are concrete values to use, not suggestions.

**Goal:** Define all Unity project settings and art specifications so any engineer (or LLM) can set up consistent, correct configurations.

**Scope:** Project settings, camera config, physics layers, sprite specs, color palette, animation frames.

---

## Section 1: Project Settings

### Display & Resolution

| Setting | Value | Rationale |
|---------|-------|-----------|
| Reference Resolution | 320x180 | 16:9 at retro pixel scale |
| Target Resolution | 1920x1080 (scales up 6x) | Modern 1080p displays |
| Aspect Ratio | 16:9 | Standard widescreen |
| Fullscreen Mode | Fullscreen Window | Best compatibility |

**In Unity:** Edit > Project Settings > Player > Resolution and Presentation

### Quality Settings

| Setting | Value |
|---------|-------|
| Pixel Light Count | 0 (no dynamic lights) |
| Texture Quality | Full Res |
| Anisotropic Textures | Disabled |
| Anti-Aliasing | Disabled (pixel art) |
| VSync | Every V Blank |

---

## Section 2: Camera Configuration

### Main Camera Settings

| Setting | Value | Rationale |
|---------|-------|-----------|
| Projection | Orthographic | 2D game |
| Orthographic Size | 5.625 | Shows 180 pixels vertically at 32 PPU |
| Clear Flags | Solid Color |
| Background Color | #87CEEB (Sky Blue) | Placeholder, will be snow-covered slope |
| Culling Mask | Everything |
| Depth | -1 |

**Calculation:** Orthographic Size = (Reference Height / 2) / Pixels Per Unit = 180 / 2 / 16 = 5.625

> **Note:** All sprites use 16 PPU. The orthographic size of 5.625 displays exactly 180 pixels vertically.

### Pixel Perfect Camera (Optional)

If using Unity's Pixel Perfect Camera package:

| Setting | Value |
|---------|-------|
| Assets Pixels Per Unit | 16 |
| Reference Resolution | 320x180 |
| Upscale Render Texture | On |
| Pixel Snapping | On |
| Crop Frame | Pillar and Letterbox |

---

## Section 3: Physics2D Configuration

### Layer Setup

Create these layers in Edit > Project Settings > Tags and Layers:

| Layer # | Name | Purpose |
|---------|------|---------|
| 0 | Default | Unity default |
| 6 | Player | Skier only |
| 7 | Obstacle | Trees, rocks, cabins |
| 8 | Gate | Slalom gates (triggers) |
| 9 | Terrain | Ground/tile boundaries |
| 10 | Trigger | Non-collision triggers (finish line, zones) |

### Collision Matrix

Set in Edit > Project Settings > Physics 2D > Layer Collision Matrix:

```
           Player  Obstacle  Gate  Terrain  Trigger
Player       -        X       X      X        X
Obstacle     X        -       -      -        -
Gate         X        -       -      -        -
Terrain      X        -       -      -        -
Trigger      X        -       -      -        -
```

X = Collides, - = No collision

**Key:** Player collides with everything. Nothing else collides with each other.

### Physics2D Settings

| Setting | Value | Rationale |
|---------|-------|-----------|
| Gravity | (0, 0) | We handle movement manually |
| Default Material | None | Friction handled in code |
| Velocity Iterations | 8 | Default |
| Position Iterations | 3 | Default |
| Velocity Threshold | 1 | Default |

---

## Section 4: Sorting Layers

Create in Edit > Project Settings > Tags and Layers > Sorting Layers:

| Order | Name | Contents |
|-------|------|----------|
| 0 | Background | Snow texture, distant mountains |
| 1 | Terrain | Tile ground sprites |
| 2 | Obstacles | Trees, rocks, cabins |
| 3 | Gates | Slalom gate poles |
| 4 | Player | Skier sprite |
| 5 | Effects | Particles, speed lines |
| 6 | UI | HUD elements (use Canvas sorting) |

---

## Section 5: Sprite Specifications

### Universal Settings

| Setting | Value |
|---------|-------|
| Pixels Per Unit | 16 |
| Filter Mode | Point (no filter) |
| Compression | None |
| Sprite Mode | Single or Multiple (for sheets) |
| Pivot | Center (unless noted) |

### Sprite Dimensions

| Sprite | Size (pixels) | Notes |
|--------|---------------|-------|
| Skier (all frames) | 16x24 | Tall to show stance |
| Small Tree | 16x24 | |
| Large Tree | 24x32 | |
| Rock | 16x16 | |
| Cabin | 32x32 | |
| Gate Pole | 8x32 | Single pole |
| Gate Flag | 16x16 | Attached to pole |
| Ramp | 32x16 | Wide, low profile |
| Tile Background | 320x180 | Full screen chunk |

### Collider Sizing

Colliders should be smaller than visual sprites for "forgiving" feel:

| Sprite | Collider Size | Collider Type |
|--------|---------------|---------------|
| Skier | 8x8 | Circle (radius 4) |
| Small Tree | 8x8 | Circle |
| Large Tree | 12x12 | Circle |
| Rock | 10x10 | Circle |
| Cabin | 24x24 | Box |
| Gate | 4x32 | Box (thin trigger) |

---

## Section 6: Color Palette

### Primary Palette (The "Windbreaker")

| Name | Hex | RGB | Usage |
|------|-----|-----|-------|
| Hot Pink | #FF1493 | 255, 20, 147 | Accents, UI highlights, gate flags |
| Electric Blue | #00FFFF | 0, 255, 255 | Speed effects, UI borders |
| Bright Yellow | #FFD700 | 255, 215, 0 | Warning elements, timer |
| Mint Green | #00FF7F | 0, 255, 127 | Success states, flow meter |
| Snow White | #FFFAFA | 255, 250, 250 | Snow, backgrounds |

### Secondary Palette

| Name | Hex | RGB | Usage |
|------|-----|-----|-------|
| Deep Purple | #9400D3 | 148, 0, 211 | Shadows, night mode |
| Sunset Orange | #FF4500 | 255, 69, 0 | Danger, crash effects |
| Sky Blue | #87CEEB | 135, 206, 235 | Background gradient top |
| Pine Green | #228B22 | 34, 139, 34 | Trees |
| Rock Gray | #696969 | 105, 105, 105 | Rocks, obstacles |
| Cabin Brown | #8B4513 | 139, 69, 19 | Cabins |

### UI Palette

| Element | Color | Hex |
|---------|-------|-----|
| Timer Text | Electric Blue | #00FFFF |
| Timer Shadow | Deep Purple | #9400D3 |
| Speed Text | Hot Pink | #FF1493 |
| Background Panel | Black 80% | #000000CC |
| Border | Electric Blue | #00FFFF |

---

## Section 7: Animation Specifications

### Skier Animations

| Animation | Frames | Duration | Loop |
|-----------|--------|----------|------|
| Idle (standing) | 1 | N/A | No |
| Skiing (moving) | 2 | 0.2s total | Yes |
| Tucking | 1 | N/A | No |
| Turning Left | 2 | 0.15s total | No |
| Turning Right | 2 | 0.15s total | No |
| Crash | 4 | 0.4s total | No |
| Recovery | 3 | 0.3s total | No |
| Airborne | 1 | N/A | No |
| Spin (360) | 4 | 0.4s total | No |

### Skier Sprite Sheet Layout

```
Row 0: Idle, Ski1, Ski2, Tuck
Row 1: TurnL1, TurnL2, TurnR1, TurnR2
Row 2: Crash1, Crash2, Crash3, Crash4
Row 3: Recover1, Recover2, Recover3, Air
Row 4: Spin1, Spin2, Spin3, Spin4
```

Total sheet size: 64x120 pixels (4 columns x 5 rows, 16x24 each)

### Environment Animations

| Animation | Frames | Duration | Loop |
|-----------|--------|----------|------|
| Gate Flag Wave | 2 | 0.3s | Yes |
| Tree Sway (optional) | 2 | 0.5s | Yes |

---

## Section 8: Audio Specifications

### Sound Events

| Event | Trigger | Priority |
|-------|---------|----------|
| ski_loop | Player moving | Low (background) |
| tuck_wind | Tucking while moving | Medium |
| turn_carve | Sharp turn input | Medium |
| crash_impact | Collision with crash obstacle | High |
| crash_recovery | Recovery complete | Medium |
| gate_pass | Through gate correctly | High |
| gate_miss | Missed gate | High |
| speed_boost | Trick landing bonus | Medium |
| finish_line | Cross finish | Critical |

### Volume Hierarchy

| Priority | Volume Range |
|----------|--------------|
| Critical | 1.0 |
| High | 0.8 |
| Medium | 0.5 |
| Low | 0.3 |

---

## Section 9: File Organization

### Sprite Files

```
Assets/Sprites/
├── Player/
│   └── skier_sheet.png       # 64x120, all skier animations
├── Obstacles/
│   ├── small_tree.png        # 16x24
│   ├── large_tree.png        # 24x32
│   ├── rock.png              # 16x16
│   └── cabin.png             # 32x32
├── Gates/
│   ├── gate_pole.png         # 8x32
│   └── gate_flag_sheet.png   # 32x16 (2 frames)
├── Environment/
│   ├── ramp.png              # 32x16
│   └── tile_snow.png         # 320x180
└── UI/
    └── (UI sprites as needed)
```

### Import Settings Script

Create `Assets/Editor/SpriteImportSettings.cs`:

```csharp
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

---

## Section 10: Automated Project Setup

> **For Claude:** Run this script FIRST after creating the Unity project. It configures all settings programmatically.

### Task: Create Project Setup Script

**Files:**
- Create: `Assets/Editor/ProjectSetup.cs`

**Step 1: Create the setup script**

```csharp
// Assets/Editor/ProjectSetup.cs
using UnityEngine;
using UnityEditor;
using System.Linq;

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

        // Layer 6: Player
        SetLayer(layers, 6, "Player");
        // Layer 7: Obstacle
        SetLayer(layers, 7, "Obstacle");
        // Layer 8: Gate
        SetLayer(layers, 8, "Gate");
        // Layer 9: Terrain
        SetLayer(layers, 9, "Terrain");
        // Layer 10: Trigger
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

        // Clear existing (except Default)
        while (sortingLayers.arraySize > 1)
        {
            sortingLayers.DeleteArrayElementAtIndex(sortingLayers.arraySize - 1);
        }

        // Add our layers
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
        // Set gravity to zero
        Physics2D.gravity = Vector2.zero;

        // Configure collision matrix
        // Player (6) collides with: Obstacle(7), Gate(8), Terrain(9), Trigger(10)
        // Nothing else collides with each other

        int playerLayer = 6;
        int obstacleLayer = 7;
        int gateLayer = 8;
        int terrainLayer = 9;
        int triggerLayer = 10;

        // First, disable all collisions for our custom layers
        for (int i = 6; i <= 10; i++)
        {
            for (int j = 6; j <= 10; j++)
            {
                Physics2D.IgnoreLayerCollision(i, j, true);
            }
        }

        // Enable Player collisions
        Physics2D.IgnoreLayerCollision(playerLayer, obstacleLayer, false);
        Physics2D.IgnoreLayerCollision(playerLayer, gateLayer, false);
        Physics2D.IgnoreLayerCollision(playerLayer, terrainLayer, false);
        Physics2D.IgnoreLayerCollision(playerLayer, triggerLayer, false);

        Debug.Log("Physics2D configured: Gravity=0, Player collides with Obstacle/Gate/Terrain/Trigger");
    }

    private static void SetupQualitySettings()
    {
        // Get current quality level settings
        // Note: Some settings require modifying QualitySettings.asset directly

        QualitySettings.pixelLightCount = 0;
        QualitySettings.anisotropicFiltering = AnisotropicFiltering.Disable;
        QualitySettings.antiAliasing = 0;
        QualitySettings.vSyncCount = 1;

        Debug.Log("Quality settings configured: No pixel lights, no AA, VSync on");
    }
}
```

**Step 2: Create the sprite import script**

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

**Step 3: Create camera setup script**

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

**Step 4: Create color palette constants**

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

**Step 5: Run setup after creating project**

1. Create Unity project (per core-game-implementation.md Task 1)
2. Create `Assets/Editor/` folder
3. Add the three Editor scripts above
4. Add `Assets/Scripts/Core/GameColors.cs`
5. In Unity: Menu > Ski Free Or Die > Setup Project
6. In Unity: Menu > Ski Free Or Die > Setup Main Camera

**Verification:**
- Check Edit > Project Settings > Tags and Layers - should show custom layers
- Check Edit > Project Settings > Physics 2D - gravity should be (0,0)
- Select Main Camera - orthographic size should be 5.625

---

## Summary

| Category | Key Value |
|----------|-----------|
| Reference Resolution | 320x180 |
| Pixels Per Unit | 16 |
| Orthographic Size | 5.625 |
| Skier Sprite | 16x24 |
| Primary Colors | Hot Pink, Electric Blue, Yellow, Mint, White |
| Collision | Player vs Everything; nothing else collides |

**Automation Scripts:**
- `Assets/Editor/ProjectSetup.cs` - One-click layer, physics, quality setup
- `Assets/Editor/SpriteImportSettings.cs` - Auto-configure imported sprites
- `Assets/Editor/CameraSetup.cs` - Configure main camera
- `Assets/Scripts/Core/GameColors.cs` - Color palette constants

**Usage:**
1. Create Unity project
2. Add Editor scripts
3. Run "Ski Free Or Die > Setup Project" from menu
4. Reference `GameColors` class for all color values
