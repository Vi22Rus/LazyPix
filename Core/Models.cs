using System.Drawing;
using System.Text.Json;

namespace WoWForeverAssistant;
public sealed class RotationProfile
{
    public string Name { get; set; } = "Новая ротация";
    public string ClassName { get; set; } = "Маг";
    public string Specialization { get; set; } = "Frost";
    public int X { get; set; }
    public int Y { get; set; }
    public int Width { get; set; }
    public int Height { get; set; }
    public int Tolerance { get; set; } = 12;
    public int ScanMs { get; set; } = 20;
    public int RepeatMs { get; set; } = 200;
    public List<Ability> Abilities { get; set; } = new();
    public HealRegion? HealRegion { get; set; }
    public List<HealAction> HealActions { get; set; } = new();
    public TargetIndicator? HostileTarget { get; set; }
    public bool HasRegion => Width > 0 && Height > 0;
}
public sealed class HealRegion
{
    public int X { get; set; }
    public int Y { get; set; }
    public int Width { get; set; }
    public int Height { get; set; }
    public bool IsValid => Width > 0 && Height > 0;
}
public sealed class HealAction
{
    // Stable identifiers independent of UI language.
    public string Kind { get; set; } = "Potion";
    public int X { get; set; }
    public int Y { get; set; }
    public int R { get; set; }
    public int G { get; set; }
    public int B { get; set; }
    public string Key { get; set; } = "1";
    public int DelayMs { get; set; } = 200;
    public bool Matches(Color c, int tolerance) => Math.Abs(c.R-R)<=tolerance && Math.Abs(c.G-G)<=tolerance && Math.Abs(c.B-B)<=tolerance;
}
public sealed class TargetIndicator
{
    public int ScreenX { get; set; }
    public int ScreenY { get; set; }
    public int R { get; set; }
    public int G { get; set; }
    public int B { get; set; }
    public int Tolerance { get; set; } = 8;
    public bool Matches(Color c) => Math.Abs(c.R - R) <= Tolerance && Math.Abs(c.G - G) <= Tolerance && Math.Abs(c.B - B) <= Tolerance;
}
public sealed class AbilityPixel
{
    public int OffsetX { get; set; }
    public int OffsetY { get; set; }
    public int R { get; set; }
    public int G { get; set; }
    public int B { get; set; }
    public bool Matches(Color c, int tolerance) => Math.Abs(c.R-R)<=tolerance && Math.Abs(c.G-G)<=tolerance && Math.Abs(c.B-B)<=tolerance;
}
public sealed class Ability
{
    public string Name { get; set; } = "Способность";
    public int X { get; set; }
    public int Y { get; set; }
    public int R { get; set; }
    public int G { get; set; }
    public int B { get; set; }
    public List<AbilityPixel>? Pattern { get; set; }
    public string Key { get; set; } = "1";
    public bool OneShot { get; set; } = false;
    public int DelayMs { get; set; } = 200;
    public int RandomExtraMs { get; set; } = 0;
    public override string ToString() => $"{Name} | ({X},{Y}) RGB({R},{G},{B}) | {Key}{(OneShot ? " | ОДИН РАЗ" : " | повтор")}";
    public bool Matches(Color c, int tolerance) => Math.Abs(c.R - R) <= tolerance && Math.Abs(c.G - G) <= tolerance && Math.Abs(c.B - B) <= tolerance;
    public bool Matches(Bitmap bitmap, int tolerance)
    {
        if (Pattern is not { Count: 9 }) return X >= 0 && Y >= 0 && X < bitmap.Width && Y < bitmap.Height && Matches(bitmap.GetPixel(X,Y), tolerance);
        foreach (var pixel in Pattern)
        {
            int x = X + pixel.OffsetX, y = Y + pixel.OffsetY;
            if (x < 0 || y < 0 || x >= bitmap.Width || y >= bitmap.Height || !pixel.Matches(bitmap.GetPixel(x,y), tolerance)) return false;
        }
        return true;
    }
}
public static class ProfileStore
{
    public static string PathName => Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "WoWForeverAssistant", "profiles.json");
    public static List<RotationProfile> Load()
    {
        try { return File.Exists(PathName) ? JsonSerializer.Deserialize<List<RotationProfile>>(File.ReadAllText(PathName)) ?? new() : new(); }
        catch (Exception ex) { throw new InvalidDataException($"Не удалось прочитать {PathName}: {ex.Message}", ex); }
    }
    public static void Save(List<RotationProfile> profiles)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(PathName)!);
        var temp = PathName + ".tmp";
        File.WriteAllText(temp, JsonSerializer.Serialize(profiles, new JsonSerializerOptions { WriteIndented = true }));
        File.Move(temp, PathName, true);
    }
}
