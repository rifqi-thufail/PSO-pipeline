# Development Workflow Guide

This guide outlines the complete development workflow for the PSO-pipeline project, including branching strategy, testing, and safe integration practices.

## 📋 Table of Contents

1. [Branching Strategy](#branching-strategy)
2. [Development Workflow](#development-workflow)
3. [Testing Framework](#testing-framework)
4. [Integration Process](#integration-process)
5. [Scripts and Automation](#scripts-and-automation)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

## 🌿 Branching Strategy

### Branch Structure

```
main (development)           ← Default development branch
├── staging                  ← Integration and testing branch  
├── production              ← Stable production-ready code
└── feature/feature-name    ← Feature development branches
```

### Branch Purposes

- **main**: Primary development branch where all feature work is merged
- **staging**: Integration branch for testing changes before production
- **production**: Stable, production-ready code that has passed all tests
- **feature/**: Individual feature development branches

## 🔄 Development Workflow

### 1. Start New Feature

```powershell
# Create and switch to a new feature branch from staging
.\scripts\create-feature.ps1 -FeatureName "user-authentication" -Push
```

### 2. Development Process

```powershell
# Make your changes
git add .
git commit -m "feat: add user authentication endpoint"

# Run tests frequently during development
.\scripts\run-tests.ps1 -Mode backend
.\scripts\run-tests.ps1 -Mode frontend

# Push changes
git push origin feature/user-authentication
```

### 3. Merge to Staging

```powershell
# Switch to staging and get latest
git checkout staging
git pull origin staging

# Merge feature branch
git merge feature/user-authentication

# Run all tests
.\scripts\run-tests.ps1

# Push if tests pass
git push origin staging

# Clean up feature branch
git branch -d feature/user-authentication
git push origin --delete feature/user-authentication
```

### 4. Integration to Production

```powershell
# Use automated integration script
.\scripts\integrate-staging.ps1

# Or dry run first to see what would happen
.\scripts\integrate-staging.ps1 -DryRun
```

## 🧪 Testing Framework

### Backend Testing (Node.js + Jest)

**Location**: `backend/tests/`
**Framework**: Jest + Supertest

```powershell
# Run backend tests
cd backend
npm test

# Run with coverage
npm run test:coverage

# Run in watch mode
npm run test:watch
```

**Test Structure**:
- `tests/models/` - Model unit tests
- `tests/routes/` - API endpoint tests  
- `tests/middleware/` - Middleware tests
- `tests/setup.js` - Test configuration

### Frontend Testing (React + Jest + React Testing Library)

**Location**: `frontend/src/tests/`
**Framework**: Jest + React Testing Library

```powershell
# Run frontend tests
cd frontend
npm test

# Run with coverage
npm run test:coverage

# Run in CI mode (non-interactive)
npm run test:ci
```

**Test Structure**:
- `src/tests/` - Component and utility tests
- `src/setupTests.js` - Test configuration

### Integrated Test Runner

```powershell
# Run all tests
.\scripts\run-tests.ps1

# Run only backend tests
.\scripts\run-tests.ps1 -Mode backend

# Run only frontend tests  
.\scripts\run-tests.ps1 -Mode frontend

# Run with coverage reports
.\scripts\run-tests.ps1 -Coverage
```

## 🚀 Integration Process

### Automated Integration Flow

The integration process follows this sequence:

1. **Validation**: Check for uncommitted changes
2. **Update**: Fetch and pull latest changes
3. **Test Staging**: Run full test suite on staging branch
4. **Merge**: Merge staging into production
5. **Test Production**: Run tests on production branch
6. **Push**: Push production branch to origin
7. **Rollback**: Automatic rollback if tests fail

### Manual Integration Commands

```powershell
# Full automated integration
.\scripts\integrate-staging.ps1

# Dry run to see what would happen
.\scripts\integrate-staging.ps1 -DryRun

# Force integration (skip some validations)
.\scripts\integrate-staging.ps1 -Force
```

## 🔧 Scripts and Automation

### Available Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `run-tests.ps1` | Execute tests across the project | `.\scripts\run-tests.ps1 [options]` |
| `integrate-staging.ps1` | Merge staging to production safely | `.\scripts\integrate-staging.ps1 [options]` |
| `create-feature.ps1` | Create new feature branches | `.\scripts\create-feature.ps1 -FeatureName "name"` |

### Script Options

**run-tests.ps1**:
```powershell
-Mode "all|backend|frontend"  # Which tests to run
-Coverage                     # Generate coverage reports
-Verbose                      # Show detailed output
```

**integrate-staging.ps1**:
```powershell
-DryRun                      # Show what would happen without executing
-Force                       # Skip some validation checks
```

**create-feature.ps1**:
```powershell
-FeatureName "name"          # Required: Feature name
-BaseBranch "staging"        # Base branch (default: staging)
-Push                        # Push branch to origin immediately
```

## 📏 Best Practices

### Commit Messages

Use conventional commit format:
```
feat: add user authentication
fix: resolve login session timeout
docs: update API documentation
test: add user model tests
refactor: simplify dropdown logic
```

### Testing Guidelines

1. **Write tests for new features**: Every new feature should include tests
2. **Run tests before commits**: Use `.\scripts\run-tests.ps1` before pushing
3. **Maintain test coverage**: Aim for >80% test coverage
4. **Test edge cases**: Include error scenarios and boundary conditions

### Branch Management

1. **Keep branches focused**: One feature per branch
2. **Use descriptive names**: `feature/user-authentication`, not `feature/fix`
3. **Delete merged branches**: Clean up after successful merges
4. **Regular updates**: Keep feature branches updated with staging

### Code Quality

1. **Consistent formatting**: Use project linting rules
2. **Code reviews**: Review changes before merging to staging
3. **Documentation**: Update documentation for new features
4. **Error handling**: Include proper error handling and logging

## 🔧 Troubleshooting

### Common Issues

#### Test Failures

```powershell
# Check specific test failures
.\scripts\run-tests.ps1 -Verbose

# Run only failing tests
cd backend
npm test -- --testNamePattern="failing test name"
```

#### Merge Conflicts

```powershell
# If integration script reports conflicts:
git status                    # See conflicted files
# Edit files to resolve conflicts
git add .
git commit -m "resolve: merge conflicts from staging"
.\scripts\integrate-staging.ps1  # Re-run integration
```

#### Branch Sync Issues

```powershell
# Reset staging to match origin
git checkout staging
git fetch origin
git reset --hard origin/staging

# Reset production to match origin  
git checkout production
git fetch origin
git reset --hard origin/production
```

### Recovery Procedures

#### Rollback Production

```powershell
# If production has issues, rollback to previous commit
git checkout production
git log --oneline -n 5        # Find good commit hash
git reset --hard <commit-hash>
git push origin production --force-with-lease
```

#### Restore Feature Branch

```powershell
# If accidentally deleted feature branch
git reflog                    # Find branch commit hash
git checkout -b feature/recovered-branch <commit-hash>
git push origin feature/recovered-branch
```

## 📞 Support

### Key Commands Summary

```powershell
# Quick development cycle
.\scripts\create-feature.ps1 -FeatureName "my-feature" -Push
# ... make changes ...
.\scripts\run-tests.ps1
git add . && git commit -m "feat: implement my feature"
git push origin feature/my-feature

# Merge to staging
git checkout staging && git pull origin staging
git merge feature/my-feature
.\scripts\run-tests.ps1
git push origin staging

# Deploy to production
.\scripts\integrate-staging.ps1
```

### Git Workflow Diagram

```
main
 │
 ├─── feature/user-auth
 │         │
 │         └─── (development)
 │              │
 ├─── staging ←─┘
 │         │
 │         └─── (integration & testing)
 │              │
 ├─── production ←┘
           │
           └─── (stable release)
```

This workflow ensures code quality, proper testing, and safe deployments while maintaining a clear separation between development, testing, and production environments.