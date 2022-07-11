# Copyright (C) 2022 github.com/edgetools Ethan Edwards
# Licensed under the MIT License
# see LICENSE.txt

# a bespoke powershell 5.1+ release management script
# inspired by the semantic-release and conventional-commits projects
# https://www.conventionalcommits.org/en/v1.0.0/#summary

[CmdletBinding(DefaultParameterSetName='Publish', SupportsShouldProcess)]
param(
    [Parameter(ParameterSetName='Publish')]
    [switch]$Publish,
    [Parameter(ParameterSetName='Publish')]
    [string]$ApiKey,
    [Parameter(ParameterSetName='LibraryMode')]
    [switch]$LibraryMode,

    [string]$StartRef
)

$ErrorActionPreference = 'Stop'

<#
$commit = @{
    Body = @'
feat(foo): added feature to foo

this is a new feature for foo

BREAKING CHANGE: this breaks the
way that the thing worked
before with the stuff
- also does this
Signed-by: Foo <foo@foo.foo>
Closes #5
'@
    ShortHash = 'f8e250b'
    FullHash = 'f8e250bce88d3815e930fca415293d6b7de6135d'
}

$commitWithBodySegments = @{
    Subject = 'feat(foo): added feature to foo'
    Description = @'

this is a new feature for foo
'@
    Footers = @(
        @{
            Key = 'BREAKING CHANGE'
            Value = @'
this breaks the
way that the thing worked
before with the stuff
- also does this
'@
        }
        @{
            Key = 'Signed-by'
            Value = 'Foo <foo@foo.foo>'
        },
        @{
            Key = 'Closes'
            Value = '#5'
        }
    )
    ShortHash = 'f8e250b'
    FullHash = 'f8e250bce88d3815e930fca415293d6b7de6135d'
}
#>

function SplitByNewlines($stringData) {
    return $stringData.Split(@("`r`n", "`r", "`n"), [System.StringSplitOptions]::None)
}

function RenderChangeText($changeText) {
    $rendered = [System.Collections.ArrayList]::New()
    $changeTextLines = SplitByNewlines $changeText
    if ($changeTextLines.Count -eq 1) {
        [void] $rendered.Add("* $changeTextLines")
    } elseif ($changeTextLines.Count -gt 1) {
        [void] $rendered.Add("* $($changeTextLines[0])")
    }
    for ($i = 1; $i -lt $changeTextLines.Count; $i++) {
        [void] $rendered.Add("  $($changeTextLines[$i])")
    }
    return $rendered.ToArray([string]) -join [System.Environment]::NewLine
}

function RenderChange([string]$repoUri, [hashtable]$change) {
    <#
    # a regular change
    $change = @{
        Subject = 'foo is now bar'
        Scope = $null
        FullHash = '7e45d844ba444d8493821b884e29163487c39fc2'
        ShortHash = '7e45d84'
    }
    # a breaking change from a footer
    # with multi-line content
    $change = @{
        Text = @'
added a new thing
here's details about it:
- it's cool
'@
    }
    #>
    if ($false -eq [string]::IsNullOrWhiteSpace($change.Text)) {
        # render multi-line text object
        # and short-circuit
        $rendered = RenderChangeText $change.Text
        return $rendered
    }
    # add bullet point -> "* "
    $rendered = '* '
    if ($false -eq [string]::IsNullOrWhiteSpace($change.Scope)) {
        # add optional scope -> "foo: "
        $rendered += "**$($change.Scope):** "
    }
    # add subject and link to commit -> "bar (1234abc)"
    $rendered += "$($change.Subject) ([$($change.ShortHash)]($($repoUri)/commit/$($change.FullHash)))"
    return $rendered
}

function RenderCategory([string]$repoUri, [string]$name, [hashtable[]]$changes) {
    <#
    $name = 'Foo'
    $changes = @(
        @{
            Subject = 'foo is now bar'
            Scope = $null
            FullHash = '7e45d844ba444d8493821b884e29163487c39fc2'
            ShortHash = '7e45d84'
        }
    )
    #>
    $rendered = [System.Collections.ArrayList]::New()
    [void] $rendered.Add("### $name")
    [void] $rendered.Add('')
    foreach ($change in $changes) {
        $renderedChange = RenderChange $repoUri $change
        [void] $rendered.Add($renderedChange)
    }
    return $rendered.ToArray([string]) -join [System.Environment]::NewLine
}

function RenderVersion([string]$repoUri, [string]$version, [string]$previousVersion) {
    if (($false -eq [string]::IsNullOrWhiteSpace($previousVersion)) -and
            ($version -ne $previousVersion)) {
        $versionUri = "$($repoUri)/compare/$previousVersion...$version"
    } else {
        $versionUri = "$($repoUri)/tree/$version"
    }
    $date = Get-Date -Format 'yyyy-MM-dd'
    $renderedVersion = "## [$version]($versionUri) ($date)"
    return $renderedVersion
}

function RenderChangelogHeader([string]$changelogHeader) {
    return "# $changelogHeader$([System.Environment]::NewLine)"
}

