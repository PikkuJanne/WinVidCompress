[CmdletBinding()]
param([Parameter(Mandatory = $true)][string]$Manifest)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'LauncherTestSupport.ps1')
$metadata = Get-Content -LiteralPath $Manifest -Raw -Encoding UTF8 | ConvertFrom-Json
$root = Assert-WvcTestRoot $metadata.Owner
foreach ($saved in $metadata.RestoreAcls) {
    $target = [IO.Path]::GetFullPath($saved.Path)
    if (-not $target.StartsWith($root.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw 'ACL restore target escapes the owned fixture root.'
    }
    $acl = Get-Acl -LiteralPath $target
    $acl.SetSecurityDescriptorSddlForm($saved.Sddl)
    Set-Acl -LiteralPath $target -AclObject $acl
}
Remove-WvcTestRoot $metadata.Owner
