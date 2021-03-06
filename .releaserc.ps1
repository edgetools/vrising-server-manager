@{
    RepoUri = 'https://www.github.com/edgetools/vrising-server-manager'
    AuthorName = 'edgetools-ci'
    AuthorEmail = '54470821+edgetools-ci@users.noreply.github.com'
    PushBranch = 'main'
    AllowBumpZeroMajor = $false
    ModuleDirPath = Join-Path -Path $PSScriptRoot -ChildPath 'VRisingServerManager'
    ModuleManifestFilePath = (
            Join-Path -Path $PSScriptRoot -ChildPath 'VRisingServerManager' |
            Join-Path -ChildPath 'VRisingServerManager.psd1')
    ReadmeFilePath = Join-Path -Path $PSScriptRoot -ChildPath 'README.md'
    ChangelogFilePath = Join-Path -Path $PSScriptRoot -ChildPath 'CHANGELOG.md'
    ChangelogHeader = 'Changelog'
    ChangelogCategories = [ordered]@{
        Breaking = ':warning: BREAKING CHANGES :warning:'
        Features = 'Features'
        Fixes = 'Bug Fixes'
        Chores = 'Chores'
    }
    CommitTypes = @{
        'feat' = @{
            Severity = 'Minor'
            Category = 'Features'
        }
        'fix' = @{
            Severity = 'Patch'
            Category = 'Fixes'
        }
        '*' = @{
            Severity = $null
            Category = 'Chores'
        }
    }
    PrunePatterns = @(
        '\[skip[ -]ci\] ?'
    )
}
