# Flutter/Android toolchain

Scripts and docs for **calculator_app** on Windows (Iran-friendly mirrors).

## Documentation (Persian)

| Doc | Audience |
|-----|----------|
| [docs/README-FA.md](docs/README-FA.md) | **Start here** — index for all roles |
| [docs/GUIDE-WEB-FA.md](docs/GUIDE-WEB-FA.md) | Web developers (Chrome, deploy) |
| [docs/GUIDE-WINDOWS-FA.md](docs/GUIDE-WINDOWS-FA.md) | Windows desktop (exe) |
| [docs/GUIDE-MOBILE-FA.md](docs/GUIDE-MOBILE-FA.md) | Android (APK, emulator, adb) |
| [docs/FLUTTER-SETUP-FA.md](docs/FLUTTER-SETUP-FA.md) | Toolchain install (SDK, Gradle, mirrors) |

Run commands from project root: `calculator_app`

## Scripts

| Script | Purpose |
|--------|---------|
| [probe-flutter-mirrors-iran.ps1](scripts/probe-flutter-mirrors-iran.ps1) | Probe Pub/Storage/Maven/Android CDN |
| [install-flutter-mobile-toolchain-iran.ps1](scripts/install-flutter-mobile-toolchain-iran.ps1) | env, PATH, SDK base, Gradle patch |
| [install-android-sdk-packages-iran.ps1](scripts/install-android-sdk-packages-iran.ps1) | platform-36, build-tools, cmake, NDK |
| [patch-flutter-gradle-mirrors.ps1](scripts/patch-flutter-gradle-mirrors.ps1) | Patch Flutter SDK Gradle |
| [verify-flutter-setup.ps1](scripts/verify-flutter-setup.ps1) | Atomic check (`-Strict` before APK) |

## Verify

```powershell
powershell -ExecutionPolicy Bypass -File toolchain/scripts/verify-flutter-setup.ps1 -Strict -SkipDoctor
```
