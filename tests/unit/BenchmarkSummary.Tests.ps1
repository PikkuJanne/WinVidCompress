BeforeAll {
    $script:Runner=Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'tools/benchmark.ps1'
    . $Runner
}
Describe 'Benchmark projection and repeat arithmetic [WVC-M3-04-A03]' {
    It 'preserves exact token order while replacing only path arguments' {
        $tokens=@('-i','private & source.mov','-metadata','title=copy-01','-crf','22','owned.partial.mp4')
        $safe=@(Get-BenchmarkTokens $tokens 'private & source.mov' 'owned.partial.mp4')
        ($safe -join '|') | Should -BeExactly '-i|<SOURCE>|-metadata|title=copy-01|-crf|22|<OUTPUT>'
    }
    It 'records the measured <Count>-repeat spread without inventing a value' -TestCases @(
        @{Count=2;Values=@(7,3);Median=5;Min=3;Max=7},
        @{Count=3;Values=@(7,3,6);Median=6;Min=3;Max=7}
    ) {
        param($Count,$Values,$Median,$Min,$Max)
        $spread=Get-BenchmarkSpread $Values
        $spread.Count | Should -Be $Count
        $spread.Median | Should -Be $Median
        $spread.Minimum | Should -Be $Min
        $spread.Maximum | Should -Be $Max
        $spread.Range | Should -Be ($Max-$Min)
    }
    It 'leaves an unmeasured spread unavailable' {
        Get-BenchmarkSpread @() | Should -BeNullOrEmpty
    }
}
