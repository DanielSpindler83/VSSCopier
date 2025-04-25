<#
Class: VSSCopier

Summary:
VSSCopier manages Windows Volume Shadow Copies (VSS), mounts them using symbolic links, and enables filtered file copying from the snapshot. Designed to work in both local and Octopus Deploy environments.

Constructors:
- [VSSCopier]::new()
  Initializes using default mount root path "C:\MountShadow".

- [VSSCopier]::new("D:\CustomMountPath")
  Initializes with a custom mount root path.

Public Methods:

- CreateShadowCopy([string]$sourcePath)
  Creates a shadow copy of the volume containing the given source path.
  Example: $copier.CreateShadowCopy("C:\Data")

- CopyFilesFromShadowCopy([string]$sourcePath, [string]$destinationPath, [string]$logFilePattern = "*.log")
  Copies files matching the pattern from the shadow copy to the destination folder.
  Example: $copier.CopyFilesFromShadowCopy("C:\Data\Logs", "D:\Backup\Logs")

- Cleanup()
  Deletes the current shadow copy, symbolic link, and mount directory.
  Example: $copier.Cleanup()

- Dispose()
  Alias for Cleanup() to support explicit cleanup semantics.
  Example: $copier.Dispose()

- ListAllShadowCopies()
  Returns all shadow copies on the system as an array of objects.
  Example: $copier.ListAllShadowCopies() | Format-Table

- ListAllShadowCopiesWriteLog()
  Logs all existing shadow copies with detailed info.
  Example: $copier.ListAllShadowCopiesWriteLog()

- CleanupAllShadowCopies()
  Deletes all shadow copies currently present on the system.
  Example: $copier.CleanupAllShadowCopies()
#>


class VSSCopier {
    [string]$MountRoot
    [string]$MountPoint
    [string]$ShadowCopyID
    [string]$LinkPath
    [string]$DevicePath
    [bool]$IsInOctopus

    VSSCopier([string]$customMountRoot) {
        $this.Initialize($customMountRoot)
    }

    VSSCopier() {
        $this.Initialize("C:\MountShadow")
    }

    hidden [void]Initialize([string]$mountRoot) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $this.MountRoot = $mountRoot
        $this.MountPoint = Join-Path -Path $this.MountRoot -ChildPath "ShadowCopy_$timestamp"

        $this.IsInOctopus = $this.DetectOctopusEnvironment()
        $this.WriteLog("Environment detection: Running in Octopus = $($this.IsInOctopus)")

        if (!(Test-Path $this.MountRoot)) {
            New-Item -ItemType Directory -Path $this.MountRoot -Force | Out-Null
        }

