using System;
using System.Collections.Generic;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Media.Imaging;

namespace WoWForeverAssistant;

public static class SpecializationIcons
{
    private static readonly Dictionary<string, Dictionary<string, string>> Files = new(StringComparer.OrdinalIgnoreCase)
    {
        ["Воин"] = new(StringComparer.OrdinalIgnoreCase) { ["Arms"] = "ability_warrior_savageblow", ["Fury"] = "ability_warrior_innerrage", ["Protection"] = "ability_warrior_defensivestance" },
        ["Паладин"] = new(StringComparer.OrdinalIgnoreCase) { ["Holy"] = "spell_holy_holybolt", ["Protection"] = "ability_paladin_shieldofthetemplar", ["Retribution"] = "spell_holy_auraoflight" },
        ["Охотник"] = new(StringComparer.OrdinalIgnoreCase) { ["Beast Mastery"] = "ability_hunter_bestialdiscipline", ["Marksmanship"] = "ability_hunter_focusedaim", ["Survival"] = "ability_hunter_camouflage" },
        ["Разбойник"] = new(StringComparer.OrdinalIgnoreCase) { ["Assassination"] = "ability_rogue_eviscerate", ["Combat"] = "ability_backstab", ["Subtlety"] = "ability_stealth" },
        ["Жрец"] = new(StringComparer.OrdinalIgnoreCase) { ["Discipline"] = "spell_holy_powerwordshield", ["Holy"] = "spell_holy_guardianspirit", ["Shadow"] = "spell_shadow_shadowwordpain" },
        ["Шаман"] = new(StringComparer.OrdinalIgnoreCase) { ["Elemental"] = "spell_nature_lightning", ["Enhancement"] = "spell_shaman_improvedstormstrike", ["Restoration"] = "spell_nature_magicimmunity" },
        ["Маг"] = new(StringComparer.OrdinalIgnoreCase) { ["Arcane"] = "spell_holy_magicalsentry", ["Fire"] = "spell_fire_firebolt02", ["Frost"] = "spell_frost_frostbolt02" },
        ["Чернокнижник"] = new(StringComparer.OrdinalIgnoreCase) { ["Affliction"] = "spell_shadow_deathcoil", ["Demonology"] = "spell_shadow_metamorphosis", ["Destruction"] = "spell_shadow_rainoffire" },
        ["Друид"] = new(StringComparer.OrdinalIgnoreCase) { ["Balance"] = "spell_nature_starfall", ["Feral"] = "ability_racial_bearform", ["Restoration"] = "spell_nature_healingtouch" },
    };

    public static ImageSource? Get(string className, string specialization)
    {
        if (!Files.TryGetValue(className, out var specs) ||
            !specs.TryGetValue(specialization?.Trim() ?? "", out var file))
            return null;
        try
        {
            var bmp = new BitmapImage();
            bmp.BeginInit();
            bmp.UriSource = new Uri("pack://application:,,,/Assets/SpecIcons/" + file + ".png", UriKind.Absolute);
            bmp.CacheOption = BitmapCacheOption.OnLoad;
            bmp.EndInit();
            bmp.Freeze();
            return bmp;
        }
        catch { return null; }
    }

    public static FrameworkElement Tile(string className, string specialization, int size = 34)
    {
        var icon = Get(className, specialization);
        if (icon != null)
            return new Image { Source = icon, Width = size, Height = size, Stretch = Stretch.UniformToFill };
        return new TextBlock {
            Text = "✦", FontSize = size * 0.65,
            Foreground = Brushes.LightBlue,
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center
        };
    }
}
