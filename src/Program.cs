using System.Globalization;
using System.Runtime.InteropServices;
using CastDemo;

CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;

if (args is ["--dump", var path])
{
    Sweep.Dump(path);
    return;
}

Output.Section("environment");
Output.Show("runtime", RuntimeInformation.FrameworkDescription);
Output.Show("built for", AppContext.TargetFrameworkName ?? "unknown");

TheCast.Run();
ConstVersusRunTime.Run();
Forms.Run();
Stable.Run();
Extras.Run();
