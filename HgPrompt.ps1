# For backwards compatibility
$global:HgPromptSettings = $global:VcsStatusSettings

function Write-Prompt($Object, $ForegroundColor, $BackgroundColor = -1) {
    if ($BackgroundColor -lt 0) {
        Write-Host $Object -NoNewLine -ForegroundColor $ForegroundColor
    } else {
        Write-Host $Object -NoNewLine -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor
    }
}

function Write-HgStatus($status = (get-hgStatus $global:VcsStatusSettings.EnableFileStatus $global:VcsStatusSettings.GetBookmarkStatus)) {
    if ($status -and $global:VcsStatusSettings.EnablePromptStatus) {
        $s = $global:VcsStatusSettings
       
        $branchFg = $s.BranchForegroundColor
        $branchBg = $s.BranchBackgroundColor
        
        if($status.Behind) {
          $branchFg = $s.BranchBehindForegroundColor
          $branchBg = $s.BranchBehindBackgroundColor
        }

        if ($status.MultipleHeads) {
          $branchFg = $s.BranchBeheadForegroundColor
          $branchBg = $s.BranchBeheadBackgroundColor
        }
       
        Write-Prompt $s.BeforeText -BackgroundColor $s.BeforeBackgroundColor -ForegroundColor $s.BeforeForegroundColor
        Write-Prompt $status.Branch -BackgroundColor $branchBg -ForegroundColor $branchFg
        
        if($s.ShowStatusWhenZero -or $status.Added) {
          Write-Prompt "$($s.AddedStatusPrefix)$($status.Added)" -BackgroundColor $s.AddedLocalBackgroundColor -ForegroundColor $s.AddedLocalForegroundColor
        }
        if($s.ShowStatusWhenZero -or $status.Modified) {
          Write-Prompt "$($s.ModifiedStatusPrefix)$($status.Modified)" -BackgroundColor $s.ModifiedLocalBackgroundColor -ForegroundColor $s.ModifiedLocalForegroundColor
        }
        if($s.ShowStatusWhenZero -or $status.Deleted) {
          Write-Prompt "$($s.DeletedStatusPrefix)$($status.Deleted)" -BackgroundColor $s.DeletedLocalBackgroundColor -ForegroundColor $s.DeletedLocalForegroundColor
        }
        if($s.ShowStatusWhenZero -or $status.Untracked) {
          Write-Prompt "$($s.UntrackedStatusPrefix)$($status.Untracked)" -BackgroundColor $s.UntrackedLocalBackgroundColor -ForegroundColor $s.UntrackedLocalForegroundColor
        }
        if($s.ShowStatusWhenZero -or $status.Missing) {
           Write-Prompt "$($s.MissingStatusPrefix)$($status.Missing)" -BackgroundColor $s.MissingLocalBackgroundColor -ForegroundColor $s.MissingLocalForegroundColor
        }
        if($s.ShowStatusWhenZero -or $status.Renamed) {
           Write-Prompt "$($s.RenamedStatusPrefix)$($status.Renamed)" -BackgroundColor $s.RenamedLocalBackgroundColor -ForegroundColor $s.RenamedLocalForegroundColor
        }

        if($s.ShowTags -and ($status.Tags.Length -or $status.ActiveBookmark.Length)) {
          Write-Prompt $s.TagPrefix -ForegroundColor $s.TagForegroundColor -BackgroundColor $s.TagBackgroundColor
            
          if($status.ActiveBookmark.Length) {
              Write-Prompt $status.ActiveBookmark -ForegroundColor $s.BranchForegroundColor -BackgroundColor $s.TagBackgroundColor 
              if($status.Tags.Length) {
                Write-Prompt " " -ForegroundColor $s.TagSeparatorForegroundColor -BackgroundColor $s.TagBackgroundColor
              }
          }
         
          $tagCounter=0
          $status.Tags | % {
            Write-Prompt $_ -ForegroundColor $s.TagForegroundColor -BackgroundColor $s.TagBackgroundColor 
        
            if($tagCounter -lt ($status.Tags.Length -1)) {
              Write-Prompt $s.TagSeparator -ForegroundColor $s.TagSeparatorForegroundColor -BackgroundColor $s.TagBackgroundColor
            }
            $tagCounter++;
          }        
        }
        
        if($s.ShowPatches) {
          $patches = Get-MqPatches
          if($patches.All.Length) {
            write-host $s.PatchPrefix -NoNewLine
  
            $patchCounter = 0
            
            $patches.Applied | % {
              Write-Prompt $_ -ForegroundColor $s.AppliedPatchForegroundColor -BackgroundColor $s.AppliedPatchBackgroundColor
              if($patchCounter -lt ($patches.All.Length -1)) {
                Write-Prompt $s.PatchSeparator -ForegroundColor $s.PatchSeparatorColor
              }
              $patchCounter++;
            }
            
            $patches.Unapplied | % {
               Write-Prompt $_ -ForegroundColor $s.UnappliedPatchForegroundColor -BackgroundColor $s.UnappliedPatchBackgroundColor
               if($patchCounter -lt ($patches.All.Length -1)) {
                  Write-Prompt $s.PatchSeparator -ForegroundColor $s.PatchSeparatorColor
               }
               $patchCounter++;
            }
          }
        }
        
       Write-Prompt $s.AfterText -BackgroundColor $s.AfterBackgroundColor -ForegroundColor $s.AfterForegroundColor
    }
}

# Should match https://github.com/dahlbyk/posh-git/blob/master/GitPrompt.ps1
if(!(Test-Path Variable:Global:VcsPromptStatuses)) {
    $Global:VcsPromptStatuses = @()
}
function Global:Write-VcsStatus { $Global:VcsPromptStatuses | foreach { & $_ } }

# Add scriptblock that will execute for Write-VcsStatus
$Global:VcsPromptStatuses += {
    Write-HgStatus
}
# but we don't want any duplicate hooks (if people import the module twice)
$Global:VcsPromptStatuses = $Global:VcsPromptStatuses | Select -Unique