function RenderChangelog(
        [string]$repoUri,
        [string]$nextVersion,
        [string]$previousVersion,
        [System.Collections.Specialized.OrderedDictionary]$changelog) {
    <#
    $repoUri = 'https://www.github.com/foo/bar'
    $nextVersion = '1.2.3'
    $previousVersion = '1.2.2'
    $changelog = [ordered]@{
        'BREAKING CHANGES' = @(
            @{
                Subject = 'grabbed two sticks and bent them'
                Scope = $null
                FullHash = '761711878877302486f160f8f274f07ae9f60097'
                ShortHash = '7617118'
            },
            @{
                Text = 'bar no longer foos'
            },
            @{
                Text = @'
added a new feature with multiple different stuffs

- great new stuffs

- even more great stuffs
- some sub stuffs, too!

if you like the stuffs, check out the uri:
https://edgetools.dev/foo
'@
            }
        )
        'Features' = @(
            @{
                Subject = 'added feature to foobar'
                Scope = 'foobar'
                FullHash = '05c802c5e44114ca0aa18be65924554a0d6b2e73'
                ShortHash = '05c802c'
            }
        )
        'Bug Fixes' = @(
            @{
                Scope = $null
                Subject = 'fixed problem with thing'
                FullHash = '7ce6a8f48326ff4242bc8c8bc286e2a6fe225304'
                ShortHash = '7ce6a8f'
            },
            @{
                Scope = $null
                Subject = 'reset thing with stuff'
                FullHash = '976160a5a2371dbdb18d4d8401f36b17143151aa'
                ShortHash = '976160a'
            }
        )
    }
    #>
    $renderedChanges = [System.Collections.ArrayList]::New()
    # render the version
    $renderedVersion = RenderVersion $repoUri $nextVersion $previousVersion
    [void] $renderedChanges.Add($renderedVersion)
    # render changes
    foreach ($category in $changelog.GetEnumerator()) {
        if ($category.Value.Count -gt 0) {
            $categoryName = $category.Name
            $categoryChanges = $category.Value
            $renderedCategory = RenderCategory $repoUri $categoryName $categoryChanges
            [void] $renderedChanges.Add('')
            [void] $renderedChanges.Add($renderedCategory)
        }
    }
    return $renderedChanges.ToArray([string]) -join [System.Environment]::NewLine
}

function GetCommitLogFormatString() {
    $sep = '%x00'
    $rawBody = '%B' # always has an unnecessary newline after it
    # https://stackoverflow.com/questions/71412477/git-log-pretty-b-but-without-newline-after-the-body
    # https://stackoverflow.com/questions/58016135/format-string-for-consistent-separation-between-entries-output-by-git-log-pre
    $trimNewline = '%-C()' # neat
    $shortHash = '%h'
    $fullHash = '%H'
    # using rawBody since it will get split into subject / description later
    # using shortHash and fullHash so shortHash length can change upstream if they want to
    return "${rawBody}${trimNewline}${sep}${shortHash}${sep}${fullHash}"
}

function GetLatestSemanticGitTag() {
    $tags = git tag --list
    if ($LASTEXITCODE -ne 0) {
        throw "git command failed"
    }
    $semanticVersions = $tags | Where-Object { $_ -match '\d+\.\d+\.\d+' } | ForEach-Object { GetSemanticVersion $_ }
    $latestTag = $semanticVersions | Sort-Object Major,Minor,Patch -Descending | Select-Object -First 1
    return $latestTag
}

function GitTagExists($tag) {
    $gitTagOutput = git tag --list "$tag"
    if ($LASTEXITCODE -ne 0) {
        throw "git command failed"
    }
    $gitTag = ($gitTagOutput | Out-String).TrimEnd()
    return $tag -eq $gitTag
}

function GetRefForVersion($version) {
    if ([string]::IsNullOrWhiteSpace($version)) {
        return $null
    }
    $versionTagExists = GitTagExists $version
    if ($true -eq $versionTagExists) {
        return "refs/tags/$version"
    }
    return $null
}

function GitTagVersion(
        [string]$authorName,
        [string]$authorEmail,
        [string]$message,
        [string]$version) {
    if ([string]::IsNullOrWhiteSpace($version)) {
        throw "version cannot be null"
    }
    $message | git `
        -c "user.name=$authorName" `
        -c "user.email=$authorEmail" `
        tag -a --file - --cleanup=whitespace $version
    if ($LASTEXITCODE -ne 0) {
        throw "git command failed"
    }
}

function GitAddFiles([string[]]$files) {
    foreach ($file in $files) {
        git add $file
        if ($LASTEXITCODE -ne 0) {
            throw "git command failed"
        }
    }
}

function CreateReleaseCommit(
        [string]$authorName,
        [string]$authorEmail,
        [string]$version) {
    git `
        -c "user.name=$authorName" `
        -c "user.email=$authorEmail" `
        commit -m "chore: [skip ci] release $version"
    if ($LASTEXITCODE -ne 0) {
        throw "git command failed"
    }
}

