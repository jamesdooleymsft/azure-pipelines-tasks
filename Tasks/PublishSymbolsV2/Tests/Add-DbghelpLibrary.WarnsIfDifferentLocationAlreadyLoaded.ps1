[CmdletBinding()]
param()

# Arrange.
. $PSScriptRoot\..\..\..\Tests\lib\Initialize-Test.ps1
. $PSScriptRoot\..\IndexHelpers\DbghelpFunctions.ps1
Register-Mock Get-DbghelpPath { "SomeDrive:\AgentHome\...\dbghelp.dll" }
Register-Mock Get-CurrentProcess {
    New-Object psobject -Property @{
            Id = $PID
            Modules = @(
                New-Object psobject -Property @{
                    ModuleName = 'dbghelp.dll'
                    FileName = 'SomeDrive:\SomeDir2\dbghelp.dll'
                }
                New-Object psobject -Property @{
                    ModuleName = 'dbghelp.dll'
                    FileName = 'SomeDrive:\SomeDir3\dbghelp.dll'
                }
            )
        }
}
Register-Mock Invoke-LoadLibrary
Register-Mock Write-Warning

# Act.
Add-DbghelpLibrary 

# Assert.
Assert-WasCalled Invoke-LoadLibrary -Times 0
Assert-WasCalled Write-Warning -Times 2
Assert-WasCalled Write-Warning -- "UnexpectedDbghelpdllExpected0Actual1 $([System.Management.Automation.WildcardPattern]::Escape("SomeDrive:\AgentHome\...\dbghelp.dll")) $([System.Management.Automation.WildcardPattern]::Escape("SomeDrive:\SomeDir2\dbghelp.dll"))"
Assert-WasCalled Write-Warning -- "UnexpectedDbghelpdllExpected0Actual1 $([System.Management.Automation.WildcardPattern]::Escape("SomeDrive:\AgentHome\...\dbghelp.dll")) $([System.Management.Automation.WildcardPattern]::Escape("SomeDrive:\SomeDir3\dbghelp.dll"))"

# Verify that each warning contains both paths and that they are different
Assert-WasCalled Write-Warning -ArgumentsEvaluator {
    $message = $args[0]
    # Extract the two paths from the warning message
    # Format: "UnexpectedDbghelpdllExpected0Actual1 <path1> <path2>"
    $parts = $message -split ' ', 3
    if ($parts.Count -ne 3) {
        Write-Host "Expected 3 parts in warning message, got $($parts.Count)"
        return $false
    }
    $path1 = $parts[1]
    $path2 = $parts[2]
    # Verify the paths are different
    if ($path1 -eq $path2) {
        Write-Host "Warning contains the same path twice: $path1"
        return $false
    }
    return $true
}
