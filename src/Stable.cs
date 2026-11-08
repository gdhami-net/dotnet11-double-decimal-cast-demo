using System.Globalization;

namespace CastDemo;

static class Stable
{
    // Formats the double with 15 significant digits and parses the text. The README says where this
    // matches the old cast and where it can land one digit away.
    public static decimal FromG15(double d) =>
        decimal.Parse(
            d.ToString("G15", CultureInfo.InvariantCulture),
            NumberStyles.Float,
            CultureInfo.InvariantCulture);

    public static void Run()
    {
        Output.Section("getting a stable number", labelWidth: 30);

        foreach (double d in new[] { 1.23, 2.675, 1.005, 19.99, 19.9 })
        {
            string name = d.ToString("R", CultureInfo.InvariantCulture);
            Output.Show($"{name}: cast only", (decimal)d);
            Output.Show($"{name}: round after the cast", Math.Round((decimal)d, 2));
            Output.Show($"{name}: round before the cast", (decimal)Math.Round(d, 2));
            Output.Show($"{name}: G15 and parse", FromG15(d));
            Output.Show($"{name}: G15, parse, then round", Math.Round(FromG15(d), 2));
        }
    }
}
