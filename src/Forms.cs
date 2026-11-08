using System.Numerics;
using Money = System.Decimal;

namespace CastDemo;

// Every conversion the post talks about, one per line. A line that ends in FOUND must be a hit
// for the search in the post, a line that ends in MISSED must not be, and neither must any other
// line. check.ps1 runs the search over this file and compares. The labels stay free of anything
// the search looks for, so a hit always comes from the code.
static class Forms
{
    public static void Run()
    {
        double d = 1.23;
        float f = 1.23f;
        int count = 3;
        long large = 3L;

        Output.Section("forms that convert a double", labelWidth: 26);
        Output.Show("cast", (decimal)d); // FOUND
        Output.Show("nullable cast", (decimal?)d); // FOUND
        Output.Show("capitalised cast", (Decimal)d); // FOUND
        Output.Show("full name cast", (System.Decimal)d); // FOUND
        Output.Show("Convert", Convert.ToDecimal(d)); // FOUND
        Output.Show("Convert as a method group", new[] { d }.Select(Convert.ToDecimal).First()); // FOUND
        Output.Show("constructor", new decimal(d)); // FOUND
        Output.Show("CreateChecked", decimal.CreateChecked(d)); // FOUND
        Output.Show("CreateTruncating", decimal.CreateTruncating(d)); // FOUND
        Output.Show("CreateSaturating", decimal.CreateSaturating(d)); // FOUND
        Output.Show("IConvertible", ((IConvertible)d).ToDecimal(null)); // FOUND
        Output.Show("target-typed new", TargetTyped(d));
        Output.Show("generic math", Generic<decimal>(d));
        Output.Show("alias cast", (Money)d); // MISSED
        Output.Show("ChangeType", ViaChangeType(d));

        Output.Section("forms that convert a float", labelWidth: 26);
        Output.Show("cast of float", (decimal)f); // FOUND
        Output.Show("Convert of float", Convert.ToDecimal(f)); // FOUND
        Output.Show("constructor of float", new decimal(f)); // FOUND
        Output.Show("CreateChecked of float", decimal.CreateChecked(f)); // FOUND
        Output.Show("CreateTruncating of float", decimal.CreateTruncating(f)); // FOUND
        Output.Show("CreateSaturating of float", decimal.CreateSaturating(f)); // FOUND

        Output.Section("look the same in a search, and do not change", labelWidth: 26);
        Output.Show("cast of int", (decimal)count); // FOUND
        Output.Show("cast of long", (decimal)large); // FOUND
        Output.Show("constructor of int", new decimal(count)); // FOUND
        Output.Show("Convert of int", Convert.ToDecimal(count)); // FOUND
        Output.Show("Convert of string", Convert.ToDecimal("1.23")); // FOUND
    }

    static decimal TargetTyped(double d) => new(d); // MISSED

    static T Generic<T>(double d) where T : INumberBase<T> => T.CreateChecked(d); // MISSED

    // Found only by accident: the typeof on this line contains the text the cast pattern looks for.
    static decimal ViaChangeType(double d) => Convert.ChangeType(d, typeof(decimal)) is decimal m ? m : 0m; // FOUND
}
