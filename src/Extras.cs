using System.Globalization;

namespace CastDemo;

// Things the post leaves out. The README lists them.
static class Extras
{
    public static void Run()
    {
        Output.Section("extras for the README", labelWidth: 40);

        Output.Show("Math.Round(655.925, 2, AwayFromZero)", Math.Round(655.925, 2, MidpointRounding.AwayFromZero));

        decimal big = 10000000000000.099609375m;
        Output.Show("(double) of 10000000000000.099609375m", ((double)big).ToString("G99", CultureInfo.InvariantCulture));

        // Exactly halfway at the 15th digit. The old cast broke ties to even.
        double tie = 1000000000000.125;
        Output.Show("tie: cast only", (decimal)tie);
        Output.Show("tie: G15 and parse", Stable.FromG15(tie));

        float docsFloat = 14.1f;
        Output.Show("14.1f: cast only", (decimal)docsFloat);
        Output.Show("14.1f: G7 and parse", decimal.Parse(docsFloat.ToString("G7", CultureInfo.InvariantCulture), NumberStyles.Float, CultureInfo.InvariantCulture));

        double tiny = 1E-30;
        Output.Show("1E-30: cast only", (decimal)tiny);
        double wide = 12345678901234567890.0;
        Output.Show("12345678901234567890.0: cast only", (decimal)wide);
        Output.Show("12345678901234567890.0: G15 and parse", Stable.FromG15(wide));
    }
}
