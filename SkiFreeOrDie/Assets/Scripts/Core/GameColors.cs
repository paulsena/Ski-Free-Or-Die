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
