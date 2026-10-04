. (Join-Path $PSScriptRoot 'TestSupport.ps1')

function Assert-WvcFixtureProbe($Probe, $Definition) {
    $streams = @($Probe.streams)
    if ($streams.Count -ne @($Definition.ExpectedStreams).Count) { throw 'Unexpected fixture stream count.' }
    for ($index = 0; $index -lt $streams.Count; $index++) {
        foreach ($property in $Definition.ExpectedStreams[$index].PSObject.Properties) {
            if ($property.Name -eq 'default') { $value = $streams[$index].disposition.default }
            elseif ($property.Name -eq 'language') { $value = $streams[$index].tags.language }
            else { $value = $streams[$index].($property.Name) }
            if ("$value" -ne "$($property.Value)") { throw ('Unexpected fixture stream property: ' + $property.Name) }
        }
    }
    $duration = [double]::Parse($Probe.format.duration, [Globalization.CultureInfo]::InvariantCulture)
    if ([double]::IsNaN($duration) -or [double]::IsInfinity($duration) -or
        $duration -lt $Definition.DurationSeconds.Minimum -or $duration -gt $Definition.DurationSeconds.Maximum) {
        throw 'Fixture duration outside one-second tolerance.'
    }
}

function New-WvcFixtures($Owner, [string]$FFmpeg, [string]$FFprobe) {
    $root = Assert-WvcTestRoot $Owner
    $destination = Join-Path $root 'fixtures'
    if (Test-Path -LiteralPath $destination) { throw 'Fixture directory already exists; refusing reuse.' }
    [void][IO.Directory]::CreateDirectory($destination)
    $inventoryPath = Join-Path $PSScriptRoot 'fixtures/inventory.json'
    $definitions = Get-Content -LiteralPath $inventoryPath -Raw | ConvertFrom-Json
    $entries = @()
    foreach ($definition in $definitions.Items) {
        $output = [IO.Path]::GetFullPath((Join-Path $destination $definition.File))
        if ([IO.Path]::GetFileName($output) -ne $definition.File -or
            -not $output.StartsWith($destination + '\', [StringComparison]::OrdinalIgnoreCase)) {
            throw 'Fixture inventory path escapes destination.'
        }
        $status = 'Passed'
        $reason = ''
        try {
            if ($definition.Kind -eq 'ProbeJson') {
                Copy-Item -LiteralPath (Join-Path (Join-Path $PSScriptRoot 'fixtures') $definition.Source) -Destination $output
            } elseif (-not $FFmpeg -or -not $FFprobe) {
                $status = 'Skipped'
                $reason = 'FFmpeg/FFprobe unavailable; media generation and probe not tested.'
            } else {
                $arguments = @($definition.Arguments | ForEach-Object { if ($_ -eq '{output}') { $output } else { $_ } })
                $generated = Invoke-WvcTestProcess $FFmpeg $arguments
                [IO.File]::WriteAllText((Join-Path $destination ($definition.Id + '.stderr.log')), $generated.StdErr)
                if ($generated.ExitCode -ne 0) { throw 'FFmpeg fixture generation failed; see local stderr log.' }
                if (-not (Test-Path -LiteralPath $output -PathType Leaf) -or (Get-Item -LiteralPath $output).Length -eq 0) {
                    throw 'FFmpeg returned zero without a nonempty fixture.'
                }
                $probeArgs = @($definition.ProbeArguments | ForEach-Object { if ($_ -eq '{output}') { $output } else { $_ } })
                $probed = Invoke-WvcTestProcess $FFprobe $probeArgs
                [IO.File]::WriteAllText((Join-Path $destination ($definition.Id + '.probe.stderr.log')), $probed.StdErr)
                if ($probed.ExitCode -ne 0) { throw 'FFprobe fixture validation failed; see local stderr log.' }
                $probe = $probed.StdOut | ConvertFrom-Json
                Assert-WvcFixtureProbe $probe $definition
            }
        } catch {
            $status = 'Failed'
            $reason = 'Fixture creation/structural check failed; inspect local diagnostics.'
            [IO.File]::WriteAllText((Join-Path $destination ($definition.Id + '.error.log')), $_.ToString())
        }
        $entries += [pscustomobject][ordered]@{
            Id = $definition.Id; File = $definition.File; Kind = $definition.Kind
            Status = $status; Reason = $reason; Generated = ($status -eq 'Passed')
            Arguments = $definition.Arguments; Requires = $definition.Requires
            ProbeArguments = $(if ($definition.PSObject.Properties['ProbeArguments']) { $definition.ProbeArguments } else { @() })
            DurationSeconds = $(if ($definition.PSObject.Properties['DurationSeconds']) { $definition.DurationSeconds } else { $null })
            Source = $(if ($definition.PSObject.Properties['Source']) { $definition.Source } else { $null })
            InvalidResponse = $(if ($definition.PSObject.Properties['InvalidResponse']) { $definition.InvalidResponse } else { $false })
            RequiredCapabilities = $definition.RequiredCapabilities
            ExpectedStreams = $definition.ExpectedStreams; Capabilities = $definition.Capabilities
            Provenance = $definition.Provenance; CleanupOwner = $definition.CleanupOwner
        }
    }
    $report = [pscustomobject][ordered]@{ SchemaVersion = 1; Items = $entries }
    Write-WvcTestJson (Join-Path $destination 'inventory.json') $report
    $report
}
