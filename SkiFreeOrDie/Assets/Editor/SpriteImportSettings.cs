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
            importer.spriteImportMode = SpriteImportMode.Single;
            importer.spritePixelsPerUnit = 16;
            importer.filterMode = FilterMode.Point;
            importer.textureCompression = TextureImporterCompression.Uncompressed;
            importer.mipmapEnabled = false;
        }
    }
}
