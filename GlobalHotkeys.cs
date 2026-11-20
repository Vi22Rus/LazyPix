using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Interop;
using System.Windows.Input;
using System.Text.Json;
using System.Diagnostics;

namespace WoWForeverAssistant;
public sealed class HotkeySettings
{
    public string Start { get; set; } = "F11";
    public string Pause { get; set; } = "F6";
    public string Stop { get; set; } = "F8";
    public string AddAbility { get; set; } = "F7";
    public static string FilePath => Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),"WoWForeverAssistant","hotkeys.json");
    public static HotkeySettings Load() { try { return File.Exists(FilePath) ? JsonSerializer.Deserialize<HotkeySettings>(File.ReadAllText(FilePath)) ?? new() : new(); } catch { return new(); } }
    public void Save() { Directory.CreateDirectory(Path.GetDirectoryName(FilePath)!); File.WriteAllText(FilePath,JsonSerializer.Serialize(this,new JsonSerializerOptions { WriteIndented = true })); }
}
public sealed class GlobalHotkeys : IDisposable
{
    private const int WM_HOTKEY = 0x0312;
    [DllImport("user32.dll", SetLastError=true)] private static extern bool RegisterHotKey(IntPtr hwnd, int id, uint modifiers, uint key);
    [DllImport("user32.dll", SetLastError=true)] private static extern bool UnregisterHotKey(IntPtr hwnd, int id);
    private const int WH_MOUSE_LL=14, WM_LBUTTONDOWN=0x0201, WM_RBUTTONDOWN=0x0204, WM_MBUTTONDOWN=0x0207, WM_XBUTTONDOWN=0x020B;
    private delegate IntPtr MouseProc(int code, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll",SetLastError=true)] private static extern IntPtr SetWindowsHookEx(int id, MouseProc callback, IntPtr module, uint threadId);
    [DllImport("user32.dll")] private static extern bool UnhookWindowsHookEx(IntPtr hook);
    [DllImport("user32.dll")] private static extern IntPtr CallNextHookEx(IntPtr hook,int code,IntPtr wParam,IntPtr lParam);
    [DllImport("kernel32.dll",CharSet=CharSet.Auto)] private static extern IntPtr GetModuleHandle(string? name);
    private readonly MouseProc mouseCallback;
    private IntPtr mouseHook;
    private readonly Dictionary<string,int> mouseBindings=new(StringComparer.OrdinalIgnoreCase);
    private readonly HashSet<int> mousePressed=new();
    private readonly IntPtr hwnd;
    private readonly HwndSource source;
    private readonly Action<int> handler;
    private readonly List<int> registered = new();
    public GlobalHotkeys(Window window, Action<int> handler)
    {
        hwnd = new WindowInteropHelper(window).Handle;
        source = HwndSource.FromHwnd(hwnd) ?? throw new InvalidOperationException("Не найдено окно LazyPix");
        this.handler = handler; source.AddHook(Hook);
        mouseCallback=MouseHook;
        mouseHook=SetWindowsHookEx(WH_MOUSE_LL,mouseCallback,GetModuleHandle(null),0);
    }
    private IntPtr Hook(IntPtr h, int msg, IntPtr w, IntPtr l, ref bool handled)
    {
        if (msg == WM_HOTKEY && registered.Contains(w.ToInt32())) { handler(w.ToInt32()); handled=true; }
        return IntPtr.Zero;
    }
    private IntPtr MouseHook(int code,IntPtr wParam,IntPtr lParam)
    {
        if(code>=0)
        {
            int message=wParam.ToInt32();
            string? button=message switch { WM_LBUTTONDOWN=>"Mouse1", WM_RBUTTONDOWN=>"Mouse2", WM_MBUTTONDOWN=>"Mouse3", WM_XBUTTONDOWN=>Marshal.ReadInt16(lParam, 24)==1?"Mouse4":"Mouse5", _=>null };
            if(button!=null && mouseBindings.TryGetValue(button,out int id))
            {
                // Mouse events are never suppressed; avoid repeated actions while held.
                if(mousePressed.Add(id)) source.Dispatcher.BeginInvoke(new Action(()=>handler(id)));
            }
            else if(message is 0x0202 or 0x0205 or 0x0208 or 0x020C)
            {
                string? released=message switch { 0x0202=>"Mouse1",0x0205=>"Mouse2",0x0208=>"Mouse3",0x020C=>Marshal.ReadInt16(lParam,24)==1?"Mouse4":"Mouse5",_=>null };
                if(released!=null && mouseBindings.TryGetValue(released,out int releasedId)) mousePressed.Remove(releasedId);
            }
        }
        return CallNextHookEx(mouseHook,code,wParam,lParam);
    }
    public string Apply(HotkeySettings settings)
    {
        foreach (var id in registered) UnregisterHotKey(hwnd,id); registered.Clear(); mouseBindings.Clear(); mousePressed.Clear();
        var entries = new[]{settings.Start,settings.Pause,settings.Stop,settings.AddAbility};
        var warnings = new List<string>();
        for(int i=0;i<entries.Length;i++)
        {
            if(entries[i].StartsWith("Mouse",StringComparison.OrdinalIgnoreCase))
            {
                if(int.TryParse(entries[i][5..],out int number) && number is >=1 and <=5)
                {
                    if(mouseHook==IntPtr.Zero) warnings.Add($"Mouse hook unavailable: {entries[i]}");
                    else mouseBindings["Mouse"+number]=i+1;
                }
                else warnings.Add($"Unsupported mouse button: {entries[i]}");
                continue;
            }
            var parts=entries[i].ToUpperInvariant().Split('+',StringSplitOptions.RemoveEmptyEntries|StringSplitOptions.TrimEntries);
            uint mods=0; string key=parts.LastOrDefault()??"";
            foreach(var part in parts.SkipLast(1)) { if(part=="CTRL")mods|=2; else if(part=="SHIFT")mods|=4; else if(part=="ALT")mods|=1; }
            if (!Enum.TryParse<Key>(key,true,out var k)) { warnings.Add($"Неверная клавиша: {entries[i]}"); continue; }
            var vk=KeyInterop.VirtualKeyFromKey(k);
            if (vk == 0 || !RegisterHotKey(hwnd,i+1,mods|0x4000,(uint)vk)) warnings.Add($"Не удалось зарегистрировать {entries[i]} (возможно, занята)");
            else registered.Add(i+1);
        }
        return string.Join("; ",warnings);
    }
    public void Dispose() { foreach(var id in registered) UnregisterHotKey(hwnd,id); registered.Clear(); if(mouseHook!=IntPtr.Zero) UnhookWindowsHookEx(mouseHook); mouseHook=IntPtr.Zero; source.RemoveHook(Hook); }
}
