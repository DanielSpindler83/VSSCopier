@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'VSSCopier.psm1'
    # Version number of this module.
    ModuleVersion = '1.0.0'
    # Supported PowerShell editions
    CompatiblePSEditions = @('Desktop', 'Core')
    # ID used to uniquely identify this module
    GUID = '368a3680-9931-4c30-952b-7f20d3a22217'
    # Author of this module
    Author = 'Daniel James Spindler'
    # Company or vendor of this module
    CompanyName = 'Daniel James Spindler'
    # Copyright statement for this module
    Copyright = '(c) 2025 Daniel James Spindler. All rights reserved.'
    # Description of the functionality provided by this module
    Description = 'VSSCopier manages Windows Volume Shadow Copies (VSS), mounts them using symbolic links, and enables filtered file copying from the snapshot. Designed to work in both local and Octopus Deploy environments.'
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.0'
    # Functions to export from this module
    FunctionsToExport = @('*')
    # Cmdlets to export from this module
    CmdletsToExport = @()
    # Variables to export from this module
    VariablesToExport = @()
    # Aliases to export from this module
    AliasesToExport = @()
    # Scripts to process at the beginning of module import
    ScriptsToProcess = @('VSSCopier.ps1')
    # Private data to pass to the module specified in RootModule.
    PrivateData = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('VSS', 'ShadowCopy', 'Backup', 'OctopusDeploy', 'PowerShell', 'VolumeShadowCopy')
            # A URL to the license for this module.
            LicenseUri = 'https://github.com/DanielSpindler83/VSSCopier?tab=Apache-2.0-1-ov-file#readme'
            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/DanielSpindler83/VSSCopier'
            # A URL to an icon representing this module.
            # IconUri = ''
            # ReleaseNotes of this module
            ReleaseNotes = 'Initial public release of VSSCopier. Provides VSS snapshot management and file copying from shadow volumes.'
        }
    }
    # HelpInfo URI of this module
    # HelpInfoURI = ''
    # Default prefix for commands exported from this module
    # DefaultCommandPrefix = ''
}