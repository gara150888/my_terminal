# file path = C:\Users\user\OneDrive\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1


# Remove PowerShell's built-in cls alias
Remove-Item Alias:cls -Force -ErrorAction SilentlyContinue

$paddingX = 20

function prompt {
    $path = (Get-Location).Path
    Write-Host (" " * $paddingX) -NoNewline
    Write-Host "PS $path>" -ForegroundColor White -NoNewline
    return " "
}

function Show-Logo {
    [System.Console]::Clear()

   $time = Get-Date -Format "hh:mm:ss tt"
   $date = Get-Date -Format "dddd, dd MMMM yyyy"

    $logo = @(
""
""	
""
        "██████╗  ███████╗ ██╗   ██╗"
        "██╔══██╗ ██╔════╝ ██║   ██║"
        "██║  ██║ █████╗   ██║   ██║"
        "██║  ██║ ██╔══╝   ╚██╗ ██╔╝"
        "██████╔╝ ███████╗  ╚████╔╝ "
        "╚═════╝  ╚══════╝   ╚═══╝  "
	"$time "
        ""
	"$date"
        ""
    )

    $width = [System.Console]::WindowWidth

    foreach ($line in $logo) {
        $padding = [Math]::Max(0, [Math]::Floor(($width - $line.Length) / 2))
        Write-Host (" " * $padding + $line) -ForegroundColor Red
    }

    Write-Host "" 
}

function cls {
    [System.Console]::Clear()
    Show-Logo
}

Show-Logo

function cpy {
    (Get-Location).Path.Substring(3) | Set-Clipboard
}

function nt {
    wt -w 0 nt -d (Get-Location).Path
}

function fresh {
    . $PROFILE
}

function ai {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Question
    )

    & "C:\Users\vg312\OneDrive\Documents\WindowsPowerShell\ai.ps1" /ai $Question
}
