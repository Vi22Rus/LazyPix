using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Input;
using WinForms = System.Windows.Forms;

namespace WoWForeverAssistant;

public sealed class EditorDialogs
{
    private static Window Dialog(string title, StackPanel content, double height = 340)
    {
        var w = new Window { Title = L.T(title), Width = 500, Height = height, MinWidth = 440, MinHeight = 260, WindowStartupLocation = WindowStartupLocation.CenterOwner,
            ResizeMode = ResizeMode.CanResize, Background = new SolidColorBrush(Color.FromRgb(12,29,49)), Foreground = Brushes.White, Content = content };
        content.Margin = new Thickness(24); return w;
    }
    private static TextBlock Label(string value) => new() { Text = L.T(value), Foreground = new SolidColorBrush(Color.FromRgb(233,193,123)), Margin = new Thickness(0,7,0,5) };
    private static TextBox Input(string value) => new() { Text = value, Margin = new Thickness(0,0,0,6) };
    private static Button OkButton(Window w) { var b = new Button { Content = L.T("Сохранить"), HorizontalAlignment = HorizontalAlignment.Right, Margin = new Thickness(0,14,0,0), MinWidth = 120 }; b.Click += (_,_) => { w.DialogResult = true; }; return b; }
    public static string? Prompt(Window owner, string title, string initial)
    {
        var content = new StackPanel(); content.Children.Add(Label(title)); var input = Input(initial); content.Children.Add(input);
        var w = Dialog(title, content, 320); w.Owner = owner; content.Children.Add(OkButton(w));
        return w.ShowDialog() == true && !string.IsNullOrWhiteSpace(input.Text) ? input.Text.Trim() : null;
    }
    public static (string spec,string name)? Rotation(Window owner, string className)
    {
        var options = className switch {
            "Маг" => new[] { "Frost", "Fire", "Arcane" }, "Воин" => new[] { "Arms", "Fury", "Protection" },
            "Паладин" => new[] { "Holy", "Protection", "Retribution" }, "Охотник" => new[] { "Beast Mastery", "Marksmanship", "Survival" },
            "Жрец" => new[] { "Discipline", "Holy", "Shadow" }, "Разбойник" => new[] { "Assassination", "Combat", "Subtlety" },
            "Шаман" => new[] { "Elemental", "Enhancement", "Restoration" }, "Чернокнижник" => new[] { "Affliction", "Demonology", "Destruction" },
            "Друид" => new[] { "Balance", "Feral", "Restoration" }, _ => new[] { "Default" } };
        var content = new StackPanel(); content.Children.Add(Label(L.T("Специализация")));
        var spec = new ComboBox { Background = new SolidColorBrush(Color.FromRgb(20,46,73)), Foreground = Brushes.White };
        foreach (var option in options)
        {
            var row = new StackPanel { Orientation = Orientation.Horizontal };
            row.Children.Add(SpecializationIcons.Tile(className, option, 28));
            row.Children.Add(new TextBlock { Text = option, Foreground = Brushes.White,
                VerticalAlignment = VerticalAlignment.Center, Margin = new Thickness(9,0,0,0) });
            spec.Items.Add(new ComboBoxItem { Tag = option, Content = row, Padding = new Thickness(3) });
        }
        spec.SelectedIndex = 0;
        content.Children.Add(spec);
        content.Children.Add(Label(L.T("Название ротации"))); var name = Input(options[0]); content.Children.Add(name);
        spec.SelectionChanged += (_,_) => {
            if (spec.SelectedItem is ComboBoxItem item && item.Tag is string selected)
                name.Text = selected;
        };
        var w = Dialog(L.T("Новая ротация — ") + className, content, 430); w.Owner = owner; content.Children.Add(OkButton(w));
        return w.ShowDialog() == true && !string.IsNullOrWhiteSpace(name.Text)
            && spec.SelectedItem is ComboBoxItem selectedItem && selectedItem.Tag is string chosenSpec
            ? (chosenSpec, name.Text.Trim()) : null;
    }
    public static bool Confirm(Window owner, string title, string message)
    {
        var panel = new StackPanel();
        panel.Children.Add(new TextBlock { Text = L.T(message), TextWrapping = TextWrapping.Wrap, Margin = new Thickness(0,8,0,22), FontSize = 14 });
        var buttons = new StackPanel { Orientation = Orientation.Horizontal, HorizontalAlignment = HorizontalAlignment.Right };
        var cancel = new Button { Content = L.T("Отмена"), MinWidth = 100, Margin = new Thickness(0,0,10,0) };
        var accept = new Button { Content = L.T("Подтвердить"), MinWidth = 120 };
        var w = Dialog(title, panel, 320); w.Owner = owner;
        cancel.Click += (_,_) => w.DialogResult = false;
        accept.Click += (_,_) => w.DialogResult = true;
        buttons.Children.Add(cancel); buttons.Children.Add(accept); panel.Children.Add(buttons);
        return w.ShowDialog() == true;
    }
    public static void Notice(Window owner, string title, string message, string? buttonLabel = null)
    {
        var panel = new StackPanel();
        panel.Children.Add(new TextBlock { Text = L.T(message), TextWrapping = TextWrapping.Wrap, Margin = new Thickness(0,8,0,20) });
        var w = Dialog(title, panel, 300); w.Owner = owner;
        if (buttonLabel is null) panel.Children.Add(OkButton(w));
        else
        {
            var close = new Button { Content = L.T(buttonLabel), HorizontalAlignment = HorizontalAlignment.Right, Margin = new Thickness(0,14,0,0), MinWidth = 120 };
            close.Click += (_,_) => w.DialogResult = true;
            panel.Children.Add(close);
        }
        w.ShowDialog();
    }
    public static bool Hotkeys(Window owner, HotkeySettings settings)
    {
        var panel = new StackPanel();
        panel.Children.Add(new TextBlock { Text = L.T("Горячие клавиши работают, даже когда открыта игра. Если комбинация занята другой программой, LazyPix сообщит об этом."), TextWrapping = TextWrapping.Wrap, Foreground = Brushes.LightSteelBlue, Margin = new Thickness(0,0,0,12) });
        TextBox Field(string label,string value) { panel.Children.Add(Label(label)); var box=Input(value);panel.Children.Add(box);return box; }
        var start=Field(L.T("Запуск"),settings.Start);var pause=Field(L.T("Пауза"),settings.Pause);var stop=Field(L.T("Стоп"),settings.Stop);var add=Field(L.T("Добавить способность"),settings.AddAbility);
        foreach (var field in new[]{start,pause,stop,add})
        {
            var capture = new Button { Content=L.T("Назначить кнопку мыши"), Margin=new Thickness(0,3,0,7), HorizontalAlignment=HorizontalAlignment.Left };
            capture.Click += (_,_) =>
            {
                var picker = new Window { Title=L.T("Нажмите кнопку мыши"), Width=360, Height=170, Owner=owner, WindowStartupLocation=WindowStartupLocation.CenterOwner, Background=new SolidColorBrush(Color.FromRgb(12,29,49)), Foreground=Brushes.White };
                picker.Content=new TextBlock { Text=L.T("Нажмите нужную кнопку мыши в этом окне."), Margin=new Thickness(20), TextWrapping=TextWrapping.Wrap };
                picker.PreviewMouseDown += (_,e) =>
                {
                    var button=e.ChangedButton switch { System.Windows.Input.MouseButton.Left=>"Mouse1", System.Windows.Input.MouseButton.Right=>"Mouse2", System.Windows.Input.MouseButton.Middle=>"Mouse3", System.Windows.Input.MouseButton.XButton1=>"Mouse4", System.Windows.Input.MouseButton.XButton2=>"Mouse5", _=>null };
                    if(button!=null) { field.Text=button; e.Handled=true; picker.Close(); }
                };
                picker.ShowDialog();
            };
            // Place the capture control immediately after its corresponding input.
            panel.Children.Insert(panel.Children.IndexOf(field)+1,capture);
        }
        var w=Dialog(L.T("Горячие клавиши"),panel,650);w.Owner=owner;
        var save=OkButton(w); panel.Children.Add(save);
        if(w.ShowDialog()!=true)return false;
        var vals=new[]{start.Text.Trim(),pause.Text.Trim(),stop.Text.Trim(),add.Text.Trim()};
        if(vals.Any(string.IsNullOrWhiteSpace)||vals.Distinct(StringComparer.OrdinalIgnoreCase).Count()!=4) { Notice(owner,L.T("Ошибка"),L.T("Горячие клавиши должны быть заполнены и различаться."));return false; }
        settings.Start=vals[0];settings.Pause=vals[1];settings.Stop=vals[2];settings.AddAbility=vals[3];return true;
    }
    public static bool Heal(Window owner, HealAction action)
    {
        var panel=new StackPanel();
        panel.Children.Add(Label(L.T("Тип лечения")));
        var kind=new ComboBox { Background=new SolidColorBrush(Color.FromRgb(20,46,73)),Foreground=Brushes.White,Margin=new Thickness(0,0,0,10) };
        kind.Items.Add(new ComboBoxItem { Content=L.T("Хилпот"),Tag="Potion" });
        kind.Items.Add(new ComboBoxItem { Content=L.T("Камень здоровья"),Tag="Stone" });
        kind.SelectedIndex=action.Kind=="Stone"?1:0;panel.Children.Add(kind);
        panel.Children.Add(Label(L.T("Клавиша")));
        var original=action.Key.ToUpperInvariant().Split('+',StringSplitOptions.TrimEntries|StringSplitOptions.RemoveEmptyEntries);
        var key=Input(original.LastOrDefault(x=>x!="CTRL"&&x!="SHIFT"&&x!="ALT")??"1");key.Width=130;
        var ctrl=new CheckBox { Content="Ctrl",IsChecked=original.Contains("CTRL"),Foreground=Brushes.White,Margin=new Thickness(12,6,12,0) };
        var shift=new CheckBox { Content="Shift",IsChecked=original.Contains("SHIFT"),Foreground=Brushes.White,Margin=new Thickness(0,6,0,0) };
        var alt=new CheckBox { Content="Alt",IsChecked=original.Contains("ALT"),Foreground=Brushes.White,Margin=new Thickness(12,6,0,0) };
        var keys=new StackPanel { Orientation=Orientation.Horizontal };keys.Children.Add(key);keys.Children.Add(ctrl);keys.Children.Add(shift);keys.Children.Add(alt);panel.Children.Add(keys);
        panel.Children.Add(Label(L.T("Дополнительная задержка (мс)")));
        var delay=Input(action.DelayMs.ToString());panel.Children.Add(delay);
        panel.Children.Add(new TextBlock { Text=$"RGB({action.R},{action.G},{action.B}) · ({action.X},{action.Y})",Foreground=Brushes.LightSteelBlue,Margin=new Thickness(0,8,0,0) });
        var w=Dialog(L.T("Настройка хилпота"),panel,410);w.Owner=owner;
        var save=new Button { Content=L.T("Сохранить"),MinWidth=120,HorizontalAlignment=HorizontalAlignment.Right,Margin=new Thickness(0,14,0,0) };
        save.Click+=(_,_)=>{
            var binding=(ctrl.IsChecked==true?"Ctrl+":"")+(shift.IsChecked==true?"Shift+":"")+(alt.IsChecked==true?"Alt+":"")+key.Text.Trim();
            if(!GHubKeys.TryParse(binding,out _,out _)||!int.TryParse(delay.Text,out int ms)||ms<0||ms>5000){Notice(w,L.T("Проверка данных"),L.T("Проверь клавишу и задержку 0–5000 мс."));return;}
            action.Kind=(string)((ComboBoxItem)kind.SelectedItem!).Tag;action.Key=binding;action.DelayMs=ms;w.DialogResult=true;
        };
        panel.Children.Add(save);return w.ShowDialog()==true;
    }
    public static bool Ability(Window owner, Ability ability, bool isNew, string className)
    {
        var panel = new StackPanel();
        var scroll = new ScrollViewer { VerticalScrollBarVisibility = ScrollBarVisibility.Auto, Content = panel, Margin = new Thickness(24) };
        panel.Children.Add(Label(L.T("Название способности — поиск по классу")));
        var name = Input(ability.Name == "Способность" ? "" : SpellCatalog.DisplayName(className,ability.Name));
        name.Height = 35; panel.Children.Add(name);
        var suggestions = new ListBox { MaxHeight = 115, Background = new SolidColorBrush(Color.FromRgb(20,46,73)), Foreground = Brushes.White, Visibility = Visibility.Collapsed };
        panel.Children.Add(suggestions);
        var spells = SpellCatalog.ForClass(className);
        name.TextChanged += (_,_) => {
            var typed = name.Text.Trim(); suggestions.Items.Clear();
            if (typed.Length == 0) { suggestions.Visibility = Visibility.Collapsed; return; }
            foreach(var spell in spells.Where(x => x.Contains(typed,StringComparison.OrdinalIgnoreCase) || SpellCatalog.DisplayName(className,x).Contains(typed,StringComparison.OrdinalIgnoreCase)).Take(8)) {
                var item = new ListBoxItem { Tag=spell, Padding=new Thickness(3) };
                var row = new StackPanel { Orientation=Orientation.Horizontal };
                row.Children.Add(PaladinIcons.Tile(className,spell,28));
                row.Children.Add(new TextBlock { Text=SpellCatalog.DisplayName(className,spell),Margin=new Thickness(8,4,0,0),Foreground=Brushes.White });
                item.Content=row; suggestions.Items.Add(item);
            }
            suggestions.Visibility = suggestions.Items.Count > 0 ? Visibility.Visible : Visibility.Collapsed;
        };
        suggestions.SelectionChanged += (_,_) => { if (suggestions.SelectedItem is ListBoxItem item && item.Tag is string spell) { name.Text = SpellCatalog.DisplayName(className,spell); suggestions.Visibility = Visibility.Collapsed; } };
        panel.Children.Add(new TextBlock { Text = L.T("Подсказки по классу или своё название; каталог пока неполный"), Foreground = Brushes.LightSteelBlue, FontSize = 11, Margin = new Thickness(0,3,0,8) });
        panel.Children.Add(Label(L.T("Клавиша")));
        var original = ability.Key.ToUpperInvariant().Split('+', StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries);
        var baseKey = original.LastOrDefault(x => x != "CTRL" && x != "SHIFT" && x != "ALT") ?? "1";
        var key = Input(baseKey); key.Width = 135;
        var ctrl = new CheckBox { Content = L.T("Ctrl"), IsChecked = original.Contains("CTRL"), Foreground = Brushes.White, Margin = new Thickness(12,6,12,0) };
        var shift = new CheckBox { Content = L.T("Shift"), IsChecked = original.Contains("SHIFT"), Foreground = Brushes.White, Margin = new Thickness(0,6,0,0) };
        var alt = new CheckBox { Content = "Alt", IsChecked = original.Contains("ALT"), Foreground = Brushes.White, Margin = new Thickness(12,6,0,0) };
        var keyRow = new StackPanel { Orientation = Orientation.Horizontal }; keyRow.Children.Add(key); keyRow.Children.Add(ctrl); keyRow.Children.Add(shift); keyRow.Children.Add(alt); panel.Children.Add(keyRow);
        var once = new CheckBox { Content = L.T("Использовать один раз до смены иконки"), IsChecked = ability.OneShot, Foreground = Brushes.White, Margin = new Thickness(0,12,0,4) }; panel.Children.Add(once);
        var delayRow = new StackPanel { Orientation = Orientation.Horizontal };
        var baseColumn = new StackPanel { Width = 190, Margin = new Thickness(0,0,12,0) };
        baseColumn.Children.Add(Label(L.T("Дополнительная задержка (мс)")));
        var delay = Input((isNew ? 200 : ability.DelayMs).ToString()); baseColumn.Children.Add(delay);
        var randomColumn = new StackPanel { Width = 190 };
        randomColumn.Children.Add(Label(L.T("Случайная добавка (мс)")));
        var randomExtra = Input((isNew ? 0 : ability.RandomExtraMs).ToString()); randomColumn.Children.Add(randomExtra);
        delayRow.Children.Add(baseColumn); delayRow.Children.Add(randomColumn); panel.Children.Add(delayRow);
        panel.Children.Add(new TextBlock { Text = L.T("Образец: ") + $"RGB({ability.R},{ability.G},{ability.B})  •  ({ability.X},{ability.Y})", Foreground = Brushes.LightSteelBlue, Margin = new Thickness(0,8,0,0) });
        var w = new Window { Title = isNew ? L.T("Новая способность") : L.T("Редактирование способности"), Width = 480, Height = 550, MinWidth = 420, MinHeight = 480, WindowStartupLocation = WindowStartupLocation.CenterOwner, Background = new SolidColorBrush(Color.FromRgb(12,29,49)), Foreground = Brushes.White, Owner = owner, Content = scroll };
        var save = new Button { Content = L.T("Сохранить"), HorizontalAlignment = HorizontalAlignment.Right, Margin = new Thickness(0,16,0,12), MinWidth = 140 };
        save.Click += (_,_) => {
            var binding = (ctrl.IsChecked == true ? "Ctrl+" : "") + (shift.IsChecked == true ? "Shift+" : "") + (alt.IsChecked == true ? "Alt+" : "") + key.Text.Trim();
            if (string.IsNullOrWhiteSpace(name.Text) || !GHubKeys.TryParse(binding, out _, out _) || !int.TryParse(delay.Text, out int d) || d < 0 || d > 5000 || !int.TryParse(randomExtra.Text, out int extra) || extra < 0 || extra > 5000) { Notice(w,L.T("Проверка данных"),L.T("Проверь название, клавишу и задержки 0–5000 мс.")); return; }
            ability.Name = SpellCatalog.CanonicalName(className,name.Text.Trim()); ability.Key = binding; ability.OneShot = once.IsChecked == true; ability.DelayMs = d; ability.RandomExtraMs = extra; w.DialogResult = true;
        };
        panel.Children.Add(save);
        return w.ShowDialog() == true;
    }
}
