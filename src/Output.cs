using System.Globalization;
using System.Runtime.InteropServices;

namespace CastDemo;

// One value per line: a label, at least two spaces, the value. check.ps1 reads this format.
static class Output
{
    static int _labelWidth = 13;

    public static void Section(string name, int labelWidth = 13)
    {
        _labelWidth = labelWidth;
        Console.WriteLine();
        Console.WriteLine($"== {name}");
    }

    public static void ShowEnvironment()
    {
        Show("runtime", RuntimeInformation.FrameworkDescription);
        Show("built for", AppContext.TargetFrameworkName ?? "unknown");
    }

    public static void Show(string label, object? value)
    {
        string text = value switch
        {
            IFormattable f => f.ToString(null, CultureInfo.InvariantCulture),
            null => "null",
            _ => value.ToString() ?? "null",
        };
        Console.WriteLine($"{label.PadRight(_labelWidth)}  {text}");
    }
}
