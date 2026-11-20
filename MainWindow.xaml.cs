using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Imaging;
using System.Linq;
using System.IO;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Shapes;
using System.Windows.Threading;
using WinForms = System.Windows.Forms;
using DrawingColor = System.Drawing.Color;
using WpfColor = System.Windows.Media.Color;

namespace WoWForeverAssistant;
public partial class MainWindow : Window
{
    private readonly GHubDriver driver = new();
    private readonly HotkeySettings hotkeySettings = HotkeySettings.Load();
    private GlobalHotkeys? globalHotkeys;
    private readonly List<RotationProfile> profiles;
    private readonly DispatcherTimer scanTimer = new() { Interval = TimeSpan.FromMilliseconds(20) };
    private readonly string[] classes = { "Воин", "Паладин", "Охотник", "Маг", "Жрец", "Разбойник", "Шаман", "Чернокнижник", "Друид" };
    private readonly string[] glyphs = { "⚔", "✦", "➶", "❄", "✧", "⚔", "ϟ", "☾", "♣" };
    private readonly string[] colors = { "#C79C6E", "#F58CBA", "#A3C564", "#63C0F1", "#E8E8E8", "#FFF468", "#0070DD", "#AD78E5", "#FF7D0A" };
    private string selectedClass = "Маг";
    private RotationProfile? current;
    private sealed class LastSelection
    {
        public string ClassName { get; set; } = "Маг";
        public int RotationIndex { get; set; } = -1;
    }
    private static string LastSelectionPath => System.IO.Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "WoWForeverAssistant", "last_selection.json");
    private void SaveLastSelection()
    {
        try
        {
            Directory.CreateDirectory(System.IO.Path.GetDirectoryName(LastSelectionPath)!);
            var state = new LastSelection { ClassName = selectedClass, RotationIndex = current == null ? -1 : profiles.IndexOf(current) };
            var temp = LastSelectionPath + ".tmp";
            File.WriteAllText(temp, JsonSerializer.Serialize(state));
            File.Move(temp, LastSelectionPath, true);
        }
        catch (Exception ex) { Write("Ошибка сохранения: " + ex.Message); }
    }
    private void RestoreLastSelection()
    {
        LastSelection? state = null;
        try
        {
            if (File.Exists(LastSelectionPath)) state = JsonSerializer.Deserialize<LastSelection>(File.ReadAllText(LastSelectionPath));
        }
        catch (Exception ex) { Write("Ошибка чтения профилей" + ": " + ex.Message); }
        string cls = state != null && classes.Contains(state.ClassName) ? state.ClassName : "Маг";
        SelectClass(cls);
        if (state != null && state.RotationIndex >= 0 && state.RotationIndex < profiles.Count)
        {
            var selected = profiles[state.RotationIndex];
            if (selected.ClassName == cls)
            {
                current = selected; RenderRotations(); RenderAbilities(); UpdateState();
            }
        }
    }
    private bool running, paused, busy, scanning, targetWasPresent, oneShotFired;
    private Ability? activeAbility;
    private HealAction? activeHeal;
    private long lastHealTicks = -1;
    private bool healLatched;
    private long lastHealDiagnosticTicks = -1;
    private string? lastMatch;
    private long lastActionTicks = -1;
    private int nextActionWaitMs;
    private static SolidColorBrush Brush(string hex) => (SolidColorBrush)new BrushConverter().ConvertFromString(hex)!;
    public MainWindow()
    {
        InitializeComponent();
        try { profiles = ProfileStore.Load(); } catch (Exception ex) { profiles = new(); EditorDialogs.Notice(this, L.T("Ошибка чтения профилей"), ex.Message); }
        // Legacy profiles did not store a class. Detect obvious English class names without
        // changing the profile file until the user saves an edit.
        foreach (var profile in profiles)
        {
            if (profile.ClassName != "Маг") continue;
            var mapping = new Dictionary<string,string>(StringComparer.OrdinalIgnoreCase) {
                ["Paladin"]="Паладин", ["Warrior"]="Воин", ["Hunter"]="Охотник",
                ["Priest"]="Жрец", ["Rogue"]="Разбойник", ["Shaman"]="Шаман",
                ["Warlock"]="Чернокнижник", ["Druid"]="Друид" };
            if (mapping.TryGetValue(profile.Name.Trim(), out var detected)) profile.ClassName = detected;
        }
        L.Changed += OnLanguageChanged;
        scanTimer.Tick += (_,_) => Scan();
        SourceInitialized += (_,_) => {
            globalHotkeys = new GlobalHotkeys(this, id => {
                switch(id) { case 1: _ = StartAsync(); break; case 2: Pause(); break; case 3: Stop(); break; case 4: AddAbility_Click(this,new RoutedEventArgs()); break; }
            });
            var warning=globalHotkeys.Apply(hotkeySettings); if(warning.Length>0) Write("Горячие клавиши: " + warning);
            RefreshHotkeyLabels();
        };
        Closed += (_,_) => { SaveLastSelection(); globalHotkeys?.Dispose(); Stop(); driver.Dispose(); };
        RenderClasses(); RestoreLastSelection(); OnLanguageChanged();
    }
    private void Ru_Click(object sender, RoutedEventArgs e) => L.Set("ru-RU");
    private void En_Click(object sender, RoutedEventArgs e) => L.Set("en-US");
    private void OnLanguageChanged()
    {
        L.TranslateTree(this);
        // Always assign static button captions from canonical Russian keys, not the current text.
        // This also fixes controls that were created while the UI was in English.
        AddRotationButton.Content=L.T("＋  Добавить ротацию");
        DuplicateRotationButton.Content=L.T("Дублировать");
        DeleteRotationButton.Content=L.T("Удалить ротацию");
        RenameRotationButton.Content=L.T("✎  Переименовать");
        PickRegionButton.Content=L.T("⌖  Выбрать область");
        AddAbilityButton.Content=L.T("＋  Добавить способность (F7)");
        AddHealbotButton.Content=L.T("＋  Добавить хилпот");
        TestButton.Content=L.T("Тест Win");
        HotkeysButton.Content=L.T("⚙ Горячие клавиши");
        RenderClasses(); RenderRotations(); RenderAbilities(); RefreshHotkeyLabels(); UpdateState();
        RenderLog();
        RuButton.Background=Brush(L.Language=="ru-RU"?"#205487":"#0E253D");
        EnButton.Background=Brush(L.Language=="en-US"?"#205487":"#0E253D");
        RuButton.BorderBrush=Brush(L.Language=="ru-RU"?"#6FC6FF":"#2A4A69");
        EnButton.BorderBrush=Brush(L.Language=="en-US"?"#6FC6FF":"#2A4A69");
    }
    // Store language-independent log events so switching languages also updates existing lines.
    private readonly List<(DateTime Time, string Kind, string Name, string Key)> logEvents = new();
    private void AddLog(string kind, string name, string key = "")
    {
        logEvents.Add((DateTime.Now, kind, name, key));
        if (logEvents.Count > 200) logEvents.RemoveAt(0);
        RenderLog();
    }
    private void Write(string text) => AddLog("error", text);
    private void LogAction(string name, string key) => AddLog("action", name, key);
    private void LogAmbiguous(string details) => AddLog("ambiguity", details);
    private void RenderLog()
    {
        LogText.Text = string.Join(Environment.NewLine, logEvents.Select(e =>
        {
            string message = e.Kind == "ambiguity"
                ? (L.Language == "ru-RU" ? "Неоднозначное совпадение: " : "Ambiguous match: ") + e.Name
                : e.Kind == "action"
                ? (L.Language == "ru-RU" ? "Обнаружено: " : "Detected: ") + (e.Name == "Камень здоровья" || e.Name == "Хилпот" ? L.T(e.Name) : SpellCatalog.DisplayName(selectedClass, e.Name)) +
                  (L.Language == "ru-RU" ? ". Нажатие: " : ". Key: ") + e.Key
                : (L.Language == "ru-RU" ? "Ошибка: " : "Error: ") + L.T(e.Name);
            return $"[{e.Time:HH:mm:ss}] {message}";
        }));
        LogText.ScrollToEnd();
    }
    private void Save()
    {
        try { ProfileStore.Save(profiles); } catch (Exception ex) { Write("Ошибка сохранения: " + ex.Message); EditorDialogs.Notice(this, L.T("Ошибка"), ex.Message); }
    }
    private void RenderClasses()
    {
        ClassList.Children.Clear();
        for (int i=0;i<classes.Length;i++)
        {
            string cls = classes[i], color = colors[i];
            string iconFile = cls switch {
                "Воин" => "warrior.jpg", "Паладин" => "paladin.jpg", "Охотник" => "Hunter.jpg",
                "Разбойник" => "rogue.jpg", "Жрец" => "Priest.jpg", "Шаман" => "Shaman.jpg",
                "Маг" => "Mage.jpg", "Чернокнижник" => "warlock.jpg", "Друид" => "druid.jpg", _ => "warrior.jpg"
            };
            var classIcon = new Ellipse { Width = 46, Height = 46, Stroke = Brush(color), StrokeThickness = 2,
                HorizontalAlignment = HorizontalAlignment.Left, Margin = new Thickness(0,0,10,0),
                Fill = new ImageBrush(new System.Windows.Media.Imaging.BitmapImage(new Uri("pack://application:,,,/Assets/" + iconFile, UriKind.Absolute))) {
                    Stretch = Stretch.UniformToFill
                } };
            var row = new Grid { Width = 158, HorizontalAlignment = HorizontalAlignment.Left };
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(53) });
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1,GridUnitType.Star) });
            Grid.SetColumn(classIcon,0); row.Children.Add(classIcon);
            var classLabel = new TextBlock { Text = L.T(cls), Foreground = Brush(cls == selectedClass ? "#FFFFFF" : "#B5C7DB"),
                FontSize = 12, FontWeight = FontWeights.SemiBold, VerticalAlignment = VerticalAlignment.Center,
                TextTrimming = TextTrimming.CharacterEllipsis, ToolTip = L.T(cls) };
            Grid.SetColumn(classLabel,1); row.Children.Add(classLabel);
            var button = new Button { Content = row, HorizontalContentAlignment = HorizontalAlignment.Left,
                HorizontalAlignment = HorizontalAlignment.Stretch, Padding = new Thickness(5,5,2,5),
                Background = Brush(cls == selectedClass ? "#205487" : "#0E253D"),
                BorderBrush = Brush(cls == selectedClass ? "#6FC6FF" : "#2A4A69"),
                Margin = new Thickness(0,0,0,7), Height = 60 };
            button.Click += (_,_) => { SelectClass(cls); SaveLastSelection(); };
            ClassList.Children.Add(button);
        }
    }
    private void SelectClass(string cls)
    {
        if (running) Stop(); selectedClass = cls; RenderClasses();
        current = profiles.FirstOrDefault(p => p.ClassName == cls); RenderRotations(); RenderAbilities(); UpdateState();
    }
    private void RenderRotations()
    {
        RotationList.Children.Clear();
        foreach (var p in profiles.Where(p => p.ClassName == selectedClass))
        {
            var panel = new StackPanel { Orientation = Orientation.Horizontal };
            panel.Children.Add(new Border { Width = 38, Height = 38, Background = Brush("#164E80"), CornerRadius = new CornerRadius(7), Margin = new Thickness(0,0,9,0), Child = SpecializationIcons.Tile(p.ClassName, p.Specialization, 38) });
            panel.Children.Add(new TextBlock { Text = p.Name, TextTrimming = TextTrimming.CharacterEllipsis, Width = 139, Foreground = System.Windows.Media.Brushes.White, VerticalAlignment = VerticalAlignment.Center, FontSize = 14 });
            var button = new Button { Content = panel, Background = Brush(ReferenceEquals(p,current) ? "#205487" : "#0D223A"), BorderBrush = Brush(ReferenceEquals(p,current) ? "#68B9FF" : "#284A69"), HorizontalContentAlignment = HorizontalAlignment.Left, Padding = new Thickness(7), Margin = new Thickness(0,0,0,8), Height = 56 };
            button.Click += (_,_) => { if (running) Stop(); current = p; RenderRotations(); RenderAbilities(); UpdateState(); SaveLastSelection(); };
            RotationList.Children.Add(button);
        }
    }
    // Vector icons are drawn by WPF itself; no font glyph substitutions or external files.
    private static FrameworkElement ActionIcon(string kind)
    {
        string geometry = kind switch {
            "edit" => "M 4,17 L 4,20 7,20 18.5,8.5 15.5,5.5 Z M 14.5,6.5 L 17.5,9.5",
            "repick" => "M 3,19 L 17,5 M 13,5 L 19,5 19,11 M 3,13 L 3,19 9,19 M 6,7 L 8,9 M 8,5 L 6,11 M 4,9 L 10,7",
            "trash" => "M 5,7 L 19,7 M 9,4 L 15,4 M 7,7 L 8,20 16,20 17,7 M 11,10 L 11,17 M 14,10 L 14,17",
            _ => "M 3,12 L 21,12"
        };
        return new System.Windows.Shapes.Path {
            Data = Geometry.Parse(geometry), Stroke = Brush(kind=="trash" ? "#FF9A9A" : "#E2F2FF"),
            StrokeThickness = 1.8, StrokeStartLineCap = PenLineCap.Round,
            StrokeEndLineCap = PenLineCap.Round, StrokeLineJoin = PenLineJoin.Round,
            Fill = System.Windows.Media.Brushes.Transparent, Width = 22, Height = 22,
            Stretch = Stretch.Uniform, HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center
        };
    }
    private void RenderAbilities()
    {
        AbilityList.Children.Clear();
        RotationTitle.Text = current?.Name ?? L.T("Выбери ротацию");
        SpecTitleIcon.Source = current is { } selectedProfile
            ? SpecializationIcons.Get(selectedProfile.ClassName, selectedProfile.Specialization) : null;
        SpecTitleIcon.Visibility = SpecTitleIcon.Source != null ? Visibility.Visible : Visibility.Collapsed;
        RegionText.Text = current is { HasRegion: true } p ? L.T("Область: ") + $"{p.X},{p.Y} · {p.Width}×{p.Height}" : L.T("Область не выбрана");
        TargetText.Text = current?.HostileTarget is { } t ? L.T("Индикатор: ") + $"{t.ScreenX},{t.ScreenY} · RGB({t.R},{t.G},{t.B})" : L.T("Индикатор не настроен");
        RepeatInput.Text = (current?.RepeatMs ?? 200).ToString();
        if (current is not { } profile) return;
        foreach (var h in profile.HealActions ?? new List<HealAction>())
        {
            var row = new DockPanel { Margin = new Thickness(0,0,0,6), Height = 49 };
            var remove = new Button { Content = "✕", Width = 36, ToolTip = L.T("Удалить хилпот"), Margin = new Thickness(5,0,0,0) };
            remove.Click += (_,_) => { if(running)return; profile.HealActions.Remove(h); Save();RenderAbilities(); };
            DockPanel.SetDock(remove,Dock.Right);row.Children.Add(remove);
            var edit = new Button { Content = "✎", Width = 36, ToolTip = L.T("Изменить параметры"), Margin = new Thickness(5,0,0,0) };
            edit.Click += (_,_) => { if(running)return; if(EditorDialogs.Heal(this,h)) {Save();RenderAbilities();} };
            DockPanel.SetDock(edit,Dock.Right);row.Children.Add(edit);
            var label = new TextBlock { Text = "✚  " + L.T(h.Kind=="Stone"?"Камень здоровья":"Хилпот") + $"   RGB {h.R},{h.G},{h.B}   {h.Key}   {h.DelayMs} " + L.T("мс"), VerticalAlignment=VerticalAlignment.Center, Foreground=Brush("#F0D6A3"), TextTrimming=TextTrimming.CharacterEllipsis };
            row.Children.Add(label);
            AbilityList.Children.Add(new Border { Background=Brush("#204336"), Padding=new Thickness(9,3,9,3), CornerRadius=new CornerRadius(7), Margin=new Thickness(0,0,0,4), Child=row });
        }
        for (int i=0;i<profile.Abilities.Count;i++)
        {
            var a = profile.Abilities[i];
            var grid = new Grid { Margin = new Thickness(0,0,0,6), Height = 66 };
            foreach (var width in new[] { "36", "*", "94", "70", "82", "132" }) grid.ColumnDefinitions.Add(new ColumnDefinition { Width = width == "*" ? new GridLength(1,GridUnitType.Star) : new GridLength(double.Parse(width)) });
            var border = new Border { Background = Brush(i%2==0 ? "#102B47" : "#10253D"), BorderBrush = Brush("#2C4B68"), BorderThickness = new Thickness(1), CornerRadius = new CornerRadius(8), Child = grid };
            var number = new TextBlock { Text = (i+1).ToString(), Foreground = Brush("#A5C0DB"), VerticalAlignment = VerticalAlignment.Center, HorizontalAlignment = HorizontalAlignment.Center }; Grid.SetColumn(number,0); grid.Children.Add(number);
            var name = new StackPanel { Orientation = Orientation.Horizontal, VerticalAlignment = VerticalAlignment.Center };
            var icon = new Border { Width = 42, Height = 42, CornerRadius = new CornerRadius(6), BorderBrush = Brush("#B9975D"), BorderThickness = new Thickness(1), Background = new LinearGradientBrush(Brush("#225EA1").Color, Brush("#091C37").Color,90), Margin = new Thickness(0,0,9,0), Child = PaladinIcons.Tile(selectedClass, a.Name, 40) }; name.Children.Add(icon);
            var labels = new StackPanel { VerticalAlignment = VerticalAlignment.Center };
            labels.Children.Add(new TextBlock { Text = SpellCatalog.DisplayName(selectedClass,a.Name), TextTrimming = TextTrimming.CharacterEllipsis, FontWeight = FontWeights.SemiBold, FontSize = 14 });
            labels.Children.Add(new TextBlock { Text = $"RGB {a.R},{a.G},{a.B}", FontSize = 10, Foreground = Brush("#819CB6") }); name.Children.Add(labels);
            Grid.SetColumn(name,1); grid.Children.Add(name);
            var key = new TextBlock { Text = a.Key, Foreground = Brush("#F0D6A3"), VerticalAlignment = VerticalAlignment.Center, HorizontalAlignment = HorizontalAlignment.Center, FontWeight = FontWeights.Bold }; Grid.SetColumn(key,2); grid.Children.Add(key);
            var mode = new Button { Content = a.OneShot ? "①" : "⟳", ToolTip = a.OneShot ? L.T("Однократно — нажми для повтора") : L.T("Повтор — нажми для однократного"), FontSize = 25, FontWeight = FontWeights.Bold, Margin = new Thickness(4), Padding = new Thickness(2), MinWidth = 48 }; mode.Click += (_,_) => { if (running) return; a.OneShot = !a.OneShot; Save(); RenderAbilities(); }; Grid.SetColumn(mode,3); grid.Children.Add(mode);
            var delay = new TextBlock { Text = $"{a.DelayMs}" + (a.RandomExtraMs>0 ? $" +{a.RandomExtraMs}" : "") + L.T(" мс"), Foreground = Brush("#D0DBE6"), VerticalAlignment = VerticalAlignment.Center, HorizontalAlignment = HorizontalAlignment.Center }; Grid.SetColumn(delay,4); grid.Children.Add(delay);
            var actions = new StackPanel { Orientation = Orientation.Horizontal, VerticalAlignment = VerticalAlignment.Center, HorizontalAlignment = HorizontalAlignment.Center };
            var edit = new Button { Content = ActionIcon("edit"), FontSize = 18, Width = 38, Height = 38, Padding = new Thickness(0), ToolTip = L.T("Изменить параметры") }; edit.Click += (_,_) => { if (running) return; if (EditorDialogs.Ability(this,a,false,selectedClass)) { Save(); RenderAbilities(); } }; actions.Children.Add(edit);
            var repick = new Button { Content = ActionIcon("repick"), FontSize = 18, Width = 38, Height = 38, Padding = new Thickness(0), ToolTip = L.T("Выбрать новый пиксель"), Margin = new Thickness(3,0,0,0) }; repick.Click += (_,_) => RepickAbility(a); actions.Children.Add(repick);
            var remove = new Button { Content = ActionIcon("trash"), FontSize = 20, Width = 38, Height = 38, Padding = new Thickness(0), ToolTip = L.T("Удалить способность"), Margin = new Thickness(3,0,0,0), Foreground = Brush("#FF8B87") }; remove.Click += (_,_) => { if (running) return; profile.Abilities.Remove(a); Save(); RenderAbilities(); }; actions.Children.Add(remove);
            Grid.SetColumn(actions,5); grid.Children.Add(actions);
            AbilityList.Children.Add(border);
        }
    }
    private void AddRotation_Click(object sender,RoutedEventArgs e)
    {
        if (running) return; var result = EditorDialogs.Rotation(this,selectedClass); if (result is not { } v) return;
        current = new RotationProfile { ClassName = selectedClass, Name = v.name, Specialization = v.spec }; profiles.Add(current); Save(); RenderRotations(); RenderAbilities(); UpdateState();
    }
    private void DuplicateRotation_Click(object sender,RoutedEventArgs e)
    {
        if (running || current is not { } p) return;
        var name = EditorDialogs.Prompt(this,L.T("Название копии"),p.Name + L.T(" — копия")); if (name is null) return;
        var clone = System.Text.Json.JsonSerializer.Deserialize<RotationProfile>(System.Text.Json.JsonSerializer.Serialize(p))!; clone.Name = name;
        profiles.Add(clone); current = clone; Save(); RenderRotations(); RenderAbilities(); UpdateState();
    }
    private void DeleteRotation_Click(object sender,RoutedEventArgs e)
    {
        if (running || current is not { } p) return;
        if (!EditorDialogs.Confirm(this,L.T("Удаление ротации"),L.T("Удалить ротацию «") + p.Name + L.T("»?"))) return;
        profiles.Remove(p); current = profiles.FirstOrDefault(x=>x.ClassName==selectedClass); Save(); RenderRotations(); RenderAbilities(); UpdateState();
    }
    private void RenameRotation_Click(object sender,RoutedEventArgs e)
    {
        if (running || current is not { } p) return; var name = EditorDialogs.Prompt(this,L.T("Название ротации"),p.Name); if (name is null) return;
        p.Name=name; Save(); RenderRotations(); RenderAbilities();
    }
    private void RepeatInput_LostFocus(object sender,RoutedEventArgs e)
    {
        if (running || current is not { } p) return;
        if (int.TryParse(RepeatInput.Text,out int ms) && ms>=100 && ms<=2000) { p.RepeatMs=ms; Save(); }
        else RepeatInput.Text=p.RepeatMs.ToString();
    }
    private void PickRegion_Click(object sender,RoutedEventArgs e)
    {
        if (running || current is not { } p) return;
        if (p.Abilities.Count>0 && !EditorDialogs.Confirm(this,L.T("Смена области"),L.T("Выбор новой области удалит все образцы способностей. Продолжить?"))) return;
        Hide(); Thread.Sleep(200);
        try { using var picker = new ScreenPicker(WinForms.Screen.PrimaryScreen!.Bounds); if (picker.ShowDialog()!=WinForms.DialogResult.OK) return;
            var r=picker.SelectedRegion; p.X=r.X;p.Y=r.Y;p.Width=r.Width;p.Height=r.Height;p.Abilities.Clear();Save();RenderAbilities(); }
        catch(Exception ex){EditorDialogs.Notice(this, L.T("Ошибка"), ex.Message);Write(ex.Message);} finally {Show();Activate();}
    }
    private bool SamplePixel(RotationProfile p, out System.Drawing.Point point, out DrawingColor color, out List<AbilityPixel>? pattern)
    {
        point=default;color=default;pattern=null; Hide(); Thread.Sleep(200);
        try { using var picker=new ScreenPicker(new System.Drawing.Rectangle(p.X,p.Y,p.Width,p.Height),true);
            if (picker.ShowDialog()!=WinForms.DialogResult.OK) return false;
            if (!picker.CaptureNinePixelPattern()) { EditorDialogs.Notice(this,L.T("Ошибка"),"Выбери точку не ближе 3 пикселей к границе области / Select a point at least 3 pixels from the region edge."); return false; }
            point=picker.SelectedPixel;color=picker.SelectedColor;pattern=picker.SelectedPattern;return true; }
        catch(Exception ex){EditorDialogs.Notice(this, L.T("Ошибка"), ex.Message);Write(ex.Message);return false;} finally{Show();Activate();}
    }
    private void AddAbility_Click(object sender,RoutedEventArgs e)
    {
        if (running || current is not { HasRegion:true } p) return;
        if (!SamplePixel(p,out var point,out var color,out var pattern)) return;
        var a=new Ability { Name="Способность",X=point.X,Y=point.Y,R=color.R,G=color.G,B=color.B,Pattern=pattern };
        if (!EditorDialogs.Ability(this,a,true,selectedClass)) return;
        p.Abilities.Add(a);Save();RenderAbilities();
    }
    private void AddHealbot_Click(object sender,RoutedEventArgs e)
    {
        if (running || current is not { } p) return;
        if (p.HealRegion is not { IsValid:true })
        {
            EditorDialogs.Notice(this,L.T("Область хилпота"),L.T("Выбери область индикатора хилпота или камня здоровья."));
            Hide();Thread.Sleep(200);
            try {
                using var picker=new ScreenPicker(WinForms.SystemInformation.VirtualScreen);
                if(picker.ShowDialog()!=WinForms.DialogResult.OK)return;
                var r=picker.SelectedRegion;
                p.HealRegion=new HealRegion { X=r.X,Y=r.Y,Width=r.Width,Height=r.Height };
                Save();
            } catch(Exception ex){EditorDialogs.Notice(this,L.T("Ошибка"),ex.Message);return;}
            finally{Show();Activate();}
        }
        var region=p.HealRegion!;
        Hide();Thread.Sleep(200);
        System.Drawing.Point point; DrawingColor color;
        try {
            using var picker=new ScreenPicker(new System.Drawing.Rectangle(region.X,region.Y,region.Width,region.Height),true);
            if(picker.ShowDialog()!=WinForms.DialogResult.OK)return;
            point=picker.SelectedPixel;color=picker.SelectedColor;
        } catch(Exception ex){EditorDialogs.Notice(this,L.T("Ошибка"),ex.Message);return;}
        finally{Show();Activate();}
        var action=new HealAction { X=point.X,Y=point.Y,R=color.R,G=color.G,B=color.B };
        if(!EditorDialogs.Heal(this,action))return;
        p.HealActions ??=new();p.HealActions.Add(action);Save();RenderAbilities();
        
    }
    private void RepickAbility(Ability a)
    {
        if (running || current is not { HasRegion:true } p) return;
        if (!SamplePixel(p,out var point,out var color,out var pattern)) return;
        a.X=point.X;a.Y=point.Y;a.R=color.R;a.G=color.G;a.B=color.B;a.Pattern=pattern;Save();RenderAbilities();
    }
    private void PickTarget_Click(object sender,RoutedEventArgs e)
    {
        if (running || current is not { } p) return;
        EditorDialogs.Notice(this,L.T("Настройка цели"),L.T("Выбери пиксель индикатора, который имеет заданный цвет только при живой враждебной цели."));
        Hide(); Thread.Sleep(200);
        try { var bounds=WinForms.SystemInformation.VirtualScreen; using var picker=new ScreenPicker(bounds,true);
            if (picker.ShowDialog()!=WinForms.DialogResult.OK) return;var c=picker.SelectedColor;
            p.HostileTarget=new TargetIndicator { ScreenX=bounds.X+picker.SelectedPixel.X,ScreenY=bounds.Y+picker.SelectedPixel.Y,R=c.R,G=c.G,B=c.B };
            Save();RenderAbilities();UpdateState(); }
        catch(Exception ex){EditorDialogs.Notice(this, L.T("Ошибка"), ex.Message);}finally{Show();Activate();}
    }
    private async Task ConnectAsync()
    {
        busy=true;UpdateState();
        try { var message=await Task.Run(driver.Connect); }
        catch(Exception ex){Write("Подключение: " + ex.Message);EditorDialogs.Notice(this, "LazyG", L.T("Не удалось подключить систему ввода. Проверь установку компонента и журнал диагностики."));}
        finally{busy=false;UpdateState();}
    }
    private async void Start_Click(object sender,RoutedEventArgs e) => await StartAsync();
    private async Task StartAsync()
    {
        if (running || busy || current is not { HostileTarget:not null } p || (!p.HasRegion && p.HealActions.Count==0) || (p.Abilities.Count==0 && p.HealActions.Count==0)) return;
        // The virtual bus can remain available after the G HUB application exits.
        // Require the G HUB application itself before starting the rotation.
        bool gHubRunning;
        try
        {
            // G HUB may run through its tray/agent process without lghub.exe remaining active.
            // Process names are specified without the .exe suffix.
            gHubRunning = false;
            foreach (var name in new[] { "lghub", "lghub_system_tray", "lghub_agent" })
            {
                var processes = Process.GetProcessesByName(name);
                try { if (processes.Length > 0) gHubRunning = true; }
                finally { foreach (var process in processes) process.Dispose(); }
                if (gHubRunning) break;
            }
        }
        catch (Exception ex)
        {
            Write("Ошибка проверки Logitech G HUB: " + ex.Message);
            EditorDialogs.Notice(this, L.T("Ошибка"), L.T("Не удалось проверить запуск Logitech G HUB."), "Выход");
            return;
        }
        if (!gHubRunning)
        {
            var message = L.T("Для запуска ротации включите Logitech G HUB.");
            Write("Для запуска ротации включите Logitech G HUB.");
            EditorDialogs.Notice(this, L.T("Ошибка"), message, "Выход");
            return;
        }
        if (!driver.Connected) await ConnectAsync(); if (!driver.Connected) return;
        if (p.Abilities.Any(a=>!GHubKeys.TryParse(a.Key,out _,out _)) || p.HealActions.Any(a=>!GHubKeys.TryParse(a.Key,out _,out _))) {EditorDialogs.Notice(this,L.T("Ошибка"),L.T("Некорректная клавиша в ротации."));return;}
        running=true;paused=false;targetWasPresent=false;ResetRecognition();scanTimer.Start();UpdateState();
    }
    private void Pause_Click(object sender,RoutedEventArgs e) => Pause();
    private void Stop_Click(object sender,RoutedEventArgs e) => Stop();
    private void Pause(){if(!running)return;paused=!paused;ResetRecognition();UpdateState();}
    private void Stop(){scanTimer.Stop();running=false;paused=false;ResetRecognition();UpdateState();}
    private async void Test_Click(object sender,RoutedEventArgs e)
    {
        if(!running || busy || !driver.Connected)return;
        busy=true;UpdateState();try{await Task.Run(driver.TestWin);}
        catch(Exception ex){Write("Ошибка теста: " + ex.Message);EditorDialogs.Notice(this, L.T("Ошибка"), ex.Message);}finally{busy=false;UpdateState();}
    }
    private void UpdateState()
    {
        StartButton.IsEnabled=!running && !busy && current is { HostileTarget:not null } q && ((q.HasRegion && q.Abilities.Count>0) || q.HealActions.Count>0);
        PauseButton.IsEnabled=running;StopButton.IsEnabled=running;TestButton.IsEnabled=running && driver.Connected && !busy;
        ConnectionText.Text=driver.Connected ? L.T("● Система ввода готова") : L.T("○ Подключение при запуске");
        PauseButton.Content = paused ? L.T("▶  Продолжить (") + hotkeySettings.Pause + ")" : L.T("⏸  Пауза (") + hotkeySettings.Pause + ")";
        PauseButton.Background = Brush(paused ? "#236747" : "#17314E");
        PauseButton.BorderBrush = Brush(paused ? "#50C991" : "#395A7A");
        StateText.Text=running ? (paused ? L.T("● Пауза") : L.T("● Ротация работает")) : L.T("○ Остановлено");
        StateText.Foreground = Brush(!running ? "#A9BDD3" : paused ? "#FF5C61" : "#43D991");
        StateText.FontWeight = running ? FontWeights.Bold : FontWeights.Normal;
        FooterState.Text=running ? L.T("● Активная ротация: ") + current?.Name : L.T("● Готово к настройке");
    }
    private void ResetRecognition(){lastMatch=null;lastActionTicks=-1;nextActionWaitMs=0;activeAbility=null;oneShotFired=false;activeHeal=null;lastHealTicks=-1;healLatched=false;lastHealDiagnosticTicks=-1;}
    private void Scan()
    {
        if(!running||paused||scanning||current is not { } p)return;scanning=true;
        try
        {
            if(p.HostileTarget is not { } indicator){ResetRecognition();return;}
            using var pixel=new Bitmap(1,1,System.Drawing.Imaging.PixelFormat.Format32bppArgb);
            using(var g=Graphics.FromImage(pixel))g.CopyFromScreen(indicator.ScreenX,indicator.ScreenY,0,0,new System.Drawing.Size(1,1));
            bool hostile=indicator.Matches(pixel.GetPixel(0,0));
            if(!hostile){targetWasPresent=false;ResetRecognition();return;}
            targetWasPresent=true;
            // Heal region is sampled first. A matching heal action always preempts the main rotation.
            if (p.HealRegion is { IsValid:true } hr && p.HealActions is { Count:>0 })
            {
                using var healBitmap=new Bitmap(hr.Width,hr.Height,System.Drawing.Imaging.PixelFormat.Format32bppArgb);
                using(var hg=Graphics.FromImage(healBitmap))hg.CopyFromScreen(hr.X,hr.Y,0,0,healBitmap.Size);
                var healMatches=p.HealActions.Where(h=>h.X>=0&&h.Y>=0&&h.X<hr.Width&&h.Y<hr.Height&&h.Matches(healBitmap.GetPixel(h.X,h.Y),p.Tolerance)).ToList();
                if(healMatches.Count>1){if(lastMatch!="HEAL_AMBIGUOUS")Write("Неоднозначное совпадение хилпота.");lastMatch="HEAL_AMBIGUOUS";return;}
                if(healMatches.Count==1)
                {
                    var h=healMatches[0];
                    if(!ReferenceEquals(activeHeal,h)){activeHeal=h;healLatched=false;lastHealTicks=Stopwatch.GetTimestamp();}
                    if(!healLatched && Stopwatch.GetElapsedTime(lastHealTicks).TotalMilliseconds>=h.DelayMs && GHubKeys.TryParse(h.Key,out var hm,out var hk))
                    {
                        // One press per appearance; never spam a potion while the icon stays lit.
                        driver.TapKey(hm,hk);healLatched=true;lastHealTicks=Stopwatch.GetTimestamp();
                        LogAction(h.Kind=="Stone"?"Камень здоровья":"Хилпот", h.Key);
                    }
                    return;
                }
                activeHeal=null;healLatched=false;lastHealTicks=-1;
            }
            if(!p.HasRegion || p.Abilities.Count==0)return;
            using var bitmap=new Bitmap(p.Width,p.Height,System.Drawing.Imaging.PixelFormat.Format32bppArgb);
            using(var g=Graphics.FromImage(bitmap))g.CopyFromScreen(p.X,p.Y,0,0,bitmap.Size);
            var matches=p.Abilities.Where(a=>a.Matches(bitmap,p.Tolerance)).ToList();
            if(matches.Count!=1)
            {
                if(matches.Count>1 && lastMatch!="AMBIGUOUS")
                {
                    // Capture the exact matched samples once per conflict, without changing rotation behavior.
                    var details = string.Join("; ", matches.Select(a =>
                    {
                        var actual = bitmap.GetPixel(a.X,a.Y);
                        return $"{SpellCatalog.DisplayName(selectedClass,a.Name)} ({a.X},{a.Y}) RGB({a.R},{a.G},{a.B}) -> RGB({actual.R},{actual.G},{actual.B})";
                    }));
                    LogAmbiguous($"{matches.Count}. {details}");
                }
                lastMatch=matches.Count>1?"AMBIGUOUS":null;
                return;
            }
            var a=matches[0];if(!ReferenceEquals(activeAbility,a)){activeAbility=a;oneShotFired=false;lastActionTicks=-1;nextActionWaitMs=0;}
            if(a.OneShot&&oneShotFired)return;
            long now=Stopwatch.GetTimestamp();int wait=nextActionWaitMs;
            if(lastActionTicks>=0&&Stopwatch.GetElapsedTime(lastActionTicks,now).TotalMilliseconds<wait)return;
            if(!GHubKeys.TryParse(a.Key,out var modifier,out var usage))return;
            driver.TapKey(modifier,usage);if(a.OneShot)oneShotFired=true;lastActionTicks=Stopwatch.GetTimestamp();
            nextActionWaitMs=Math.Max(p.RepeatMs,a.DelayMs+Random.Shared.Next(0,Math.Clamp(a.RandomExtraMs,0,5000)+1));
            LogAction(a.Name, a.Key);lastMatch=a.Name;
        }
        catch(Exception ex){Write("Ошибка сканирования: " + ex.Message);Stop();}
        finally{scanning=false;}
    }
    private void RefreshHotkeyLabels()
    {
        StartButton.Content = L.T("▶  ЗАПУСТИТЬ (") + hotkeySettings.Start + ")";
        PauseButton.Content = L.T("⏸  Пауза (") + hotkeySettings.Pause + ")";
        StopButton.Content = L.T("■  Стоп (") + hotkeySettings.Stop + ")";
    }
    private void Settings_Click(object sender, RoutedEventArgs e)
    {
        var result = EditorDialogs.Hotkeys(this,hotkeySettings);
        if (!result) return;
        hotkeySettings.Save();
        var warning=globalHotkeys?.Apply(hotkeySettings) ?? "";
        if(warning.Length>0) EditorDialogs.Notice(this,L.T("Горячие клавиши"),warning);
        RefreshHotkeyLabels();
    }
    private void OnKeyDown(object sender,System.Windows.Input.KeyEventArgs e) { }
}
