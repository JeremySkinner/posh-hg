# Inspired by Mark Embling
# http://www.markembling.info/view/my-ideal-powershell-prompt-with-git-integration
function Set-VcsStatusSettings {
    [CmdletBinding()]
param(
    [ConsoleColor]$DefaultForegroundColor    = $Host.UI.RawUI.ForegroundColor,
    [ConsoleColor]$DefaultBackgroundColor    = $Host.UI.RawUI.BackgroundColor,

    # Retrieval settings
    [Switch]$EnablePromptStatus        = !$Global:GitMissing,
    [Switch]$EnableFileStatus          = $true,
    [Switch]$ShowStatusWhenZero        = $true,
    [String[]]$RepositoriesInWhichToDisableFileStatus = @( ), # Array of repository paths

    #Before prompt
    [String]$BeforeText                      = ' [',
    [ConsoleColor]$BeforeForegroundColor     = $([ConsoleColor]::Yellow),
    [ConsoleColor]$BeforeBackgroundColor     = $DefaultBackgroundColor,

    #After prompt
    [String]$AfterText                       = '] ',
    [ConsoleColor]$AfterForegroundColor      = $([ConsoleColor]::Yellow),
    [ConsoleColor]$AfterBackgroundColor      = $DefaultBackgroundColor,

    # Branches
    [ConsoleColor]$BranchForegroundColor       = $([ConsoleColor]::Cyan),
    [ConsoleColor]$BranchBackgroundColor       = $DefaultBackgroundColor,
    # Current branch when not updated
    [ConsoleColor]$BranchBehindForegroundColor = $([ConsoleColor]::Red),
    [ConsoleColor]$BranchBehindBackgroundColor = $DefaultBackgroundColor,
    # Current branch when we're both
    [ConsoleColor]$BranchBeheadForegroundColor = $([ConsoleColor]::Magenta),
    [ConsoleColor]$BranchBeheadBackgroundColor = $DefaultBackgroundColor,

    # Working DirectoryColors
    [String]$AddedStatusPrefix                       = ' +',
    [ConsoleColor]$AddedLocalForegroundColor      = $([ConsoleColor]::Green),
    [ConsoleColor]$AddedLocalBackgroundColor      = $DefaultBackgroundColor,

    [String]$ModifiedStatusPrefix                    = ' ~',
    [ConsoleColor]$ModifiedLocalForegroundColor   = $([ConsoleColor]::Blue),
    [ConsoleColor]$ModifiedLocalBackgroundColor   = $DefaultBackgroundColor,

    [String]$DeletedStatusPrefix                     = ' -',
    [ConsoleColor]$DeletedLocalForegroundColor    = $([ConsoleColor]::Red),
    [ConsoleColor]$DeletedLocalBackgroundColor    = $DefaultBackgroundColor,

    [String]$UntrackedStatusPrefix                   = ' !',
    [ConsoleColor]$UntrackedLocalForegroundColor  = $([ConsoleColor]::Magenta),
    [ConsoleColor]$UntrackedLocalBackgroundColor  = $DefaultBackgroundColor,

    # Mercurial Specific ============================
    [String]$RenamedStatusPrefix                  = ' ^',
    [ConsoleColor]$RenamedLocalForegroundColor    = $([ConsoleColor]::Yellow),
    [ConsoleColor]$RenamedLocalBackgroundColor    = $DefaultBackgroundColor,

    [String]$MissingStatusPrefix                  = ' !',
    [ConsoleColor]$MissingLocalForegroundColor    = $([ConsoleColor]::Cyan),
    [ConsoleColor]$MissingLocalBackgroundColor    = $DefaultBackgroundColor,
    
    [Switch]$GetBookmarkStatus                    = $true    ,
    
    #Tag list
    [Switch]$ShowTags                             = $true,
    [String]$TagPrefix                            = ' ',
    [String]$TagSeparator                         = ", ",
    [ConsoleColor]$TagForegroundColor             = $([ConsoleColor]::DarkGray),
    [ConsoleColor]$TagSeparatorForegroundColor    = $([ConsoleColor]::White),
    [ConsoleColor]$TagBackgroundColor             = $DefaultBackgroundColor,
    
    # MQ Integration
    [Switch]$ShowPatches                          = $false,
    [String]$PatchPrefix                          = ' patches: ',
    [ConsoleColor]$UnappliedPatchForegroundColor  = $([ConsoleColor]::DarkGray),
    [ConsoleColor]$UnappliedPatchBackgroundColor  = $DefaultBackgroundColor,
    [ConsoleColor]$AppliedPatchForegroundColor    = $([ConsoleColor]::DarkYellow),
    [ConsoleColor]$AppliedPatchBackgroundColor    = $DefaultBackgroundColor,
    [String]$PatchSeparator                       = ' › ',
    [ConsoleColor]$PatchSeparatorColor            = $([ConsoleColor]::White  )

)

    if($global:VcsStatusSettings) {
        ## Sync the Background Colors: 
        ## If the DefaultBackgroundColor is changed
        if($PSBoundParameters.ContainsKey("DefaultBackgroundColor") -and ($global:VcsStatusSettings.DefaultBackgroundColor -ne $DefaultBackgroundColor)) {
            ## Any other background colors
            foreach($Background in $global:VcsStatusSettings.PsObject.Properties | Where { $_.Name -like "*BackgroundColor"} | % { $_.Name }) {
                # Which haven't been set
                if(!$PSBoundParameters.ContainsKey($Background)) {
                    if((!$global:VcsStatusSettings.$Background) -or ($global:VcsStatusSettings.$Background -eq $global:VcsStatusSettings.DefaultBackgroundColor)) {
                        # And are currently synced with the DefaultBackgroundColor
                        $PSBoundParameters.Add($Background, $DefaultBackgroundColor)
                    }
                }
            }
        }

        foreach($key in $PSBoundParameters.Keys) {
            $global:VcsStatusSettings | Add-Member NoteProperty $key $PSBoundParameters.$key -Force
        }
        ## Mercurial Specific: Set them if they've never been set:
        if(!(Get-Member -In $global:VcsStatusSettings -Name ShowTags)){
            $global:VcsStatusSettings | Add-Member NoteProperty RenamedStatusPrefix $RenamedStatusPrefix -Force
            $global:VcsStatusSettings | Add-Member NoteProperty RenamedLocalForegroundColor $RenamedLocalForegroundColor -Force
            $global:VcsStatusSettings | Add-Member NoteProperty RenamedLocalBackgroundColor $RenamedLocalBackgroundColor -Force
            $global:VcsStatusSettings | Add-Member NoteProperty MissingStatusPrefix $MissingStatusPrefix -Force
            $global:VcsStatusSettings | Add-Member NoteProperty MissingLocalForegroundColor $MissingLocalForegroundColor -Force
            $global:VcsStatusSettings | Add-Member NoteProperty MissingLocalBackgroundColor $MissingLocalBackgroundColor -Force
            $global:VcsStatusSettings | Add-Member NoteProperty GetBookmarkStatus $GetBookmarkStatus -Force
            $global:VcsStatusSettings | Add-Member NoteProperty ShowTags $ShowTags -Force
            $global:VcsStatusSettings | Add-Member NoteProperty TagPrefix $TagPrefix -Force
            $global:VcsStatusSettings | Add-Member NoteProperty TagSeparator $TagSeparator -Force
            $global:VcsStatusSettings | Add-Member NoteProperty TagForegroundColor $TagForegroundColor -Force
            $global:VcsStatusSettings | Add-Member NoteProperty TagSeparatorForegroundColor $TagSeparatorForegroundColor -Force
            $global:VcsStatusSettings | Add-Member NoteProperty TagBackgroundColor $TagBackgroundColor -Force
            $global:VcsStatusSettings | Add-Member NoteProperty ShowPatches $ShowPatches -Force
            $global:VcsStatusSettings | Add-Member NoteProperty PatchPrefix $PatchPrefix -Force
            $global:VcsStatusSettings | Add-Member NoteProperty UnappliedPatchForegroundColor $UnappliedPatchForegroundColor -Force
            $global:VcsStatusSettings | Add-Member NoteProperty UnappliedPatchBackgroundColor $UnappliedPatchBackgroundColor -Force
            $global:VcsStatusSettings | Add-Member NoteProperty AppliedPatchForegroundColor $AppliedPatchForegroundColor -Force
            $global:VcsStatusSettings | Add-Member NoteProperty AppliedPatchBackgroundColor $AppliedPatchBackgroundColor -Force
            $global:VcsStatusSettings | Add-Member NoteProperty PatchSeparator $PatchSeparator -Force
            $global:VcsStatusSettings | Add-Member NoteProperty PatchSeparatorColor $PatchSeparatorColor -Force
        }

    } else {
        $global:VcsStatusSettings = New-Object PSObject -Property @{
            DefaultBackgroundColor = $DefaultBackgroundColor

            # Retreival settings
            EnablePromptStatus = $EnablePromptStatus
            EnableFileStatus = $EnableFileStatus
            RepositoriesInWhichToDisableFileStatus = $RepositoriesInWhichToDisableFileStatus       

            #Before prompt        
            BeforeText = $BeforeText
            BeforeForegroundColor = $BeforeForegroundColor
            BeforeBackgroundColor = $BeforeBackgroundColor

            #After prompt
            AfterText = $AfterText
            AfterForegroundColor = $AfterForegroundColor
            AfterBackgroundColor = $AfterBackgroundColor

            BranchForegroundColor = $BranchForegroundColor
            BranchBackgroundColor = $BranchBackgroundColor
            BranchAheadForegroundColor = $BranchAheadForegroundColor
            BranchAheadBackgroundColor = $BranchAheadBackgroundColor
            BranchBehindForegroundColor = $BranchBehindForegroundColor
            BranchBehindBackgroundColor = $BranchBehindBackgroundColor

            BranchBeheadForegroundColor = $BranchBeheadForegroundColor
            BranchBeheadBackgroundColor = $BranchBeheadBackgroundColor

            # WorkingColors
            AddedStatusPrefix = $AddedStatusPrefix
            AddedLocalForegroundColor    = $AddedLocalForegroundColor   
            AddedLocalBackgroundColor    = $AddedLocalBackgroundColor   
            
            ModifiedStatusPrefix = $ModifiedStatusPrefix
            ModifiedLocalForegroundColor = $ModifiedLocalForegroundColor
            ModifiedLocalBackgroundColor = $ModifiedLocalBackgroundColor
            
            DeletedStatusPrefix = $DeletedStatusPrefix
            DeletedLocalForegroundColor  = $DeletedLocalForegroundColor 
            DeletedLocalBackgroundColor  = $DeletedLocalBackgroundColor 
            
            UntrackedStatusPrefix = $UntrackedStatusPrefix
            UntrackedLocalForegroundColor = $UntrackedLocalForegroundColor
            UntrackedLocalBackgroundColor = $UntrackedLocalBackgroundColor

            Debug = $DebugPreference -eq "Continue"

            # Mercurial Specific ============================
            RenamedStatusPrefix = $RenamedStatusPrefix
            RenamedLocalForegroundColor = $RenamedLocalForegroundColor
            RenamedLocalBackgroundColor = $RenamedLocalBackgroundColor

            MissingStatusPrefix = $MissingStatusPrefix
            MissingLocalForegroundColor = $MissingLocalForegroundColor
            MissingLocalBackgroundColor = $MissingLocalBackgroundColor

            GetBookmarkStatus = $GetBookmarkStatus

            ShowTags = $ShowTags
            TagPrefix = $TagPrefix
            TagSeparator = $TagSeparator
            TagForegroundColor = $TagForegroundColor
            TagSeparatorForegroundColor = $TagSeparatorForegroundColor
            TagBackgroundColor = $TagBackgroundColor

            ShowPatches = $ShowPatches
            PatchPrefix = $PatchPrefix
            UnappliedPatchForegroundColor = $UnappliedPatchForegroundColor
            UnappliedPatchBackgroundColor = $UnappliedPatchBackgroundColor
            AppliedPatchForegroundColor = $AppliedPatchForegroundColor
            AppliedPatchBackgroundColor = $AppliedPatchBackgroundColor
            PatchSeparator = $PatchSeparator
            PatchSeparatorColor = $PatchSeparatorColor
        }
    }
}

# Make sure this runs at least once (when the module is initially imported)
Set-VcsStatusSettings
