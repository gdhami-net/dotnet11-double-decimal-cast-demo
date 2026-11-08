using System.Globalization;
using CastDemo;

CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;

if (args is ["--dump", var path])
{
    Sweep.Dump(path);
    return;
}

Output.Section("environment");
Output.ShowEnvironment();

TheCast.Run();
ConstVersusRunTime.Run();
Forms.Run();
Stable.Run();
Extras.Run();
