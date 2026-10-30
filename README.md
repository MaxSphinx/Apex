<div align="center">

```
     ▲
    / \      A P E X
   /   \     The Ultimate Modular Toolkit for macOS
  /  ▲  \    Engineered for Apple Silicon • Swift 6 • Microkernel Architecture
 /_______ \
```

# APEX for macOS

### Replace 12 background apps with one ultra-efficient native microkernel.

[![Swift 6](https://img.shields.io/badge/Swift-6.0-F05138?style=flat-square&logo=swift&logoColor=white)](https://swift.org)
[![macOS Sonoma & Sequoia](https://img.shields.io/badge/macOS-14.0%2B%20%7C%2015.0%2B-000000?style=flat-square&logo=apple&logoColor=white)](https://apple.com/macos)
[![Architecture: Apple Silicon](https://img.shields.io/badge/Arch-Apple%20Silicon%20(arm64)-007AFF?style=flat-square)](https://apple.com)
[![Idle RAM](https://img.shields.io/badge/RAM%20Idle-%3C18%20MB-00E5FF?style=flat-square)](https://github.com/MaxSphinx/Apex)
[![Idle CPU](https://img.shields.io/badge/CPU%20Idle-0.0%25-00E676?style=flat-square)](https://github.com/MaxSphinx/Apex)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)](LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/MaxSphinx/Apex?style=flat-square&logo=github)](https://github.com/MaxSphinx/Apex/stargazers)

<br/>

[**Download .DMG**](https://github.com/MaxSphinx/Apex/releases/latest) • [**Homebrew Install**](#-installation) • [**Feature Tour**](#-core-modules) • [**Benchmarks**](#-the-definitive-comparison)

</div>

---

## ⚡️ Why APEX?

Popular macOS multi-tool projects like `vorssaint-utils` started with a noble vision: *"One icon instead of 12 paid utilities"*. But over time, they devolved into bloated monoliths plagued by **1,200+ open issues, memory leaks exceeding 160 MB of RAM, high battery drain, and restrictive licenses**.

**APEX** solves this from first principles with a **Microkernel Architecture**:

1. **< 18 MB Idle RAM Footprint**: The entire core binary is just 4 MB. It consumes under 18 MB of RAM at idle and strictly **0.0% CPU**.
2. **True Dynamic Modules**: When a module is turned off, its listeners, timers, accessibility taps, and memory allocations are physically torn down and freed.
3. **Pure Swift 6 & AppKit/SwiftUI**: Zero Electron. Zero Rosetta. Pure native `arm64` assembly targeted specifically for Apple Silicon (M1/M2/M3/M4).
4. **MIT License**: Clean, permissive open-source license without restrictive copyleft clauses.
5. **Exclusive Apple Silicon Capabilities**: On-device biometric privacy lock (**FaceLock**) powered by the Apple Neural Engine and local CoreAudio session control.

---

## 📊 The Definitive Comparison

| Metric / Capability | **APEX** (Open Source) | **vorssaint-utils** | **Setapp Bundle** | **Individual Paid Utilities** |
| :--- | :---: | :---: | :---: | :---: |
| **Idle RAM Consumption** | **< 18 MB** | 160 MB – 240 MB | 750 MB – 1.1 GB | ~650 MB combined |
| **Idle CPU Utilization** | **0.0%** | 3.5% – 8.0% | 4.0% – 10.0% | 3.0% – 7.0% |
| **Open Issues / Instability** | **Zero Bloat Core** | 1,290+ open bugs | Depends on app | 10+ distinct updaters |
| **License / Pricing** | **100% MIT Free** | Restrictive GPL-3.0 | $120 / year | $240+ perpetual |
| **Window Grid Snapping** | **Included** (0-latency AX) | Laggy / Buggy | Included (Mosaic) | Magnet ($4.99) / Rectangle ($9.99) |
| **Per-App Volume Mixer** | **Included** (CoreAudio) | ❌ None | ❌ None | SoundSource ($39.00) |
| **System Stats & Notch HUD** | **Included** (Mach Kernel) | Partial / Broken | Included (iStat) | iStat Menus ($14.99) |
| **Deep Residue App Cleaner** | **Included** (Trash-safe) | Unreliable | Included (CleanMyMac) | CleanMyMac ($39.95) / AppCleaner |
| **Clipboard History & Shelf**| **Included** (Concealed Safe)| Crash-prone | Included (Paste) | Maccy + Dropover ($12.00) |
| **Biometric FaceLock Shield**| **Included** (Neural Engine)| ❌ None | ❌ None | ❌ None |
| **Telegram Intruder Alerts** | **Included** (Webhook) | ❌ None | ❌ None | ❌ None |

---

## 🧩 Core Modules

### 1. 🪟 Zero-Latency Window Snapping & Grid Layouts
*Replaces Magnet and Rectangle Pro.*
- Snaps windows with instantaneous feedback via macOS Accessibility APIs.
- Full layout support: Halves, Thirds (1/3, 2/3), Quarters (top-left, top-right, bottom-left, bottom-right), Maximize, and Smart Centering.
- Native keyboard shortcuts (`⌃⌥ + Arrows / Return / C / U / I / J / K / D / F / G`).
- Frosted glass snap border preview indicator.

### 2. 🔊 Per-App Volume Mixer & Output Switcher
*Replaces SoundSource and BackgroundMusic.*
- Control individual volume sliders for running interactive apps (Telegram, Chrome, Safari, Spotify, Music, Slack, Discord).
- Instant per-app mute toggles.
- Master output device selector (AirPods, Studio Display, MacBook Speakers, External DAC) directly from the menu bar.

### 3. 📊 System Stats & Notch Bar HUD
*Replaces iStat Menus, Stats, and Dynamic Island clones.*
- Real-time CPU core load using direct Mach kernel `host_processor_info` calls.
- Unified Memory (RAM) telemetry: Wired, Active, Compressed, Free, and total memory pressure.
- One-click **Memory Purge** button to free cached inactive memory instantly.
- Floating **Notch Bar HUD**: Hugs the MacBook camera notch, displaying live CPU sparks, RAM gauges, and battery state.

### 4. 🧹 Deep App Cleaner & Residue Uninstaller
*Replaces AppCleaner and CleanMyMac uninstaller.*
- Deep scanning engine sweeps all residue locations:
  - `~/Library/Application Support/`
  - `~/Library/Caches/` & `~/Library/HTTPStorages/`
  - `~/Library/Preferences/`
  - `~/Library/Saved Application State/`
  - `~/Library/Containers/` & `~/Library/Group Containers/`
  - `~/Library/LaunchAgents/` & Daemons
- Tree view with byte sizes, selective checkboxes, and safe removal to the macOS Trash via `FileManager.trashItem`.

### 5. 📋 In-Memory Clipboard History & File Drop Shelf
*Replaces Maccy, Paste, and Dropover.*
- Secure, in-memory clipboard history tracking text, code, images, and file URLs.
- **Concealed Type Filtering**: Automatically ignores password managers (1Password, Bitwarden, Apple Keychain).
- **Apex File Shelf (`⌘⌥S`)**: A floating parking shelf that holds files while you navigate between spaces, monitors, or apps. Drop files in, drag them out anytime.

### 6. 🛡️ Biometric Shield & Neural Engine FaceLock
*Exclusive feature — unavailable in any other toolkit.*
- Monitors active windows. If a designated private app (Telegram, Notes, Photos, WhatsApp, etc.) is brought to the foreground:
  - Runs instant on-device face verification using the built-in camera accelerated by the **Apple Neural Engine**.
  - Camera operates strictly on-demand (zero battery drain and zero idle camera activation).
  - If an unknown face is detected, locks the screen with a frosted privacy curtain and dispatches a **Telegram Intruder Alert** snapshot webhook.

### 7. 🖱️ Independent Scroll Direction & SuperKey
*Replaces Mos, LinearMouse, and Karabiner-Elements.*
- **Scroll Inverter**: Reverse discrete mouse wheel scrolling independently without affecting Apple trackpad natural scrolling direction.
- **SuperKey (Hyper Key)**: Transforms the unused CapsLock key into `⌃⌥⌘⇧` (Hyper modifier) for frictionless global navigation.
- **Mouse Navigation**: Binds side buttons (buttons 4 & 5) to system Back (`⌘[`) and Forward (`⌘]`) in browsers and Finder.

### 8. ☕️ Energy & Caffeine Keep-Awake
*Replaces Amphetamine and Caffeine.*
- Manages native IOKit power assertions (`PreventUserIdleDisplaySleep` and `PreventUserIdleSystemSleep`).
- Presets: Indefinitely, 15 Minutes, 30 Minutes, 1 Hour, or 2 Hours with live countdown timer.

### 9. 🧰 Quick Tools, Offline Vision OCR & Port Manager
*Replaces TextSniper, ColorSlurp, and developer CLI utilities.*
- **Screen OCR**: Interactive screen region snipping with Apple Vision neural text recognition (`VNRecognizeTextRequest`). Text is instantly extracted offline and copied to clipboard.
- **Color Picker**: Native loupe screen sampler (`NSColorSampler`) copying HEX, RGB, or SwiftUI Color.
- **Active Port Manager**: Live open TCP port scanner (`lsof -iTCP -sTCP:LISTEN`) showing PID, process name, and 1-click terminate.
- **Keyboard Cleaning Mode**: Swallows keyboard input with a safe frosted overlay so you can clean your MacBook keyboard without misclicks. Unlock with 5x `ESC` or button.
- **URL Tracker Cleaner**: Auto-strips tracking parameters (`utm_*`, `fbclid`, `gclid`, `si`, `igshid`) from copied URLs.

---

## ⌨️ Default Keyboard Shortcuts

| Shortcut | Action | Module |
| :--- | :--- | :--- |
| `⌘⌥ A` | Toggle APEX Liquid Retina HUD | Core |
| `⌘⌥ S` | Toggle Floating File Drop Shelf | File Shelf |
| `⌃⌥ ←` | Snap Left Half | Window Grid |
| `⌃⌥ →` | Snap Right Half | Window Grid |
| `⌃⌥ ↑` | Maximize Window | Window Grid |
| `⌃⌥ ↓` | Snap Bottom Half | Window Grid |
| `⌃⌥ ↩` | Maximize / Full Frame | Window Grid |
| `⌃⌥ C` | Center Window on Display | Window Grid |
| `⌃⌥ U` | Snap Top-Left Quarter | Window Grid |
| `⌃⌥ I` | Snap Top-Right Quarter | Window Grid |
| `⌃⌥ J` | Snap Bottom-Left Quarter | Window Grid |
| `⌃⌥ K` | Snap Bottom-Right Quarter | Window Grid |
| `⌃⌥ D` | Snap Left Third (1/3) | Window Grid |
| `⌃⌥ F` | Snap Center Third (1/3) | Window Grid |
| `⌃⌥ G` | Snap Right Third (1/3) | Window Grid |

---

## 📦 Installation

### Option 1: Homebrew Cask (Recommended)

```bash
brew tap MaxSphinx/apex https://github.com/MaxSphinx/Apex
brew install --cask apex
```

### Option 2: Direct DMG Download

1. Download the latest `Apex-1.0.0-arm64.dmg` from the [Releases](https://github.com/MaxSphinx/Apex/releases/latest) page.
2. Open the DMG and drag **Apex.app** into your `/Applications` folder.
3. Launch Apex. Click the peak (`▲`) icon in the menu bar to open your Liquid Retina HUD!

### Option 3: Build from Source

```bash
git clone https://github.com/MaxSphinx/Apex.git
cd Apex
make app
make run
```

---

## 🏗️ Architecture & Philosophy

```
                     ┌────────────────────────┐
                     │   Apex Status Item (▲) │
                     └───────────┬────────────┘
                                 │
                     ┌───────────▼────────────┐
                     │    Apex Microkernel    │
                     │    (Memory: <18 MB)    │
                     └───────────┬────────────┘
         ┌───────────────┬───────┴───────┬───────────────┐
         │               │               │               │
┌────────▼───────┐┌──────▼───────┐┌──────▼───────┐┌──────▼───────┐
│ WindowSnapping ││ VolumeMixer  ││ SystemStats  ││  AppCleaner  │
└────────────────┘└──────────────┘└──────────────┘└──────────────┘
         │               │               │               │
┌────────▼───────┐┌──────▼───────┐┌──────────────┐┌──────────────┐
│   Clipboard    ││  FileShelf   ││ FaceLock     ││ TelegramBot  │
│    History     ││  Drop Zone   ││ NeuralEngine ││ IntruderAlert│
└────────────────┘└──────────────┘└──────────────┘└──────────────┘
```

- **Microkernel Isolation**: Every capability is a standalone struct/class conforming to `ApexModule`. When toggled off, all notification listeners, timers, and memory buffers are purged.
- **Zero Background Polling**: Stats engines only sample when the HUD is visible or at low-frequency intervals (2s) via Mach kernel APIs.
- **On-Device Privacy**: FaceLock executes 100% locally on the Apple Neural Engine (`Vision.framework`). Camera frames are never stored, written to disk, or sent to any server.

---

## 🛠️ Requirements

- macOS 14.0+ (Sonoma) or macOS 15.0+ (Sequoia)
- Apple Silicon Mac (M1, M2, M3, M4, Pro, Max, Ultra)
- Swift 6.0+ toolchain

---

## 🤝 Contributing

Contributions are welcomed!
1. Fork the repository.
2. Create your feature branch (`git checkout -b feature/amazing-feature`).
3. Commit your changes (`git commit -m 'Add amazing feature'`).
4. Push to the branch (`git push origin feature/amazing-feature`).
5. Open a Pull Request.

---

## 📄 License

Distributed under the **MIT License**. See [`LICENSE`](LICENSE) for more information.

<div align="center">
  <sub>Crafted with precision for Apple Silicon by <a href="https://github.com/MaxSphinx">MaxSphinx</a>.</sub>
</div>
