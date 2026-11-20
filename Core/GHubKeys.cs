namespace WoWForeverAssistant;
public static class GHubKeys
{
    // USB HID keyboard usage IDs (boot keyboard report slots 2..7).
    public static bool TryParse(string value, out byte modifier, out byte usage)
    {
        modifier = 0; usage = 0;
        foreach (var part in value.Trim().ToUpperInvariant().Split('+', StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries))
        {
            if (part is "CTRL" or "CONTROL") { modifier |= 0x01; continue; }
            if (part == "SHIFT") { modifier |= 0x02; continue; }
            if (part == "ALT") { modifier |= 0x04; continue; }
            if (part == "WIN") { modifier |= 0x08; continue; }
            if (part.Length == 1 && part[0] is >= 'A' and <= 'Z') { usage = (byte)(4 + part[0] - 'A'); continue; }
            if (part.Length == 1 && part[0] is >= '1' and <= '9') { usage = (byte)(30 + part[0] - '1'); continue; }
            if (part == "0") { usage = 39; continue; }
            if (part == "SPACE") { usage = 44; continue; }
            if (part == "TAB") { usage = 43; continue; }
            if (part == "ENTER") { usage = 40; continue; }
            if (part.StartsWith('F') && int.TryParse(part[1..], out int f) && f is >= 1 and <= 12) { usage = (byte)(57 + f); continue; }
            return false;
        }
        return usage != 0;
    }
}
