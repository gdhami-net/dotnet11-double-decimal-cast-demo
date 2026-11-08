# dotnet11-double-decimal-cast-demo

One small console program, built with the .NET 10 SDK and with the .NET 11 SDK, that shows how
converting a `double` or `float` to `decimal` gives a different number on .NET 11.

## What it proves

| Build and run | const / literal cast | cast of a variable |
|---|---|---|
| .NET 10 SDK, `net10.0`, on .NET 10 | `1.23` | `1.23` |
| .NET 11 SDK, `net11.0`, on .NET 11 | `1.2299999999999999822364316060` | `1.2299999999999999822364316060` |
| .NET 11 SDK, `net10.0`, on .NET 10 | `1.2299999999999999822364316060` | `1.23` |
| .NET 10 SDK, `net10.0`, rolled forward to .NET 11 | `1.23` | `1.2299999999999999822364316060` |

- The SDK decides a constant conversion, because the compiler works it out with the runtime it runs
  on itself. A literal such as `(decimal)1.23` counts as a constant even without the `const` keyword.
- The runtime decides the cast of a variable. That covers assemblies you did not compile, such as
  NuGet packages, which is why the last row matters.
- `(decimal)0.1 + (decimal)0.2 == 0.3m` is `True` on .NET 10 and `False` on .NET 11.
- Every form changes the same way: the cast, `(decimal?)`, `(Decimal)`, `(System.Decimal)`,
  `Convert.ToDecimal` (also as a method group), `new decimal(d)`, `decimal.CreateChecked`,
  `CreateTruncating`, `CreateSaturating`, `IConvertible.ToDecimal`, `new(d)` with a target type,
  generic math through `T.CreateChecked`, a `using` alias, and `Convert.ChangeType`.
- `find-casts.sh` is a text search for these forms. `check.ps1` runs its patterns over `src/Forms.cs`
  and compares the hits with the `FOUND` and `MISSED` comments on each line.

## How to run it

You need PowerShell 7 and git, plus both SDKs. `dotnet` on PATH has to offer the .NET 10 SDK and a
.NET 10 runtime. If the .NET 11 SDK lives in its own folder, point `DOTNET11` at its `dotnet` executable.

```powershell
$env:DOTNET11 = "C:\path\to\dotnet11\dotnet.exe"   # only if it isn't on PATH
pwsh -NoProfile -File check.ps1
```

The script builds the program four ways, one per row of the table, and asserts every value quoted
in the post and in this file. It exits 0 and ends with `ALL CHECKS PASSED` when they all hold. To
read the output yourself, run a build from `artifacts/`:

```powershell
dotnet artifacts/sdk11-net10/bin/CastDemo/release/CastDemo.dll
```

The folders `sdk10/` and `sdk11/` hold only a `global.json`. The script builds from inside them, so
each build gets the SDK it's meant to have.

## Tool versions

Run on Windows 11 with:

- .NET SDK 10.0.201, runtime 10.0.5
- .NET SDK 11.0.100-rc.3.26522.148, runtime 11.0.0-rc.3.26522.148
- PowerShell 7.6.9, git 2.51.2

## Edge cases the post leaves out

**The trailing zero.** Plain `ToString()` prints `1.2299999999999999822364316060`. Microsoft's page
shows `1.229999999999999982236431606` because its example formats with `G29`, which drops trailing
zeros. It's the same value at a different scale. The program prints both.

**`float` shows it more.** `(decimal)1.23f` is `1.230000019073486328125` on .NET 11, and
`(decimal)14.1f` is `14.1000003814697265625`. Formatting with `G7` and parsing gives `14.1` on both.

**The trailing zero after rounding.** `Math.Round((decimal)d, 2)` keeps the same value, but it can
print differently. With `d = 19.9`, .NET 10 prints `19.9` and .NET 11 prints `19.90`. That matters to
snapshot tests and anything else that compares text. Among 50,000 cent amounts the value never
changed and the text changed on 4,046.

**Rounding after the cast can flip at a half.** With `d = 2.675`, `Math.Round((decimal)d, 2)` gives
`2.68` on .NET 10 and `2.67` on .NET 11, because the double is slightly below 2.675. Among 50,000
values with three decimals, 2,449 rounded to a different value. Banker's rounding can hide it:
`1.005` gives `1.00` on both.

**G15 is close to the old cast, and not identical.** Formatting with `G15` and parsing gave the same
text on both runtimes for all 150,000 doubles in the sweep. Against the old cast it matched on all
100,000 values that had 15 significant digits or fewer. On 50,000 long doubles it differed on 1,072,
always in the 15th digit. For example `0.2933701380285715` was `0.293370138028572` through the old
cast and is `0.293370138028571` through `G15`. The old cast did its scaling in floating point, which
could push it one digit away.

**An exact tie at the 15th digit** gives the same result both ways: `1000000000000.125` is
`1000000000000.12` through the old cast and through `G15`. On .NET 11 the plain cast keeps
`1000000000000.125`.

**The other direction changed too.** A `decimal` converted to `double` now rounds once:
`(double)10000000000000.099609375m` is `10000000000000.09765625` on .NET 10 and
`10000000000000.099609375` on .NET 11. `find-casts.sh` doesn't look for those.

**`Math.Round` on a double** changed in the same preview:
`Math.Round(655.925, 2, MidpointRounding.AwayFromZero)` gives `655.93` on .NET 10 and `655.92` on
.NET 11.

**What the search misses or can't judge.** It can't see types, so a cast of an `int` is a hit as
well. It finds `Convert.ChangeType` only by accident, because `typeof(decimal)` contains the text of
a cast, and any other `typeof(decimal)` is a false hit. It misses `new(d)` with a target type, generic
math through `T.CreateChecked`, and a `using` alias. It can't read compiled packages.

**No switch.** Microsoft's page says there's no compatibility switch. The two pull requests behind
the change, dotnet/runtime#130565 and #130566, add no `AppContext` check.

## License

MIT
