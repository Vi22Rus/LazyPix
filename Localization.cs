using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text.Json;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;

namespace WoWForeverAssistant;
public static class L
{
    private static readonly Dictionary<string,string> english = Read("en-US");
    private static readonly Dictionary<string,Dictionary<string,string>> packs = new(StringComparer.OrdinalIgnoreCase);
    public static string[] AvailableLanguages => Assembly.GetExecutingAssembly().GetManifestResourceNames()
        .Where(x => x.StartsWith("WoWForeverAssistant.Localization.",StringComparison.Ordinal) && x.EndsWith(".json",StringComparison.Ordinal))
        .Select(x => x.Substring("WoWForeverAssistant.Localization.".Length).Replace(".json", ""))
        .OrderBy(x=>x).ToArray();
    public static string Language { get; private set; } = LoadLanguage();
    public static event Action? Changed;
    private static Dictionary<string,string> Read(string locale)
    {
        try {
            using var stream = Assembly.GetExecutingAssembly().GetManifestResourceStream("WoWForeverAssistant.Localization." + locale + ".json");
            if (stream != null) return JsonSerializer.Deserialize<Dictionary<string,string>>(stream) ?? new();
        } catch { }
        return new();
    }
    private static string LoadLanguage()
    {
        try { var file = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),"LazyG","language.txt");
              var lang = File.Exists(file) ? File.ReadAllText(file).Trim() : "ru-RU";
              return AvailableLanguages.Contains(lang,StringComparer.OrdinalIgnoreCase) ? lang : "ru-RU"; }
        catch { return "ru-RU"; }
    }
    public static void Set(string language)
    {
        if (!AvailableLanguages.Contains(language,StringComparer.OrdinalIgnoreCase)) return;
        Language = language;
        try { var dir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),"LazyG");
              Directory.CreateDirectory(dir); File.WriteAllText(Path.Combine(dir,"language.txt"),language); } catch { }
        Changed?.Invoke();
    }
    public static string T(string text)
    {
        if (Language == "ru-RU" || string.IsNullOrEmpty(text)) return text;
        if (!packs.TryGetValue(Language,out var dict)) { dict = Read(Language); packs[Language] = dict; }
        if (dict.TryGetValue(text,out var localized)) return localized;
        if (english.TryGetValue(text,out var exact)) return exact;
        foreach (var kv in (Language == "en-US" ? english : dict).OrderByDescending(x => x.Key.Length))
            if (kv.Key.Length >= 4 && text.Contains(kv.Key,StringComparison.Ordinal))
                text = text.Replace(kv.Key,kv.Value,StringComparison.Ordinal);
        return text;
    }
    // Normalize dynamically generated English captions back to canonical Russian keys.
    private static string Canonical(string value)
    {
        if (string.IsNullOrEmpty(value)) return value;
        foreach (var kv in english.OrderByDescending(x => x.Value.Length))
            if (!string.IsNullOrEmpty(kv.Value) && kv.Value.Length >= 4)
                value = value.Replace(kv.Value, kv.Key, StringComparison.Ordinal);
        return value;
    }
    private sealed class LocalizedOriginal
    {
        public string Value;
        public string Last;
        public LocalizedOriginal(string value) { Value = Canonical(value); Last = value; }
    }
    // Re-evaluate changed dynamic labels, but never treat our previous translation as source.
    public static void TranslateTree(DependencyObject root)
    {
        void Walk(DependencyObject item)
        {
            if (item is TextBlock tb)
            {
                var original = tb.Tag as LocalizedOriginal;
                if (original == null) { original = new LocalizedOriginal(tb.Text); tb.Tag = original; }
                else if (tb.Text != original.Last) original.Value = Canonical(tb.Text);
                tb.Text = T(original.Value);
                original.Last = tb.Text;
            }
            if (item is ContentControl c && c.Content is string content)
            {
                var original = c.Tag as LocalizedOriginal;
                if (original == null) { original = new LocalizedOriginal(content); c.Tag = original; }
                else if (content != original.Last) original.Value = Canonical(content);
                c.Content = T(original.Value);
                original.Last = (string)c.Content;
            }
            if (item is FrameworkElement f && f.ToolTip is string tooltip)
            {
                if (!tooltips.TryGetValue(f,out var orig)) orig = Canonical(tooltip);
                else if (tooltip != T(orig)) orig = Canonical(tooltip);
                tooltips[f] = orig;
                f.ToolTip = T(orig);
            }
            for (int i=0;i<VisualTreeHelper.GetChildrenCount(item);i++) Walk(VisualTreeHelper.GetChild(item,i));
        }
        Walk(root);
    }
    private static readonly Dictionary<FrameworkElement,string> tooltips = new();
}
