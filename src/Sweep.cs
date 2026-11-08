using System.Globalization;

namespace CastDemo;

// Writes a result for many doubles, so check.ps1 can compare two runtimes value by value.
// The generator is written out here, so the inputs can't depend on the runtime.
static class Sweep
{
    const int ValuesPerSet = 50_000;

    public static void Dump(string path)
    {
        using var writer = new StreamWriter(path);
        writer.NewLine = "\n";

        var random = new SplitMix64(20261108);
        for (int i = 0; i < ValuesPerSet; i++)
            Write(writer, "cents", (random.Next() % 100_000_000UL) / 100.0);
        for (int i = 0; i < ValuesPerSet; i++)
            Write(writer, "thousandths", (random.Next() % 1_000_000_000UL) / 1000.0);
        for (int i = 0; i < ValuesPerSet; i++)
            Write(writer, "wide", (random.Next() % 1_000_000_000_000UL) * Math.Pow(10, -(int)(random.Next() % 13)) / 7.0);
    }

    static void Write(StreamWriter writer, string set, double d)
    {
        var c = CultureInfo.InvariantCulture;
        writer.Write(set); writer.Write('\t');
        writer.Write(d.ToString("R", c)); writer.Write('\t');
        writer.Write(((decimal)d).ToString(c)); writer.Write('\t');
        writer.Write(Math.Round((decimal)d, 2).ToString(c)); writer.Write('\t');
        writer.Write(Stable.FromG15(d).ToString(c)); writer.Write('\t');
        writer.Write(Math.Round(Stable.FromG15(d), 2).ToString(c));
        writer.WriteLine();
    }

    struct SplitMix64(ulong seed)
    {
        ulong _state = seed;

        public ulong Next()
        {
            ulong z = _state += 0x9E3779B97F4A7C15UL;
            z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9UL;
            z = (z ^ (z >> 27)) * 0x94D049BB133111EBUL;
            return z ^ (z >> 31);
        }
    }
}
