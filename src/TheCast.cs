namespace CastDemo;

static class TheCast
{
    public static void Run()
    {
        Output.Section("the cast, at run time");

        double price = 1.23;
        decimal converted = (decimal)price;
        Output.Show("converted", converted);

        double a = 0.1, b = 0.2;
        decimal sum = (decimal)a + (decimal)b;
        Output.Show("sum", sum);
        Output.Show("sum == 0.3m", sum == 0.3m);

        Output.Section("the same value, shown other ways", labelWidth: 26);
        Output.Show("every digit of the double", price.ToString("G60"));
        Output.Show("converted, shown with G29", converted.ToString("G29"));
        Output.Show("converted, shown with F2", converted.ToString("F2"));
        Output.Show("converted == 1.23m", converted == 1.23m);
    }
}
