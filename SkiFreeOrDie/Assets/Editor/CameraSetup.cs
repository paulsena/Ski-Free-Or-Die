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
