using System;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Media.Imaging;
namespace WoWForeverAssistant;
// Legacy class name retained for existing UI call sites; now supports every class.
public static class PaladinIcons
{
    public static ImageSource? Get(string className,string abilityName)
    {
        var file = SpellCatalog.IconFile(className,abilityName);
        if (string.IsNullOrEmpty(file)) return null;
        try {
            var bmp = new BitmapImage();bmp.BeginInit();
            bmp.UriSource = new Uri("pack://application:,,,/Assets/SpellIcons/"+file,UriKind.Absolute);
            bmp.CacheOption=BitmapCacheOption.OnLoad;bmp.EndInit();bmp.Freeze();return bmp;
        } catch {return null;}
    }
    public static FrameworkElement Tile(string className,string name,int size=32)
    {
        var image=Get(className,name);
        if(image==null) return new TextBlock {Text="✦",FontSize=size*0.6,Foreground=Brushes.LightBlue,HorizontalAlignment=HorizontalAlignment.Center,VerticalAlignment=VerticalAlignment.Center};
        return new Image {Source=image,Width=size,Height=size,Stretch=Stretch.UniformToFill};
    }
}
