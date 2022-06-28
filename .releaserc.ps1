@{
    RepoUri = 'https://www.github.com/edgetools/vrising-server-manager'
    AllowBumpZeroMajor = $false
    ModuleManifestFilePath = (
            Join-Path -Path $PSScriptRoot -ChildPath 'VRisingServerManager' |
            Join-Path -ChildPath 'VRisingServerManager.psd1')
    ChangelogFilePath = 'CHANGELOG.md'
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
