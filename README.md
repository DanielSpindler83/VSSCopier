# VSSCopier

`VSSCopier` is a PowerShell class for managing **Volume Shadow Copies (VSS)** on Windows systems. It supports creating snapshots, mounting them via symbolic links, copying files from the shadow copy, and cleaning up—all with support for **local environments** and **Octopus Deploy**.

---

## 📦 Installation

### Option 1: Clone the Repo

```powershell
git clone https://github.com/DanielSpindler83/VSSCopier.git
cd VSSCopier
Import-Module ./VSSCopier.psm1
```

### Option 2: Manual Download

1. [Download the ZIP](https://github.com/DanielSpindler83/VSSCopier/archive/refs/heads/main.zip)
2. Extract it
3. Import the module:

```powershell
Import-Module ./VSSCopier-main/VSSCopier.psm1
```

---

## 🚀 Quick Start

```powershell
# Create an instance with default mount root (C:\MountShadow)
$copier = [VSSCopier]::new()

# Or with a custom mount root
$copier = [VSSCopier]::new("D:\Mounts")
```

Mount root is the path that created shadow copies are mounted into.

---

## 🔧 Methods & Examples

### Create a Shadow Copy

```powershell
$copier.CreateShadowCopy("C:\Data")
```

> Creates a shadow copy of the volume containing `C:\Data`. A symbolic link to the snapshot is created in the mount path.

---

### Copy Files from Shadow Copy

```powershell
$copier.CopyFilesFromShadowCopy("C:\Data\Logs", "D:\Backups\Logs")
```

> Copies all `.log` files from the snapshot version of `C:\Data\Logs` to `D:\Backups\Logs`.

You can also specify a custom file pattern:

```powershell
$copier.CopyFilesFromShadowCopy("C:\Data", "D:\Backups", "*.txt")
```

---

### Cleanup a Shadow Copy

```powershell
$copier.Cleanup()
```

> Removes the created shadow copy, symbolic link, and the temporary mount directory.

Or use:

```powershell
$copier.Dispose()
```

> This is an alias for `Cleanup()` to support explicit disposal semantics.

---

### List All Shadow Copies

```powershell
$copier.ListAllShadowCopies() | Format-Table
```

> Returns a list of all shadow copies on the system.

---

### Print All Shadow Copies with Logging

```powershell
$copier.ListAllShadowCopiesWriteLog()
```

> Logs each shadow copy to the output (or Octopus logs if applicable).

---

### Delete All Shadow Copies

```powershell
$copier.CleanupAllShadowCopies()
```

> Forcefully deletes all shadow copies present on the system.

---

## 💡 Notes

- ⚠️ **Requires Administrator privileges**
- 🧪 Tested on Windows 10/11 with PowerShell 5.1
- 💼 Works in Octopus Deploy environments (auto-detects and uses `Write-Highlight` if available)
- 💥 Uses `Win32_ShadowCopy`, `CIM`, `WMI`, and `mklink` for VSS handling

---

## 📁 Structure

This module contains a single PowerShell class: `VSSCopier`, located in `VSSCopier.psm1`.

You can extend or wrap it in functions if desired for alternative usage patterns.

---

## 🤝 License

Apache-2.0 license – use freely, modify, contribute back!

---

## 📫 Contact / Contribute

Issues and PRs welcome. Feel free to fork and submit improvements!

Made with 💻 by Daniel James Spindler