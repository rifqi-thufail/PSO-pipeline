# Development Workflow Scripts
# PowerShell script to run tests across the entire project

param(
    [string]$Mode = "all",
    [switch]$Coverage = $false,
    [switch]$Verbose = $false
)

$ErrorActionPreference = "Stop"

Write-Host "=== PSO Pipeline Test Runner ===" -ForegroundColor Green

# Helper function to run commands with error handling
function Invoke-Command-Safe {
    param([string]$Command, [string]$WorkingDirectory, [string]$Description)
    
    Write-Host "`n--- $Description ---" -ForegroundColor Yellow
    if ($Verbose) { Write-Host "Running: $Command" -ForegroundColor Gray }
    
    $originalLocation = Get-Location
    try {
        if ($WorkingDirectory) { Set-Location $WorkingDirectory }
        
        $result = Invoke-Expression $Command 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "ERROR: $Description" -ForegroundColor Red
            Write-Host $result -ForegroundColor Red
            return $false
        }
        
        Write-Host "SUCCESS: $Description" -ForegroundColor Green
        if ($Verbose) { Write-Host $result -ForegroundColor Gray }
        return $true
    }
    finally {
        Set-Location $originalLocation
    }
}

# Test summary
$testResults = @()

# Backend Tests
if ($Mode -eq "all" -or $Mode -eq "backend") {
    Write-Host "`nBACKEND TESTS" -ForegroundColor Cyan
    
    $backendPath = Join-Path $PWD "backend"
    
    # Install dependencies if node_modules doesn't exist
    if (!(Test-Path (Join-Path $backendPath "node_modules"))) {
        $result = Invoke-Command-Safe "npm install" $backendPath "Installing backend dependencies"
        $testResults += @{ Test = "Backend Dependencies"; Result = $result }
    }
    
    # Run backend tests
    $testCommand = if ($Coverage) { "npm run test:coverage" } else { "npm test -- --passWithNoTests" }
    $result = Invoke-Command-Safe $testCommand $backendPath "Backend unit tests"
    $testResults += @{ Test = "Backend Tests"; Result = $result }
}

# Frontend Tests
if ($Mode -eq "all" -or $Mode -eq "frontend") {
    Write-Host "`nFRONTEND TESTS" -ForegroundColor Cyan
    
    $frontendPath = Join-Path $PWD "frontend"
    
    # Install dependencies if node_modules doesn't exist
    if (!(Test-Path (Join-Path $frontendPath "node_modules"))) {
        $result = Invoke-Command-Safe "npm install" $frontendPath "Installing frontend dependencies"
        $testResults += @{ Test = "Frontend Dependencies"; Result = $result }
    }
    
    # Run frontend tests
    $testCommand = if ($Coverage) { "npm run test:coverage" } else { "npm run test:ci" }
    $result = Invoke-Command-Safe $testCommand $frontendPath "Frontend unit tests"
    $testResults += @{ Test = "Frontend Tests"; Result = $result }
}

# Summary
Write-Host "`n=== TEST SUMMARY ===" -ForegroundColor Green
$allPassed = $true

foreach ($test in $testResults) {
    $status = if ($test.Result) { "PASSED" } else { "FAILED" }
    $color = if ($test.Result) { "Green" } else { "Red" }
    Write-Host "$($test.Test): $status" -ForegroundColor $color
    
    if (!$test.Result) { $allPassed = $false }
}

if ($allPassed) {
    Write-Host "`nAll tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nSome tests failed!" -ForegroundColor Red
    exit 1
}