function GetCommitLogUsingGit($startRef) {
    # --no-pager: ensure it doesn't paginate
    # -z: separate with NULL char
    # --format: custom format
    $commitLog = $null
    if ($false -eq [string]::IsNullOrWhiteSpace($startRef)) {
        $commitLog = git --no-pager log -z --format=$(GetCommitLogFormatString) "$startRef..HEAD" | Out-String
    } else {
        $commitLog = git --no-pager log -z --format=$(GetCommitLogFormatString) | Out-String
    }
    if ($LASTEXITCODE -ne 0) {
        throw "git command failed"
    }
    return $commitLog
}

function ParseGitCommitLog($commitLog) {
    $commits = [System.Collections.ArrayList]::new()
    $remainingLog = $commitLog
    while ($false -eq [string]::IsNullOrWhiteSpace($remainingLog)) {
        $body, $shortHash, $fullHash, $remainingLog = $remainingLog.Split("`0", 4)
        $commit = @{
            Body = $body
            ShortHash = $shortHash
            FullHash = $fullHash
        }
        [void] $commits.Add($commit)
    }
    Write-Output $commits.ToArray([hashtable]) -NoEnumerate
    return
}

function IsFooter($commitLine) {
    $taglineFooterPattern = '^\w+[-\w]*(: | #){1,}[\s\S]+$'
    $breakingFooterPattern = '^BREAKING[- ]CHANGE: [\s\S]+$'
    return (($commitLine -match $taglineFooterPattern) -or
            ($commitLine -match $breakingFooterPattern))
}

function ExtractSegmentsFromCommitBody($commitBody) {
    # https://www.conventionalcommits.org/en/v1.0.0/#summary
    # relevant rules:
    #  8. One or more footers MAY be provided one blank line after the body.
    #     Each footer MUST consist of a word token, followed by either a :<space> or <space># separator,
    #     followed by a string value (this is inspired by the git trailer convention).
    #  9. A footer’s token MUST use `-` in place of whitespace characters,
    #     e.g., `Acked-by` (this helps differentiate the footer section from a multi-paragraph body).
    #     An exception is made for `BREAKING CHANGE`, which MAY also be used as a token.
    # 10. A footer’s value MAY contain spaces and newlines, and parsing MUST terminate
    #     when the next valid footer token/separator pair is observed.
    # 11. Breaking changes MUST be indicated in the type/scope prefix of a commit,
    #     or as an entry in the footer.
    # 12. If included as a footer, a breaking change MUST consist of
    #     the uppercase text `BREAKING CHANGE`, followed by a colon, space, and description,
    #     e.g., `BREAKING CHANGE: environment variables now take precedence over config files.`
    # 13. If included in the type/scope prefix, breaking changes MUST be indicated by a `!` immediately
    #     before the `:`. If `!` is used, `BREAKING CHANGE:` MAY be omitted from the footer section,
    #     and the commit description SHALL be used to describe the breaking change.
    # 15. The units of information that make up Conventional Commits MUST NOT be
    #     treated as case sensitive by implementors, with the exception
    #     of `BREAKING CHANGE` which MUST be uppercase.
    # 16. BREAKING-CHANGE MUST be synonymous with BREAKING CHANGE, when used as a token in a footer.
    $commitBodyLines = SplitByNewlines $commitBody
    $extractedSubject = $null
    if ($commitBodyLines.Count -eq 1) {
        $extractedSubject = $commitBodyLines
    } elseif ($commitBodyLines.Count -gt 1) {
        $extractedSubject = $commitBodyLines[0]
    }
    $descriptionBuilder = [System.Collections.ArrayList]::New()
    $extractedFooters = [System.Collections.ArrayList]::New()
    for ($i = 1; $i -lt $commitBodyLines.Count; $i++) {
        # check if we've reached a footer
        # if not, add it to the description
        if ($true -eq (IsFooter $commitBodyLines[$i])) {
            # (to satisfy #10 above) need to continue reading lines after a matching footer
            # until another footer is encountered or the end is reached
            $footerBuilder = [System.Collections.ArrayList]::New()
            [void] $footerBuilder.Add($commitBodyLines[$i])
            for ($j = $i+1; $j -lt $commitBodyLines.Count; $j++) {
                if ($true -eq (IsFooter $commitBodyLines[$j])) {
                    # encountered another footer which terminates processing
                    # set the outer iterator so that the next loop
                    # will start processing the upcoming footer
                    $i = $j - 1
                    break # return to the outer loop
                } else {
                    [void] $footerBuilder.Add($commitBodyLines[$j])
                }
            }
            $footerString = [string]::Join([System.Environment]::NewLine, $footerBuilder.ToArray([string]))
            [void] $extractedFooters.Add($footerString)
        } else {
            [void] $descriptionBuilder.Add($commitBodyLines[$i])
        }
    }
    $extractedDescription = [string]::Join([System.Environment]::NewLine, $descriptionBuilder.ToArray([string]))
    return @{
        Subject = $extractedSubject
        Description = $extractedDescription
        Footers = $extractedFooters.ToArray([string])
    }
}

