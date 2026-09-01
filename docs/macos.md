# macOS build notes

MajdataEdit-Neo now builds on macOS with the .NET 9 SDK. The editor uses
ManagedBass for waveform extraction and audio preview; ManagedBass is only a
.NET wrapper and requires the native BASS library separately.

## Native audio library

1. Download the macOS BASS library from the official Un4seen BASS distribution.
2. Use a universal library (arm64 + x86_64) when possible. Otherwise use the
   library matching the target runtime (`osx-arm64` or `osx-x64`).
3. Rename it to `libbass.dylib` and place it beside `MajdataEdit-Neo.csproj`.
4. Build or publish the project. The project file copies `libbass.dylib` to the
   output directory only on macOS.

The native library is intentionally ignored by Git because its redistribution
terms are separate from this project. A missing library causes
`Bass.Init()` to fail with `DllNotFoundException` when audio functionality is
used.

## Build

```bash
dotnet restore MajdataEdit-Neo.sln
dotnet build MajdataEdit-Neo.csproj -c Release
dotnet publish MajdataEdit-Neo.csproj -c Release -r osx-arm64 --self-contained true
dotnet publish MajdataEdit-Neo.csproj -c Release -r osx-x64 --self-contained true
```

The current project is a desktop .NET output, not yet a signed/notarized
`.app` bundle. Code signing and packaging are required before distributing it
outside a development machine.

The framework-dependent app requires the macOS .NET 9 runtime
(`Microsoft.NETCore.App 9.0.x`). macOS does not provide a separate
`.NET Desktop Runtime` package; install the standard .NET runtime or SDK.

The repository includes `scripts/publish-macos.sh` to create a local app
bundle. It requires `libbass.dylib` beside the project file and accepts either
`osx-arm64` or `osx-x64`:

```bash
./scripts/publish-macos.sh osx-arm64
open artifacts/MajdataEdit-Neo-osx-arm64.app
```

If the project has already been built with `dotnet build` and the matching
runtime pack is not available locally, reuse that output without downloading:

```bash
USE_EXISTING_BUILD=true ./scripts/publish-macos.sh osx-arm64
```

To make a self-contained app that does not require a system .NET install,
provide `DOTNET_ROOT` and bundle the installed runtime:

```bash
DOTNET_ROOT=/path/to/dotnet BUNDLE_DOTNET=true \
  USE_EXISTING_BUILD=true ./scripts/publish-macos.sh osx-arm64
```

The script defaults to framework-dependent publishing. Set
`SELF_CONTAINED=true` for a standalone bundle on a normal macOS/.NET setup;
that mode downloads the matching .NET runtime pack.

## MajdataPlay connection

The editor connects to MajdataPlay through:

```text
ws://127.0.0.1:8083/majdata
```

Start the macOS MajdataPlay standalone app first, then use the editor's player
connection control. Both applications must run on the same Mac.
