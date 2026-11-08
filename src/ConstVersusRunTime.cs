namespace CastDemo;

// The compiler works out a constant conversion while it builds, using the runtime the compiler
// itself is running on. A cast of a variable happens later, on whatever runtime runs the program.
static class ConstVersusRunTime
{
    const decimal Folded = (decimal)1.23;
    const bool FoldedEquals = (decimal)0.1 + (decimal)0.2 == 0.3m;

    public static void Run()
    {
        Output.Section("const against run time", labelWidth: 18);

        decimal literal = (decimal)1.23;

        double d = 1.23;
        decimal atRunTime = (decimal)d;

        Output.Show("const", Folded);
        Output.Show("literal cast", literal);
        Output.Show("cast of a variable", atRunTime);
        Output.Show("same value", Folded == atRunTime);
        Output.Show("const 0.1 + 0.2 == 0.3m", FoldedEquals);
    }
}
