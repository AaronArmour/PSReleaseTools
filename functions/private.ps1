#these are internal functions for the PSReleaseTools module

#define an internal function to download the file
Function DL {
    [cmdletbinding(SupportsShouldProcess)]
    Param([string]$Source, [string]$Destination, [string]$hash, [switch]$Passthru)

    Write-Verbose "[$($myinvocation.mycommand)] $Source to $Destination"

    if ($pscmdlet.ShouldProcess($Destination, "Downloading $source")) {
        Invoke-Webrequest -Uri $source -UseBasicParsing -DisableKeepAlive -OutFile $Destination
        Write-Verbose "[DL] Comparing file hash to $hash"
        $f = Get-FileHash -Path $Destination -Algorithm SHA256
        if ($f.hash -ne $hash) {
            Write-Warning "Hash mismatch. $Destination may be incomplete."
        }

        if ($passthru) {
            Get-Item $Destination
        }
    } #should process
} #DL

Function GetData {
    [cmdletbinding()]
    Param(
        [switch]$Preview
    )

    $uri = "https://api.github.com/repos/powershell/powershell/releases"

    Write-Verbose "[$($myinvocation.mycommand)] Getting current release information from $uri"
    $get = Invoke-Restmethod -uri $uri -Method Get -ErrorAction stop

    if ($Preview) {
        Write-Verbose "[$($myinvocation.mycommand)] Getting latest preview"
        ($get).where( {$_.prerelease}) | Select-Object -first 1
    }
    else {
        Write-Verbose "[$($myinvocation.mycommand)] Getting latest stable release"
        ($get).where( { -NOT $_.prerelease}) | Select-Object -first 1
    }
}

Function InstallMsi {
    [cmdletbinding(SupportsShouldProcess)]
    Param(
        [parameter(Mandatory, HelpMessage = "The full path to the MSI file")]
        [string]$Path,
        [Parameter(HelpMessage = "Specify what kind of installation you want. The default if a full interactive install.")]
        [ValidateSet("Full", "Quiet", "Passive")]
        [string]$Mode = "Full"
    )

    Write-Verbose "[$($myinvocation.mycommand)] Creating install command for $Path"

    $cmd = "Start-Process -filepath '$Path' -argumentlist '/$mode'"
    Write-Verbose "[$($myinvocation.mycommand)] Using $Mode mode"
    $sb = [scriptblock]::Create($cmd)

    if ($pscmdlet.ShouldProcess($sb)) {
        Invoke-Command -scriptblock $sb
    }

} #close installmsi