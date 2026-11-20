using System.ComponentModel;
using System.Runtime.InteropServices;
using Microsoft.Win32;
using Microsoft.Win32.SafeHandles;

namespace WoWForeverAssistant;

/// <summary>Direct access to the installed Logitech G HUB virtual bus. No third-party DLL,
/// Python, TCP or SendInput. Uses an undocumented Logitech IOCTL; compatibility is not guaranteed.</summary>
public sealed class GHubDriver : IDisposable
{
    private const uint GenericRead = 0x80000000;
    private const uint GenericWrite = 0x40000000;
    private const uint OpenExisting = 3;
    private const uint KeyboardIoctl = 0x2A200C;
    private SafeFileHandle? device;
    public bool Connected => device is { IsInvalid: false, IsClosed: false };
    public string DevicePath { get; private set; } = "";

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern SafeFileHandle CreateFileW(string name, uint access, uint share,
        IntPtr security, uint disposition, uint flags, IntPtr template);

    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool DeviceIoControl(SafeFileHandle handle, uint code,
        byte[] input, int inputSize, IntPtr output, int outputSize,
        out int returned, IntPtr overlapped);

    private static IEnumerable<string> DiscoverPaths()
    {
        // Find bus instances by their HardwareID, not a hard-coded ROOT\\SYSTEM\\0001.
        var instances = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        using (var root = Registry.LocalMachine.OpenSubKey(@"SYSTEM\CurrentControlSet\Enum\ROOT\SYSTEM"))
        {
            if (root != null)
                foreach (var instance in root.GetSubKeyNames())
                {
                    using var item = root.OpenSubKey(instance);
                    var ids = item?.GetValue("HardwareID") as string[] ?? Array.Empty<string>();
                    if (ids.Any(id => id.Contains("lghubvirtualbus", StringComparison.OrdinalIgnoreCase)))
                        instances.Add(instance);
                }
        }
        if (instances.Count == 0) yield break;

        using var classes = Registry.LocalMachine.OpenSubKey(@"SYSTEM\CurrentControlSet\Control\DeviceClasses");
        if (classes == null) yield break;
        foreach (var guid in classes.GetSubKeyNames())
        {
            using var cls = classes.OpenSubKey(guid);
            if (cls == null) continue;
            foreach (var name in cls.GetSubKeyNames())
            {
                // Registry symbolic link key: ##?#ROOT#SYSTEM#0001#{interface-guid}
                if (!instances.Any(i => name.Contains($"ROOT#SYSTEM#{i}#", StringComparison.OrdinalIgnoreCase)))
                    continue;
                if (!name.StartsWith("##?#", StringComparison.Ordinal)) continue;
                yield return @"\\?\" + name.Substring(4);
            }
        }
    }

    public string Connect()
    {
        Disconnect();
        if (!OperatingSystem.IsWindows() || !Environment.Is64BitProcess)
            throw new PlatformNotSupportedException("Требуется Windows x64.");
        var candidates = DiscoverPaths().Distinct(StringComparer.OrdinalIgnoreCase).ToArray();
        if (candidates.Length == 0)
            throw new InvalidOperationException("Интерфейс lghubvirtualbus не найден в реестре Windows. Проверьте установку и запуск Logitech G HUB.");
        int error = 0;
        foreach (var path in candidates)
        {
            var handle = CreateFileW(path, GenericRead | GenericWrite, 3, IntPtr.Zero, OpenExisting, 0, IntPtr.Zero);
            if (!handle.IsInvalid)
            {
                device = handle;
                DevicePath = path;
                return "Открыт интерфейс виртуальной шины Logitech: " + path;
            }
            error = Marshal.GetLastWin32Error();
            handle.Dispose();
        }
        throw new Win32Exception(error, $"Найдено {candidates.Length} интерфейсов Logitech, но открыть ни один не удалось (Win32={error}).");
    }

    private void SendKeyboardReport(byte modifier, byte key = 0)
    {
        if (device is null || !Connected) throw new InvalidOperationException("Сначала подключитесь к драйверу G HUB.");
        // Standard 8-byte boot keyboard report: modifiers, reserved, 6 key slots.
        // Left GUI / Win = HID usage 0xE3 => modifier bit 3 (0x08).
        var report = new byte[8];
        report[0] = modifier;
        report[2] = key;
        if (!DeviceIoControl(device, KeyboardIoctl, report, report.Length,
                IntPtr.Zero, 0, out _, IntPtr.Zero))
            throw new Win32Exception(Marshal.GetLastWin32Error(), "G HUB отклонил клавиатурный IOCTL.");
    }

    public void TapKey(byte modifier, byte usage)
    {
        if (!Connected) throw new InvalidOperationException("G HUB не подключён.");
        try { SendKeyboardReport(modifier, usage); Thread.Sleep(12); }
        finally { SendKeyboardReport(0); }
    }

    public void TestWin()
    {
        if (!Connected) throw new InvalidOperationException("G HUB не подключён.");
        try
        {
            SendKeyboardReport(0x08);
            Thread.Sleep(70);
        }
        finally
        {
            // Always release all modifiers, even if the press failed.
            SendKeyboardReport(0);
        }
    }

    public void Disconnect()
    {
        device?.Dispose(); device = null; DevicePath = "";
    }
    public void Dispose() => Disconnect();
}