function ConvertFootersIntoKeyValue($footers) {
    $footerMap = [System.Collections.ArrayList]::New()
    foreach ($footer in $footers) {
        $taglineFooterExtractionPatternA = '^(\w+[-\w]*): ([\s\S]+)'
        $matchResult = Select-String `
            -InputObject $footer `
            -Pattern $taglineFooterExtractionPatternA
        if (($null -eq $matchResult) -or
                ($false -eq $matchResult.Matches.Success)) {
            $taglineFooterExtractionPatternB = '^(\w+[-\w]*) (#[\s\S]+)'
            $matchResult = Select-String `
                -InputObject $footer `
                -Pattern $taglineFooterExtractionPatternB
            if (($null -eq $matchResult) -or
                    ($false -eq $matchResult.Matches.Success)) {
                $breakingFooterExtractionPattern = '^(BREAKING[- ]CHANGE): ([\s\S]+)'
                $matchResult = Select-String `
                    -InputObject $footer `
                    -Pattern $breakingFooterExtractionPattern
                if (($null -eq $matchResult) -or
                        ($false -eq $matchResult.Matches.Success)) {
                    throw "footer failed to parse: $footer"
                }
            }
        }
        $match = @{
            Key = $matchResult.Matches.Groups[1].Value
            Value = $matchResult.Matches.Groups[2].Value
        }
        [void] $footerMap.Add($match)
    }
    Write-Output $footerMap.ToArray() -NoEnumerate
    return
}

function PruneCommitBody([string]$commitBody, [string[]]$prunePatterns) {
    foreach ($prunePattern in $prunePatterns) {
        if ($commitBody -match $prunePattern) {
            $commitBody = $commitBody -replace $prunePattern
        }
    }
    return $commitBody
}

function ParseCommitBodies($commits, [string[]]$prunePatterns) {
    $commitsWithBodySegments = [System.Collections.ArrayList]::New()
    foreach ($commit in $commits) {
        $prunedCommitBody = PruneCommitBody $commit.Body $prunePatterns
        $commitBodySegments = ExtractSegmentsFromCommitBody $prunedCommitBody
        $footers = ConvertFootersIntoKeyValue $commitBodySegments.Footers
        $commitWithBodySegments = @{
            Subject = $commitBodySegments.Subject
            Description = $commitBodySegments.Description
            Footers = $footers
            ShortHash = $commit.ShortHash
            FullHash = $commit.FullHash
        }
        [void] $commitsWithBodySegments.Add($commitWithBodySegments)
    }
    Write-Output $commitsWithBodySegments.ToArray() -NoEnumerate
    return
}

function ParseConventionalCommitSubjectForDetails($subject) {
    # group 1: type
    # group 3: scope
    # group 4: breaking flag
    # group 5: description
    $conventionalCommitExtractionPattern = '^(\w+)(\(([\w-_ ]+)\))?(!)?: (.*)$'
    $matchResult = Select-String `
        -InputObject $subject `
        -Pattern $conventionalCommitExtractionPattern
    if ($false -eq $matchResult.Matches.Success) {
        throw "commit subject failed to parse: $subject"
    }
    return @{
        Type = $matchResult.Matches.Groups[1].Value
        Scope = $matchResult.Matches.Groups[3].Value
        Subject = $matchResult.Matches.Groups[5].Value
        IsBreaking = ('!' -eq $matchResult.Matches.Groups[4].Value)
    }
}

function GetChangelogCategoryForType($categories, $commitTypes, $commitType) {
    $category = $null
    if (($false -eq [string]::IsNullOrWhiteSpace($commitType)) -and
            ($true -eq $commitTypes.ContainsKey($commitType))) {
        $category = $commitTypes[$commitType].Category
    } elseif ($true -eq $commitTypes.ContainsKey('*')) {
        $category = $commitTypes['*'].Category
    } else {
        throw "unrecognized commit type: $commitType"
    }
    if ($true -eq ([string]::IsNullOrWhiteSpace($category))) {
        throw [System.ArgumentNullException]::New('category', "no Category found for Type $commitType")
    }
    if ($false -eq $categories.Contains($category)) {
        throw "Category $category not found"
    }
    return $category
}

function IsConventionalCommitSubject($commitSubject) {
    $conventionalCommitPattern = '^\w+(\([\w-_ ]+\))?!?: .*$'
    return ($commitSubject -match $conventionalCommitPattern)
}

function IdentifyBreakingFooters($footers) {
    $breakingFooters = [System.Collections.ArrayList]::New()
    $otherFooters = [System.Collections.ArrayList]::New()
    foreach ($footer in $footers) {
        $breakingFooterIdentificationPattern = '^BREAKING[- ]CHANGE'
        if ($footer.Key -match $breakingFooterIdentificationPattern) {
            [void] $breakingFooters.Add($footer)
        } else {
            [void] $otherFooters.Add($footer)
        }
    }
    # this doesn't need Write-Output -NoEnumerate because we're intentionally returning two objects
    # so even if one is a single object, it won't get unraveled
    return $breakingFooters.ToArray(),$otherFooters.ToArray()
}

