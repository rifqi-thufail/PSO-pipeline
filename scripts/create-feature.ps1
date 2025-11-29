# Feature Branch Workflow Script
# PowerShell script to create feature branches from staging and prepare for merge

param(
    [Parameter(Mandatory=$true)]
    [string]$FeatureName,
    
    [string]$BaseBranch = "staging",
    [switch]$Push = $false
)

$ErrorActionPreference = "Stop"

Write-Host "=== PSO Pipeline Feature Branch Creator ===" -ForegroundColor Green

# Validate feature name
if ($FeatureName -notmatch "^[a-zA-Z0-9\-_]+$") {
    Write-Host "❌ Error: Feature name must contain only letters, numbers, hyphens, and underscores" -ForegroundColor Red
    exit 1
}

$featureBranchName = "feature/$FeatureName"

# Helper function for Git commands
function Invoke-Git-Safe {
    param([string]$Command, [string]$Description)
    
    Write-Host "Git: $Command" -ForegroundColor Gray
    try {
        $result = git $Command.Split(' ')
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ FAILED: $Description" -ForegroundColor Red
            return $false
        }
        Write-Host "✅ $Description" -ForegroundColor Green
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

# Check for uncommitted changes
$status = git status --porcelain
if ($status) {
    Write-Host "❌ Error: There are uncommitted changes!" -ForegroundColor Red
    Write-Host "Please commit or stash your changes first." -ForegroundColor Yellow
    git status
    exit 1
}

# Check if feature branch already exists
$existingBranch = git branch --list $featureBranchName
if ($existingBranch) {
    Write-Host "❌ Error: Feature branch '$featureBranchName' already exists!" -ForegroundColor Red
    Write-Host "Use a different feature name or delete the existing branch." -ForegroundColor Yellow
    exit 1
}

# Fetch latest changes
Write-Host "`n🔄 Fetching latest changes..." -ForegroundColor Cyan
if (!(Invoke-Git-Safe "fetch origin" "Fetch from origin")) { exit 1 }

# Switch to base branch and update
Write-Host "`n📥 Updating $BaseBranch branch..." -ForegroundColor Cyan
if (!(Invoke-Git-Safe "checkout $BaseBranch" "Switch to $BaseBranch")) { exit 1 }
if (!(Invoke-Git-Safe "pull origin $BaseBranch" "Pull latest $BaseBranch")) { exit 1 }

# Create and switch to feature branch
Write-Host "`n🌟 Creating feature branch: $featureBranchName" -ForegroundColor Cyan
if (!(Invoke-Git-Safe "checkout -b $featureBranchName" "Create feature branch")) { exit 1 }

# Push to origin if requested
if ($Push) {
    Write-Host "`n📤 Pushing feature branch to origin..." -ForegroundColor Cyan
    if (!(Invoke-Git-Safe "push -u origin $featureBranchName" "Push feature branch")) { exit 1 }
}

# Create initial commit with workflow info
$workflowFile = ".feature-workflow"
$workflowContent = @"
# Feature Branch: $featureBranchName
# Created: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
# Base Branch: $BaseBranch
# 
# Workflow:
# 1. Make your changes and commit regularly
# 2. Run tests: .\scripts\run-tests.ps1
# 3. When ready, merge back to staging:
#    - git checkout staging
#    - git pull origin staging  
#    - git merge $featureBranchName
#    - .\scripts\run-tests.ps1
#    - git push origin staging
# 4. Delete feature branch: git branch -d $featureBranchName
"@

$workflowContent | Out-File -FilePath $workflowFile -Encoding UTF8
if (!(Invoke-Git-Safe "add $workflowFile" "Add workflow file")) { exit 1 }
if (!(Invoke-Git-Safe "commit -m `"feat: create feature branch $FeatureName`"" "Initial commit")) { exit 1 }

if ($Push) {
    if (!(Invoke-Git-Safe "push origin $featureBranchName" "Push initial commit")) { exit 1 }
}

# Success message
Write-Host "`n=== FEATURE BRANCH CREATED ===" -ForegroundColor Green
Write-Host "✅ Feature branch: $featureBranchName" -ForegroundColor Green
Write-Host "✅ Based on: $BaseBranch" -ForegroundColor Green
if ($Push) {
    Write-Host "✅ Pushed to origin" -ForegroundColor Green
}

Write-Host "`n📝 Next steps:" -ForegroundColor Yellow
Write-Host "1. Make your feature changes" -ForegroundColor Gray
Write-Host "2. Commit your changes regularly" -ForegroundColor Gray
Write-Host "3. Run tests: .\scripts\run-tests.ps1" -ForegroundColor Gray
Write-Host "4. When ready, merge to staging and run integration" -ForegroundColor Gray

Write-Host "`n🎉 Happy coding!" -ForegroundColor Green