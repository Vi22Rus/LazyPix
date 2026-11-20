using System.Windows.Forms;
using System.Drawing;

namespace WoWForeverAssistant;

/// <summary>Creates a canonical key binding; never sends keys while configuring.</summary>
public sealed class KeyBindingDialog : Form
{
    private readonly TextBox keyInput = new() { Width = 185, Text = "1", CharacterCasing = CharacterCasing.Upper };
    private readonly CheckBox shift = new() { Text = "Shift", AutoSize = true };
    private readonly CheckBox ctrl = new() { Text = "Ctrl", AutoSize = true };
    private readonly Label preview = new() { AutoSize = true };
    public string Binding { get; private set; } = "";

    public KeyBindingDialog()
    {
        Text = "Назначение клавиши";
        Font = new Font("Segoe UI", 10);
        ClientSize = new Size(370, 215);
        FormBorderStyle = FormBorderStyle.FixedDialog;
        MaximizeBox = false;
        MinimizeBox = false;
        StartPosition = FormStartPosition.CenterParent;
        var label = new Label { Text = "Основная клавиша (1–9, 0, A–Z, F1–F12):", Location = new Point(18, 16), AutoSize = true };
        keyInput.Location = new Point(18, 44);
        shift.Location = new Point(18, 85);
        ctrl.Location = new Point(118, 85);
        preview.Location = new Point(18, 119);
        var ok = new Button { Text = "Сохранить", Location = new Point(153, 165), Size = new Size(100, 32) };
        var cancel = new Button { Text = "Отмена", Location = new Point(261, 165), Size = new Size(90, 32), DialogResult = DialogResult.Cancel };
        Controls.AddRange(new Control[] { label, keyInput, shift, ctrl, preview, ok, cancel });
        AcceptButton = ok;
        CancelButton = cancel;
        keyInput.TextChanged += (_, _) => UpdatePreview();
        shift.CheckedChanged += (_, _) => UpdatePreview();
        ctrl.CheckedChanged += (_, _) => UpdatePreview();
        ok.Click += (_, _) =>
        {
            string main = keyInput.Text.Trim().ToUpperInvariant();
            // The modifier keys must be selected via checkboxes, not typed into the base key.
            if (main.Contains('+') || main is "CTRL" or "CONTROL" or "SHIFT" ||
                !GHubKeys.TryParse(main, out byte parsedModifier, out _ ) || parsedModifier != 0)
            {
                MessageBox.Show(this, "Укажи одну основную клавишу без Ctrl/Shift. Модификаторы выбираются галочками.",
                    "Неверная клавиша", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }
            Binding = Compose(main);
            DialogResult = DialogResult.OK;
            Close();
        };
        UpdatePreview();
    }

    private string Compose(string main) =>
        (ctrl.Checked ? "Ctrl+" : "") + (shift.Checked ? "Shift+" : "") + main;

    private void UpdatePreview() => preview.Text = "Комбинация: " + Compose(keyInput.Text.Trim().ToUpperInvariant());
}
