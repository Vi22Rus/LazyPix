using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Reflection;
namespace WoWForeverAssistant;
public static class SpellCatalog
{
    private sealed record Entry(string ClassName,string English,string Russian,int Id,string Icon);
    private static readonly Lazy<List<Entry>> Entries = new(() => {
        using var stream = Assembly.GetExecutingAssembly().GetManifestResourceStream("WoWForeverAssistant.Data.spells_ru_en.json") ?? throw new InvalidOperationException("Spell catalog missing");
        using var doc = JsonDocument.Parse(stream);
        return doc.RootElement.GetProperty("spells").EnumerateArray().Select(x => new Entry(
            x.GetProperty("class").GetString() ?? "",
            x.GetProperty("name_en").GetString() ?? "",
            x.GetProperty("name_ru").GetString() ?? "",
            x.GetProperty("spell_id").GetInt32(),
            x.GetProperty("icon_file").GetString() ?? "")).ToList();
    });
    private static Entry? Find(string className,string abilityName) {
        var name = abilityName.Trim();
        return Entries.Value.FirstOrDefault(x => x.ClassName == className &&
            string.Equals(x.Russian,name,StringComparison.OrdinalIgnoreCase))
            ?? Entries.Value.FirstOrDefault(x => x.ClassName == className &&
            string.Equals(x.English,name,StringComparison.OrdinalIgnoreCase));
    }
    // Persist canonical English spell names: changing UI language must not change saved profiles.
    public static string CanonicalName(string className,string abilityName) => Find(className,abilityName)?.English ?? abilityName;
    public static string DisplayName(string className,string abilityName) {
        var entry=Find(className,abilityName);
        return entry==null ? abilityName : L.Language=="ru-RU" ? entry.Russian : entry.English;
    }
    public static string? RussianName(string className,string abilityName) => Find(className,abilityName)?.Russian;
    public static string[] ForClass(string className) => Entries.Value.Where(x=>x.ClassName==className)
        .Select(x=>x.English).Distinct(StringComparer.OrdinalIgnoreCase)
        .OrderBy(x=>DisplayName(className,x),StringComparer.CurrentCultureIgnoreCase).ToArray();
    public static string? IconFile(string className,string abilityName) => Find(className,abilityName)?.Icon;
}
