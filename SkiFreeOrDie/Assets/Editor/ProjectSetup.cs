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