function UnwrapBreakingFooters($breakingFooters) {
    $unwrappedBreakingFooters = [System.Collections.ArrayList]::New()
    foreach ($footer in $breakingFooters) {
        [void] $unwrappedBreakingFooters.Add($footer.Value)
    }
    Write-Output $unwrappedBreakingFooters.ToArray([string]) -NoEnumerate
    return
}

function GetSeverityForType($commitTypes, $commitType) {
    if (($false -eq [string]::IsNullOrWhiteSpace($commitType)) -and
            ($commitTypes.ContainsKey($commitType))) {
        return $commitTypes[$commitType].Severity
    } elseif ($commitTypes.ContainsKey('*')) {
        return $commitTypes['*'].Severity
    } else {
        throw "unrecognized commit type: $commitType"
    }
}

function GetSeverityForCommit($isBreaking, $commitTypes, $commitType) {
    if ($true -eq $isBreaking) {
        $commitSeverity = 'Major'
    } else {
        $commitSeverity = GetSeverityForType $commitTypes $commitType
    }
    return $commitSeverity
}

function GetConventionalCommits($changelogCategories, $commitTypes, $commits) {
    $conventionalCommits = [System.Collections.ArrayList]::New()
    foreach ($commit in $commits) {
        if ($true -eq (IsConventionalCommitSubject $commit.Subject)) {
            $conventionalCommitDetails = ParseConventionalCommitSubjectForDetails $commit.Subject
            $breakingFooters, $otherFooters = IdentifyBreakingFooters $commit.Footers
            $unwrappedBreakingFooters = UnwrapBreakingFooters $breakingFooters
            $isBreaking = (($true -eq $conventionalCommitDetails.IsBreaking) -or
                ($unwrappedBreakingFooters.Count -gt 0))
            $severity = GetSeverityForCommit $isBreaking $commitTypes $conventionalCommitDetails.Type
            $changelogCategory = GetChangelogCategoryForType `
                $changelogCategories `
                $commitTypes `
                $conventionalCommitDetails.Type
            $conventionalCommit = @{
                Type = $conventionalCommitDetails.Type
                Scope = $conventionalCommitDetails.Scope
                Subject = $conventionalCommitDetails.Subject
                Severity = $severity
                BreakingFlag = $conventionalCommitDetails.IsBreaking
                ChangelogCategory = $changelogCategory
                BreakingFooters = $unwrappedBreakingFooters
                OtherFooters = $otherFooters
                ShortHash = $commit.ShortHash
                FullHash = $commit.FullHash
            }
            [void] $conventionalCommits.Add($conventionalCommit)
        }
    }
    Write-Output $conventionalCommits.ToArray() -NoEnumerate
    return
}

function GetSemanticVersion($versionString) {
    $major, $minor, $patch = $versionString -split '\.'
    return [PSCustomObject]@{
        Major = [int]$major
        Minor = [int]$minor
        Patch = [int]$patch
    }
}

function GetStringVersion($semanticVersion) {
    if ($null -eq $semanticVersion) {
        return $null
    }
    $versionString = "$($semanticVersion.Major).$($semanticVersion.Minor).$($semanticVersion.Patch)"
    return $versionString
}

function BumpMajorVersion($semanticVersion) {
    return [PSCustomObject]@{
        Major = $semanticVersion.Major + 1
        Minor = 0
        Patch = 0
    }
}

function BumpMinorVersion($semanticVersion) {
    return [PSCustomObject]@{
        Major = $semanticVersion.Major
        Minor = $semanticVersion.Minor + 1
        Patch = 0
    }
}

function BumpPatchVersion($semanticVersion) {
    return [PSCustomObject]@{
        Major = $semanticVersion.Major
        Minor = $semanticVersion.Minor
        Patch = $semanticVersion.Patch + 1
    }
}

function BumpSemanticVersion($semanticVersion, $versionChange, $allowBumpZeroMajor) {
    # this supports semver <1.0.0 versions
    # if the input major version is 0, then any Major bumps
    # will be converted to Minor bumps
    # example:
    #   0.0.1 -> Major -> 0.1.0
    #   0.0.1 -> Minor -> 0.1.0
    #   0.0.1 -> Patch -> 0.0.2
    if ($true -eq [string]::IsNullOrWhiteSpace($versionChange)) {
        # this allows a null input version to return a null output version
        # (an effective no-op when versions are compared after)
        return $semanticVersion
    }
    if ($null -eq $semanticVersion) {
        # default to 0.0.0
        # then bump according to the instructed bump
        $semanticVersion = GetSemanticVersion '0.0.0'
    }
    if ('Major' -eq $versionChange) {
        if (($semanticVersion.Major -eq 0) -and ($true -ne $allowBumpZeroMajor)) {
            return BumpMinorVersion $semanticVersion
        } else {
            return BumpMajorVersion $semanticVersion
        }
    } elseif ('Minor' -eq $versionChange) {
        return BumpMinorVersion $semanticVersion
    } elseif ('Patch' -eq $versionChange) {
        return BumpPatchVersion $semanticVersion
    }
}

function GetVersionChangeFromCommits($conventionalCommits) {
    # this is a 'batch style' method
    # which means it will take a list of version changes and
    # batch them into a single change
    # example:
    #   Major, Major, Minor -> Major
    #   Minor, Minor, Patch -> Minor
    #   Patch, Patch, Patch -> Patch
    $commitSeverityList = $conventionalCommits |
        ForEach-Object { $_.Severity }
    if ('Major' -in $commitSeverityList) {
        return 'Major'
    } elseif ('Minor' -in $commitSeverityList) {
        return 'Minor'
    } elseif ('Patch' -in $commitSeverityList) {
        return 'Patch'
    }
}

function WriteModuleVersion($semanticVersion, $manifestPath) {
    $stringVersion = GetStringVersion $semanticVersion
    Update-ModuleManifest `
        -Path $manifestPath `
        -ModuleVersion $stringVersion
}

function VersionsAreEqual($leftVersion, $rightVersion) {
    $versionsAreEqual = (
        ($leftVersion.Major -eq $rightVersion.Major) -and
        ($leftVersion.Minor -eq $rightVersion.Minor) -and
        ($leftVersion.Patch -eq $rightVersion.Patch))
    return $versionsAreEqual
}

function CreateChangelogSkeleton($changelogCategories) {
    $changelog = [ordered]@{}
    foreach ($key in $changelogCategories.Keys) {
        $categoryName = $changelogCategories[$key]
        $changelog[$categoryName] = [hashtable[]]@()
    }
    return $changelog
}

function GenerateChangelogFromCommits($changelogCategories, [hashtable[]]$conventionalCommits) {
    $changelog = CreateChangelogSkeleton $changelogCategories
    foreach ($commit in $conventionalCommits) {
        $breakingCategoryName = $changelogCategories['Breaking']
        if ($true -eq $commit.BreakingFlag) {
            # if "foo!:", switch to Breaking category
            $categoryName = $breakingCategoryName
        } else {
            $categoryName = $changelogCategories[$commit.ChangelogCategory]
        }
        foreach ($footer in $commit.BreakingFooters) {
            # add breaking footers
            $changelog[$breakingCategoryName] += @(
                @{
                    Text = $footer
                }
            )
        }
        if ($null -eq $commit.Severity) {
            # skip adding commits without a severity
            continue
        }
        $changelog[$categoryName] += @(
            @{
                Subject = $commit.Subject
                Scope = $commit.Scope
                FullHash = $commit.FullHash
                ShortHash = $commit.ShortHash
            }
        )
    }
    return $changelog
}

function ReadFile($path) {
    if ($false -eq (Test-Path -LiteralPath $path)) {
        return $null
    }
    (Get-Content -LiteralPath $path -Raw).TrimEnd()
}

function WriteFile($path, $content) {
    Out-File -FilePath $path -InputObject $content
}

function UpdateChangelog($oldChangelog, $newHeader, $newChangelog) {
    <#
    $oldChangelog = @"
# Changelog

## [0.0.1](https://www.github.com/foo/bar/tree/0.0.1) (2022-07-06)

### Chores

* update badge link ([d462315](https://www.github.com/foo/bar/commit/d462315243036407ec8b442319f3b2e09b91f41a))
* update badge ([5636649](https://www.github.com/foo/bar/commit/5636649d5479c04f38bdad3bc9b19598ffc9fe54))
* add badge ([3245ecf](https://www.github.com/foo/bar/commit/3245ecfab461e62158c312b9f3b5434393383dc7))
"@

    $newHeader = '# Changelog'
    $newChangelog = @"
## [1.0.0](https://www.github.com/foo/bar/compare/0.0.1...1.0.0) (2022-07-07)

### :warning: BREAKING CHANGES :warning:

* added a new thing

  here's details about it:
  - it's cool
* this is one of the breaking changes
* plus other stuff broke worse
* **baz:** new stuff that does stuff ([A23B544](https://www.github.com/foo/bar/commit/A23B5445456065b9a3d01050ad79343b0224c2ee))     

### Bug Fixes

* **foo-bar:** prevent racing of requests ([562f3b4](https://www.github.com/foo/bar/commit/562f3b45456065b9a3d01050ad79343b0224c2ee))

### Chores

* updated the docs ([c743c15](https://www.github.com/foo/bar/commit/c743c154af70e8074e588f69d875bd065f205e96))
"@
    #>
    $updatedChangelog = @(
        $newHeader,
        [System.Environment]::NewLine,
        $newChangelog)
    if ($false -eq [string]::IsNullOrWhiteSpace($oldChangelog)) {
        if ($oldChangelog.Count -gt 1) {
            $oldChangelogWithoutHeader = ($oldChangelog | Select-Object -Skip 1) -join [System.Environment]::NewLine
        } else {
            $oldChangelogWithoutHeader = (SplitByNewlines $oldChangelog | Select-Object -Skip 1) -join [System.Environment]::NewLine
        }
        $updatedChangelog += @(
            [System.Environment]::NewLine,
            $oldChangelogWithoutHeader)
    }
    return $updatedChangelog -join ''
}

function UpdateReadme($oldReadme, $changelog) {
    $findPattern = '<!-- begin release notes -->[\s\S]*<!-- end release notes -->'
    $replaceString = "<!-- begin release notes -->$([System.Environment]::NewLine)$changelog$([System.Environment]::NewLine)<!-- end release notes -->"
    $oldReadme -replace $findPattern,$replaceString
}

function PickVersionToUse($tagVersion, $fileVersion) {
    if ($null -ne $tagVersion) {
        return $tagVersion
    } else {
        return $fileVersion
    }
}

function ReadModuleManifest($path) {
    $dataFile = Import-PowerShellDataFile -LiteralPath $path
    return $dataFile
}

function UpdateModuleManifest($path, $newVersion, $releaseNotes) {
    Update-ModuleManifest `
        -Path $path `
        -ModuleVersion $newVersion `
        -ReleaseNotes $releaseNotes
}

function PushGitRepo([string]$branch, [string]$version) {
    git push origin "refs/heads/$branch" "refs/tags/$version"
    if ($LASTEXITCODE -ne 0) {
        throw "git command failed"
    }
}

function SanitizeMarkdown([string]$markdown) {
    # immediately assign so it's easier to move around the commands after
    # without worrying about putting $markdown in the wrong spot
    $sanitizedMarkdown = $markdown

    # remove all links
    $sanitizedMarkdown = $sanitizedMarkdown -replace '\[([^\n\r]+)\]\([^\n\r()]*\)','$1'

    # replace asterisk style indent with dashes
    $sanitizedMarkdown = $sanitizedMarkdown -replace '(^ *|[\n\r] *)\* ','$1- '

    # remove header marks
    $sanitizedMarkdown = $sanitizedMarkdown -replace '(^|[\n\r])#+ ','$1'

    # remove double asterisk bolding
    $sanitizedMarkdown = $sanitizedMarkdown -replace '\*\*(.+)\*\*+','$1'
    # remove single asterisk italics
    $sanitizedMarkdown = $sanitizedMarkdown -replace '\*(.+)\*+','$1'

    # remove double underline italics
    $sanitizedMarkdown = $sanitizedMarkdown -replace '__(.+)__+','$1'
    # remove single underline italics
    $sanitizedMarkdown = $sanitizedMarkdown -replace '_(.+)_+','$1'

    # output
    $sanitizedMarkdown
}

function LoadRunCommandsFile() {
    $cwdRCFilePath = Join-Path -Path (Get-Location) -ChildPath '.releaserc.ps1'
    if ($true -eq (Test-Path -LiteralPath $cwdRCFilePath -PathType Leaf)) {
        & $cwdRCFilePath
    }
}

function DoMain(
        [bool]$dryRun,
        [bool]$publish,
        [string]$apiKey,
        [string]$startRef) {
    $rcFile = LoadRunCommandsFile
    $previousVersion = GetLatestSemanticGitTag
    if ($false -eq [string]::IsNullOrWhiteSpace($previousVersion)) {
        Write-Host "Previous version is $(GetStringVersion $previousVersion)"
    } else {
        Write-Host "No previous version found"
    }
    if ($true -eq [string]::IsNullOrWhiteSpace($startRef)) {
        $lastReleaseRef = GetRefForVersion $(GetStringVersion $previousVersion)
    } else {
        $lastReleaseRef = $startRef
    }
    $commitLog = GetCommitLogUsingGit $lastReleaseRef
    $commitsFromLog = ParseGitCommitLog $commitLog
    if ($false -eq [string]::IsNullOrWhiteSpace($lastReleaseRef)) {
        Write-Host "Found $($commitsFromLog.Count) commits in repo since $lastReleaseRef"
    } else {
        Write-Host "Found $($commitsFromLog.Count) commits in repo"
    }
    if ($commitsFromLog.Count -eq 0) {
        Write-Warning "No commits found"
        return
    }
    $commitsWithParsedBodies = ParseCommitBodies `
        $commitsFromLog `
        $rcFile.PrunePatterns
    $conventionalCommits = GetConventionalCommits `
        $rcFile.ChangelogCategories `
        $rcFile.CommitTypes `
        $commitsWithParsedBodies
    Write-Host "Found $($conventionalCommits.Count) conventional commits"
    if ($conventionalCommits.Count -eq 0) {
        Write-Warning "No conventional commits found"
        return
    }
    $versionChange = GetVersionChangeFromCommits $conventionalCommits
    $nextVersion = BumpSemanticVersion $previousVersion $versionChange $rcFile.AllowBumpZeroMajor
    $versionsAreEqual = VersionsAreEqual $previousVersion $nextVersion
    if ($true -eq $versionsAreEqual) {
        Write-Warning "No version changes detected"
        return
    }
    Write-Host "Executing $versionChange bump to next version $(GetStringVersion $nextVersion)"
    # changelog
    $changelog = GenerateChangelogFromCommits `
        $rcFile.ChangelogCategories `
        $conventionalCommits
    $renderedChangelogHeader = RenderChangelogHeader $rcFile.ChangelogHeader
    $renderedChangelog = RenderChangelog `
        $rcFile.RepoUri `
        $(GetStringVersion $nextVersion) `
        $(GetStringVersion $previousVersion) `
        $changelog
    $releaseNotes = SanitizeMarkdown $renderedChangelog
    Write-Host "----------------- CHANGELOG -----------------"
    $renderedChangelogHeader
    $renderedChangelog
    Write-Host "---------------------------------------------"
    Write-Host "--------------- RELEASE NOTES ---------------"
    $releaseNotes
    Write-Host "---------------------------------------------"
    # update changelog
    $changelogFileContent = ReadFile $rcFile.ChangelogFilePath
    $updatedChangelogFileContent = UpdateChangelog $changelogFileContent $renderedChangelogHeader $renderedChangelog
    if ($dryRun -eq $true) {
        Write-Warning "-- DRY RUN -- Would write changelog"
    } else {
        WriteFile $rcFile.ChangelogFilePath $updatedChangelogFileContent
        Write-Host "Wrote changelog"
    }
    # update readme
    $readmeFileContent = ReadFile $rcFile.ReadmeFilePath
    $updatedReadmeFileContent = UpdateReadme $readmeFileContent $renderedChangelog
    if ($dryRun -eq $true) {
        Write-Warning "-- DRY RUN -- Would write readme"
    } else {
        WriteFile $rcFile.ReadmeFilePath $updatedReadmeFileContent
        Write-Host "Wrote readme"
    }
    # update manifest
    if ($dryRun -eq $true) {
        Write-Warning "-- DRY RUN -- Would update module version to $(GetStringVersion $nextVersion)"
    } else {
        UpdateModuleManifest `
            $rcFile.ModuleManifestFilePath `
            $(GetStringVersion $nextVersion) `
            $releaseNotes
        Write-Host "Updated module version to $(GetStringVersion $nextVersion)"
    }
    # add updated files to release commit
    if ($dryRun -eq $true) {
        Write-Warning "-- DRY RUN -- Would add updated changelog and readme to commit"
    } else {
        GitAddFiles $rcFile.ChangelogFilePath,$rcFile.ReadmeFilePath
        Write-Host "Added updated changelog and readme to commit"
    }
    # create release commit
    if ($dryRun -eq $true) {
        Write-Warning "-- DRY RUN -- Would create release commit"
    } else {
        CreateReleaseCommit `
            $rcFile.AuthorName `
            $rcFile.AuthorEmail `
            $(GetStringVersion $nextVersion)
        Write-Host "Created release commit"
    }
    # tag the release
    if ($dryRun -eq $true) {
        Write-Warning "-- DRY RUN -- Would tag release $(GetStringVersion $nextVersion)"
    } else {
        GitTagVersion `
            $rcFile.AuthorName `
            $rcFile.AuthorEmail `
            $releaseNotes `
            $(GetStringVersion $nextVersion)
        Write-Host "Tagged release $(GetStringVersion $nextVersion)"
    }
    if ($true -eq $publish) {
        # ensure module is valid
        Write-Host "---------------- MODULE TEST ----------------"
        Test-ModuleManifest -Path $rcFile.ModuleManifestFilePath
        Write-Host "---------------------------------------------"
        Write-Host "----------------- PUSH REPO -----------------"
        if ($dryRun -eq $true) {
            Write-Warning "-- DRY RUN -- Would push branch '$($rcFile.PushBranch)' and tag '$(GetStringVersion $nextVersion)' to origin"
        } else {
            PushGitRepo `
                $rcFile.PushBranch `
                $(GetStringVersion $nextVersion)
            Write-Host "Pushed branch '$($rcFile.PushBranch)' and tag '$(GetStringVersion $nextVersion)' to origin"
        }
        Write-Host "---------------------------------------------"
        Write-Host "--------------- PUBLISH MODULE --------------"
        if ($dryRun -eq $true) {
            Write-Warning "-- DRY RUN -- Would publish module $(GetStringVersion $nextVersion) to PowerShellGallery"
        } else {
            Publish-Module `
                -Repository 'PSGallery' `
                -Path $rcFile.ModuleDirPath `
                -NuGetApiKey $apiKey `
                -Force
            Write-Host "Published module $(GetStringVersion $nextVersion) to PowerShellGallery"
        }
        Write-Host "---------------------------------------------"
    }
}

if ($false -eq $LibraryMode) {
    DoMain $WhatIfPreference $Publish $ApiKey $StartRef
}