        New-Item -ItemType Directory -Path $this.MountPoint -Force | Out-Null
    }

    hidden [bool]DetectOctopusEnvironment() {
        try {
            return (Get-Variable -Name "OctopusParameters" -ErrorAction SilentlyContinue) -ne $null
        }
        catch {
            return $false
        }
    }

    hidden [void]WriteLog([string]$message) {
        if ($this.IsInOctopus) {
            try {
                Write-Highlight $message
            } catch {
                Write-Host $message
            }
        } else {
            Write-Host $message
        }
    }

    [void]CreateShadowCopy([string]$sourcePath) {
        try {
            $volume = (Get-Item $sourcePath).PSDrive.Root
            $this.WriteLog("Creating shadow copy for volume: $volume")

            $shadowCopy = Invoke-CimMethod -ClassName Win32_ShadowCopy -MethodName Create -Arguments @{ Volume = $volume }
            $this.ShadowCopyID = $shadowCopy.ShadowID

            $shadowInfo = Get-WmiObject -Class Win32_ShadowCopy | Where-Object { $_.ID -eq $this.ShadowCopyID }
            $this.DevicePath = $shadowInfo.DeviceObject
            $this.WriteLog("Device object path: $($this.DevicePath)")

            $this.LinkPath = Join-Path -Path $this.MountPoint -ChildPath "Volume"
            cmd /c "mklink /D `"$($this.LinkPath)`" `"$($this.DevicePath)\`"" | Out-Null
            $this.WriteLog("Mounted shadow copy at $($this.LinkPath)")
            $this.WriteLog("---") # spacer
        }
        catch {
            Write-Error "Error creating shadow copy: $_"
        }
    }

    [void]CopyFilesFromShadowCopy([string]$sourcePath, [string]$destinationPath, [string]$logFilePattern = "*.log") {
        try {
            if (!(Test-Path $destinationPath)) {
                New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
            }

            $relativePath = $sourcePath.Substring(2)
            $shadowSourcePath = Join-Path -Path $this.LinkPath -ChildPath $relativePath

            if (-not (Test-Path $shadowSourcePath)) {
                throw "Shadow source path does not exist: $shadowSourcePath"
            }

            $this.WriteLog("Copying files from: $shadowSourcePath")
            $this.WriteLog("Copying files to: $destinationPath")
            $this.WriteLog("") # spacer

            $files = Get-ChildItem -Path $shadowSourcePath -Filter $logFilePattern -ErrorAction Stop

            if ($files.Count -eq 0) {
                $this.WriteLog("No matching log files found.")
            } else {
                foreach ($file in $files) {
                    $this.WriteLog("Copying $($file.Name)")
                    Copy-Item -Path $file.FullName -Destination $destinationPath -Force
                }
                $this.WriteLog("$($files.Count) files copied successfully to $destinationPath")
                $this.WriteLog("---") # spacer
            }
        }
        catch {
            Write-Error "Error copying files: $_"
        }
    }

    [void]Cleanup() {
        if ($this.ShadowCopyID) {
            $this.WriteLog("Deleting shadow copy ID: $($this.ShadowCopyID)")
            Get-WmiObject Win32_ShadowCopy | Where-Object { $_.ID -eq $this.ShadowCopyID } | Remove-WmiObject
            $this.ShadowCopyID = $null
        }

        if ($this.LinkPath -and (Test-Path $this.LinkPath)) {
            $this.WriteLog("Removing symbolic link at: $($this.LinkPath)")
            cmd /c "rmdir `"$($this.LinkPath)`"" | Out-Null
        }

        if ($this.MountPoint -and (Test-Path $this.MountPoint)) {
            $this.WriteLog("Removing mount point folder: $($this.MountPoint)")
            Remove-Item -Path $this.MountPoint -Force
        }
        $this.WriteLog("---") # spacer
    }

    [void]Dispose() {
        $this.Cleanup()
    }

    [object[]]ListAllShadowCopies() {
        try {
            $shadowCopies = Get-WmiObject -Class Win32_ShadowCopy

            $result = @()
            foreach ($shadowCopy in $shadowCopies) {
                $result += [PSCustomObject]@{
                    ID              = $shadowCopy.ID
                    DeviceObject    = $shadowCopy.DeviceObject
                    VolumeName      = $shadowCopy.VolumeName
                    CreationDate    = $shadowCopy.InstallDate
                    ClientAccessible = $shadowCopy.ClientAccessible
                }
            }

            if ($result.Count -eq 0) {
                $this.WriteLog("No shadow copies found on the system.")
            }

            return $result
        }
        catch {
            Write-Error "Error listing shadow copies: $_"
            return @()
        }
    }

    [void]ListAllShadowCopiesWriteLog() {
        try {
            $this.WriteLog("Listing all shadow copies on the system...")
            $this.WriteLog("") # spacer

            $shadowCopies = $this.ListAllShadowCopies()

            foreach ($entry in $shadowCopies) {
                $this.WriteLog("ShadowCopy ID:      $($entry.ID)")
                $this.WriteLog("  DeviceObject:     $($entry.DeviceObject)")
                $this.WriteLog("  VolumeName:       $($entry.VolumeName)")
                $this.WriteLog("  CreationDate:     $($entry.CreationDate)")
                $this.WriteLog("  ClientAccessible: $($entry.ClientAccessible)")
                $this.WriteLog("") # spacer
            }
            $this.WriteLog("---") # spacer
        }
        catch {
            Write-Error "Error printing shadow copies: $_"
        }
    }


    [void]CleanupAllShadowCopies() {
        try {
            $shadowCopies = Get-WmiObject -Class Win32_ShadowCopy
            $count = $shadowCopies.Count

            $this.WriteLog("Attempting to cleanup all shadow copies on the system.")

            if ($count -eq 0) {
                $this.WriteLog("No shadow copies found to delete.")
                $this.WriteLog("---") # spacer
                return
            }

            $this.WriteLog("Deleting $count shadow copies on the system.")

            foreach ($shadowCopy in $shadowCopies) {
                $this.WriteLog("Deleting shadow copy ID: $($shadowCopy.ID)")
                $shadowCopy | Remove-WmiObject
            }

            $this.WriteLog("Successfully deleted $count shadow copies.")
            $this.WriteLog("---") # spacer
        }
        catch {
            Write-Error "Error cleaning up all shadow copies: $_"
        }
    }

}