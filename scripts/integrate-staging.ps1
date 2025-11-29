# Branch Integration Script
# PowerShell script to safely merge staging into production with test validation

param(
    [switch]$Force = $false,
    [switch]$DryRun = $false
)

$ErrorActionPreference = "Stop"

Write-Host "=== PSO Pipeline Branch Integration ===" -ForegroundColor Green

# Helper function to run Git commands safely
function Invoke-Git-Safe {
    param([string]$Command, [string]$Description)
    
    Write-Host "`n--- $Description ---" -ForegroundColor Yellow
    Write-Host "Git command: git $Command" -ForegroundColor Gray
    
    if ($DryRun) {
        Write-Host "DRY RUN: Would execute 'git $Command'" -ForegroundColor Cyan
        return $true
    }
    
    try {
        $result = git $Command.Split(' ')
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ FAILED: $Description" -ForegroundColor Red
            return $false
        }
        
        Write-Host "✅ SUCCESS: $Description" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ ERROR: $Description - $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Check if we're in a Git repository
if (!(Test-Path ".git")) {
    Write-Host "❌ Error: Not in a Git repository!" -ForegroundColor Red
    exit 1
}

# Get current branch
$currentBranch = git branch --show-current
Write-Host "Current branch: $currentBranch" -ForegroundColor Cyan

# Ensure we start from main branch
if ($currentBranch -ne "main") {
    Write-Host "Switching to main branch..." -ForegroundColor Yellow
    if (!(Invoke-Git-Safe "checkout main" "Switch to main branch")) { exit 1 }
}

# Check for uncommitted changes
$status = git status --porcelain
if ($status) {
    Write-Host "❌ Error: There are uncommitted changes!" -ForegroundColor Red
    Write-Host "Please commit or stash your changes before integration." -ForegroundColor Yellow
    git status
    exit 1
}

# Fetch latest changes from origin
Write-Host "`n🔄 Fetching latest changes..." -ForegroundColor Cyan
if (!(Invoke-Git-Safe "fetch origin" "Fetch from origin")) { exit 1 }

# Step 1: Update main branch
Write-Host "`n📥 Updating main branch..." -ForegroundColor Cyan
if (!(Invoke-Git-Safe "pull origin main" "Pull latest main")) { exit 1 }

# Step 2: Switch to staging and update
Write-Host "`n🔄 Switching to staging..." -ForegroundColor Cyan
if (!(Invoke-Git-Safe "checkout staging" "Switch to staging")) { exit 1 }
if (!(Invoke-Git-Safe "pull origin staging" "Pull latest staging")) { exit 1 }

# Step 3: Check if staging has changes compared to production
Write-Host "`n🔍 Checking for changes between staging and production..." -ForegroundColor Cyan
$stagingCommit = git rev-parse staging
$productionCommit = git rev-parse production

if ($stagingCommit -eq $productionCommit) {
    Write-Host "ℹ️  No changes to integrate - staging and production are in sync" -ForegroundColor Yellow
    exit 0
}

# Show what changes will be integrated
Write-Host "`n📋 Changes to be integrated:" -ForegroundColor Cyan
git log production..staging --oneline
$changeCount = (git rev-list production..staging --count)
Write-Host "Total commits to integrate: $changeCount" -ForegroundColor Yellow

# Step 4: Run tests on staging
Write-Host "`n🧪 Running tests on staging branch..." -ForegroundColor Cyan
$testScript = Join-Path $PWD "scripts\run-tests.ps1"

if (!(Test-Path $testScript)) {
    Write-Host "❌ Error: Test script not found at $testScript" -ForegroundColor Red
    exit 1
}

if (!$DryRun) {
    & $testScript -Mode "all"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Tests failed on staging branch!" -ForegroundColor Red
        Write-Host "Integration aborted. Please fix tests before merging." -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "DRY RUN: Would run tests on staging" -ForegroundColor Cyan
}

# Step 5: Switch to production and merge
Write-Host "`n🚀 Integrating staging into production..." -ForegroundColor Cyan
if (!(Invoke-Git-Safe "checkout production" "Switch to production")) { exit 1 }
if (!(Invoke-Git-Safe "pull origin production" "Pull latest production")) { exit 1 }

# Merge staging into production
$mergeMessage = "feat: integrate staging changes - $changeCount commits"
if (!(Invoke-Git-Safe "merge staging -m `"$mergeMessage`"" "Merge staging into production")) {
    Write-Host "❌ Merge conflict detected!" -ForegroundColor Red
    Write-Host "Please resolve conflicts manually:" -ForegroundColor Yellow
    Write-Host "1. Resolve conflicts in affected files" -ForegroundColor Gray
    Write-Host "2. Run: git add ." -ForegroundColor Gray
    Write-Host "3. Run: git commit -m 'resolve: merge conflicts from staging'" -ForegroundColor Gray
    Write-Host "4. Run this script again" -ForegroundColor Gray
    exit 1
}

# Step 6: Run tests on production
Write-Host "`n🧪 Running tests on production branch..." -ForegroundColor Cyan
if (!$DryRun) {
    & $testScript -Mode "all"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Tests failed on production branch!" -ForegroundColor Red
        Write-Host "Rolling back merge..." -ForegroundColor Yellow
        git reset --hard HEAD~1
        Write-Host "Merge rolled back. Please investigate test failures." -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "DRY RUN: Would run tests on production" -ForegroundColor Cyan
}

# Step 7: Push to origin (if not dry run)
if (!$DryRun) {
    Write-Host "`n📤 Pushing production branch to origin..." -ForegroundColor Cyan
    if (!(Invoke-Git-Safe "push origin production" "Push production")) { exit 1 }
    
    Write-Host "`n📤 Pushing staging branch to origin..." -ForegroundColor Cyan
    if (!(Invoke-Git-Safe "checkout staging" "Switch back to staging")) { exit 1 }
    if (!(Invoke-Git-Safe "push origin staging" "Push staging")) { exit 1 }
} else {
    Write-Host "DRY RUN: Would push production and staging to origin" -ForegroundColor Cyan
}

# Success summary
Write-Host "`n=== INTEGRATION COMPLETE ===" -ForegroundColor Green
Write-Host "✅ Successfully integrated $changeCount commits from staging to production" -ForegroundColor Green
Write-Host "✅ All tests passed" -ForegroundColor Green
if (!$DryRun) {
    Write-Host "✅ Changes pushed to origin" -ForegroundColor Green
}

# Return to main branch
if (!(Invoke-Git-Safe "checkout main" "Return to main branch")) { 
    Write-Host "⚠️  Warning: Could not switch back to main branch" -ForegroundColor Yellow 
}

Write-Host "`n🎉 Integration workflow completed successfully!" -ForegroundColor Green