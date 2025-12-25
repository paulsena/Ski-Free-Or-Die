// Assets/Scripts/Yeti/YetiZone.cs
public enum YetiZone
{
    Safe,       // > 50 units behind player
    Warning,    // 30-50 units behind
    Danger,     // 10-30 units behind
    Critical    // < 10 units behind (about to catch)
}
