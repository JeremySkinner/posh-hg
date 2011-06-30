$script:hgCommands = @()

function HgTabExpansion($lastBlock) {
  switch -regex ($lastBlock) { 
    
   #handles hgtk help <cmd>
   #handles hgtk <cmd>
   'thg (help )?(\S*)$' {
     thgCommands($matches[2]);
   }
    
   #handles hg update <branch name>
   #handles hg merge <branch name>
   'hg (up|update|merge|co|checkout) (\S*)$' {
      findBranchOrBookmark($matches[2])
   }
       
   #Handles hg pull -B <bookmark>   
   'hg pull (-\S* )*-(B) (\S*)$' {
     hgRemoteBookmarks($matches[3])
     hgLocalBookmarks($matches[3])
   }
    
   #Handles hg push -B <bookmark>   
   'hg push (-\S* )*-(B) (\S*)$' {
     hgLocalBookmarks($matches[3])
   }
   
   #Handles hg bookmark <bookmark>
   'hg (book|bookmark) (\S*)$' {
      hgLocalBookmarks($matches[2])
   }
    
    #Handles hg push <path>
    #Handles hg pull <path>
    'hg (push|pull) (-\S* )*(\S*)$' {
      hgRemotes($matches[3])
    }
    
    #handles hg help <cmd>
    #handles hg <cmd>
    'hg (help )?(\S*)$' {
      hgCommands($matches[2]);
    }

    #handles hg <cmd> --<option>
    'hg (\S+) (-\S* )*--(\S*)$' {
      hgOptions $matches[1] $matches[3];
    }
    
    #handles hg revert <path>
    'hg revert (\S*)$' {
      hgFiles $matches[1] 'M|A|R|!'
    }
    
    #handles hg add <path>
    'hg add (\S*)$' {
      hgFiles $matches[1] '\?'
    }
    
    # handles hg diff <path>
    'hg diff (\S*)$' {
      hgFiles $matches[1] 'M'
    }
    
    # handles hg commit -(I|X) <path>
    'hg commit (\S* )*-(I|X) (\S*)$' {
      hgFiles $matches[3] 'M|A|R|!'
    }    
  }
}

function hgFiles($filter, $pattern) {
   hg status | 
    foreach { 
      if($_ -match "($pattern){1} (.*)") { 
        $matches[2] 
      } 
    } |
    where { $_ -like "*$filter*" } |
    foreach { if($_ -like '* *') {  "'$_'"  } else { $_ } }
}

function hgRemotes($filter) {
  hg paths | foreach {
    $path = $_.Split("=")[0].Trim();
    if($filter -and $path.StartsWith($filter)) {
      $path
    } elseif(-not $filter) {
      $path
    }
  }
}

# By default the hg command list is populated the first time hgCommands is invoked. 
# Invoke PopulateHgCommands in your profile if you don't want the initial hit. 
function hgCommands($filter) {
  if($script:hgCommands.Length -eq 0) {
    populateHgCommands
  }

  if($filter) {
     $hgCommands | ? { $_.StartsWith($filter) } | % { $_.Trim() } | sort  
  }
  else {
    $hgCommands | % { $_.Trim() } | sort
  }
}

# By default the hg command list is populated the first time hgCommands is invoked. 
# Invoke PopulateHgCommands in your profile if you don't want the initial hit. 
function PopulateHgCommands() {
   $hgCommands = foreach($cmd in (hg help)) {
    # Stop once we reach the "Enabled Extensions" section of help. 
    # Not sure if there's a better way to do this...
    if($cmd -eq "enabled extensions:") {
      break
    }
    
    if($cmd -match '^ (\S+) (.*)') {
        $matches[1]
     }
  }

  if($global:PoshHgSettings.ShowPatches) {
    # MQ integration must be explicitly enabled as the user may not have the extension
    $hgCommands += (hg help mq) | % {
      if($_ -match '^ (\S+) (.*)') {
          $matches[1]
       }
    }
  }
  
  $script:hgCommands = $hgCommands
}

function findBranchOrBookmark($filter){
    hgLocalBranches($filter)
    hgLocalBookmarks($filter)
}

function hgLocalBranches($filter) {
  hg branches -a | foreach {
    if($_ -match "(\S+) .*") {
      if($filter -and $matches[1].StartsWith($filter)) {
        $matches[1]
      }
      elseif(-not $filter) {
        $matches[1]
      }
    }
  }
}

function bookmarkName($bookmark) {
    $split = $bookmark.Split(" ");
        
    if($bookmark.StartsWith("*")) {
        $split[1]
    }
    else{
        $split[0]
    }
}

function hgLocalBookmarks($filter) {
  hg bookmarks | foreach {
    if($_ -match "(\S+) .*") {
      $bookmark = bookmarkName($matches[0])  
      if($filter -and $bookmark.StartsWith($filter)) {
        $bookmark
      }
      elseif(-not $filter) {
        $bookmark
      }
    }
  }
}

function hgRemoteBookmarks($filter) {
  hg incoming -B | foreach {
    if($_ -match "(\S+) .*") {
      if($filter -and $matches[1].StartsWith($filter)) {
        $matches[1]
      }
      elseif(-not $filter) {
        $matches[1]
      }
    }
  }
}

function hgOptions($cmd, $filter) {
	$optList = @()
	$output = hg help $cmd
	foreach($line in $output) {
		if($line -match '^ ((-\S)|  ) --(\S+) .*$') {
			$opt = $matches[3]
			if($filter -and $opt.StartsWith($filter)) {
				$optList += '--' + $opt.Trim()
			}
			elseif(-not $filter) {
				$optList += '--' + $opt.Trim()
			}
		}
	}

	$optList | sort
}

function thgCommands($filter) {
  $cmdList = @()
  $output = thg help
  foreach($line in $output) {
    if($line -match '^ (\S+) (.*)') {
      $cmd = $matches[1]
      if($filter -and $cmd.StartsWith($filter)) {
        $cmdList += $cmd.Trim()
      }
      elseif(-not $filter) {
        $cmdList += $cmd.Trim()
      }
    }
  }
  
  $cmdList | sort 
}