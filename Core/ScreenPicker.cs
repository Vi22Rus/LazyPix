using System.Windows.Forms;
using System.Drawing;
using System.Drawing.Imaging;

namespace WoWForeverAssistant;
public sealed class ScreenPicker : Form
{
    private readonly Bitmap snapshot;
    private Point start;
    private Rectangle selection;
    private bool dragging;
    private readonly bool pixelMode;
    public Rectangle SelectedRegion { get; private set; }
    public Point SelectedPixel { get; private set; }
    public Color SelectedColor { get; private set; }
    public List<AbilityPixel>? SelectedPattern { get; private set; }
    public bool CaptureNinePixelPattern()
    {
        const int step = 3;
        if (SelectedPixel.X < step || SelectedPixel.Y < step || SelectedPixel.X + step >= snapshot.Width || SelectedPixel.Y + step >= snapshot.Height) return false;
        var pattern = new List<AbilityPixel>(9);
        for (int dy = -step; dy <= step; dy += step)
            for (int dx = -step; dx <= step; dx += step)
            {
                var c = snapshot.GetPixel(SelectedPixel.X + dx, SelectedPixel.Y + dy);
                pattern.Add(new AbilityPixel { OffsetX = dx, OffsetY = dy, R = c.R, G = c.G, B = c.B });
            }
        SelectedPattern = pattern;
        return true;
    }

    public ScreenPicker(Rectangle bounds, bool pickPixel = false)
    {
        pixelMode = pickPixel;
        FormBorderStyle = FormBorderStyle.None;
        StartPosition = FormStartPosition.Manual;
        Bounds = bounds;
        TopMost = true;
        DoubleBuffered = true;
        Cursor = Cursors.Cross;
        KeyPreview = true;
        snapshot = new Bitmap(bounds.Width, bounds.Height, PixelFormat.Format32bppArgb);
        using var graphics = Graphics.FromImage(snapshot);
        graphics.CopyFromScreen(bounds.Location, Point.Empty, bounds.Size);
        KeyDown += (_, e) => { if (e.KeyCode == Keys.Escape) DialogResult = DialogResult.Cancel; };
    }
    protected override void OnPaint(PaintEventArgs e)
    {
        e.Graphics.DrawImageUnscaled(snapshot, 0, 0);
        // Pixel picking must show the original image without any text or tint.
        // Otherwise a user can click the overlay instead of the actual ability icon.
        if (!pixelMode)
        {
            using var shade = new SolidBrush(Color.FromArgb(75, Color.Black));
            e.Graphics.FillRectangle(shade, ClientRectangle);
        }
        if (!pixelMode && selection.Width > 0 && selection.Height > 0)
        {
            e.Graphics.DrawImage(snapshot, selection, selection, GraphicsUnit.Pixel);
            using var pen = new Pen(Color.Lime, 2);
            e.Graphics.DrawRectangle(pen, selection);
        }
        // Instructions are useful for selecting a region, but never draw over a pixel sample.
        if (!pixelMode)
        {
            using var font = new Font("Segoe UI", 12, FontStyle.Bold);
            e.Graphics.DrawString(L.T("Выдели область первой иконки · Esc — отмена"), font, Brushes.Yellow, 15, 15);
        }
    }
    protected override void OnMouseDown(MouseEventArgs e)
    {
        if (e.Button != MouseButtons.Left) return;
        if (pixelMode)
        {
            if (e.X < 0 || e.Y < 0 || e.X >= snapshot.Width || e.Y >= snapshot.Height) return;
            SelectedPixel = e.Location;
            SelectedColor = snapshot.GetPixel(e.X, e.Y);
            DialogResult = DialogResult.OK;
        }
        else { start = e.Location; dragging = true; }
    }
    protected override void OnMouseMove(MouseEventArgs e)
    {
        if (!dragging) return;
        int x = Math.Clamp(Math.Min(start.X, e.X), 0, ClientSize.Width - 1);
        int y = Math.Clamp(Math.Min(start.Y, e.Y), 0, ClientSize.Height - 1);
        int r = Math.Clamp(Math.Max(start.X, e.X), 0, ClientSize.Width);
        int b = Math.Clamp(Math.Max(start.Y, e.Y), 0, ClientSize.Height);
        selection = Rectangle.FromLTRB(x, y, Math.Max(x, r), Math.Max(y, b));
        Invalidate();
    }
    protected override void OnMouseUp(MouseEventArgs e)
    {
        if (!dragging) return;
        dragging = false;
        if (selection.Width < 8 || selection.Height < 8) return;
        SelectedRegion = new Rectangle(Left + selection.X, Top + selection.Y, selection.Width, selection.Height);
        DialogResult = DialogResult.OK;
    }
    protected override void Dispose(bool disposing) { if (disposing) snapshot.Dispose(); base.Dispose(disposing); }
}
