param (
    [string[]]$AccountsFollowing,
    [string[]]$AccountFollowers,
    [psobject[]]$ListMembers,
    [psobject[]]$ListFollowers,
    [string[]]$SpecificTwitterAccounts,
    [string[]]$Hashtags,
    [switch]$IncludePrivate,
    [string[]]$My,
    [string[]]$MySpecificListNames,
    [string[]]$MySpecificListKeywords,
    [string]$TwitterCsvFilepath,
    [string]$MastodonCsvFilepath
)
<#

            Validation

#>

. $PSScriptRoot/helpers.ps1

foreach ($key in $PSBoundParameters.Keys) {
    if ($key -eq "IncludePrivate") { continue }
    $value = $PSBoundParameters[$key]
    if (-not $value) {
        $PSBoundParameters[$key] = $null
        Set-Variable -Name $key -Value $null
    }
}

if ($ListMembers) {
    Write-Output "Checking to see if $ListMembers is a number"
    foreach ($item in $ListMembers) {
        if (-not (Test-Number $item)) {
            throw "list-members input must be a number. You can get this number by going to the list and grabbing the long number in the web addressbar"
        }
    }
}

if ($ListFollowers) {
    Write-Output "Checking to see if $ListFollowers is a number"
    foreach ($item in $ListFollowers) {
        if (-not (Test-Number $item)) {
            throw "list-members input must be a number. You can get this number by going to the list and grabbing the long number in the web addressbar"
        }
    }
}

<#

            Prep

#>

$script:checked = $script:links = @()
$PSDefaultParameterValues["*:IncludeExpansions"] = $true
$PSDefaultParameterValues["Find-Links:IncludePrivate"] = $IncludePrivate

if ($TwitterCsvFilepath -notmatch "\\|\/") {
    $TwitterCsvFilepath = "./$TwitterCsvFilepath"
}

if ($MastodonCsvFilepath -notmatch "\\|\/") {
    $MastodonCsvFilepath = "./$MastodonCsvFilepath"
}

foreach ($file in $TwitterCsvFilepath, $MastodonCsvFilepath) {
    $directory = Resolve-Path -Path (Split-Path -Path $file)
    if (-not (Test-Path -Path $directory)) {
        New-Item -Type Directory -Path $directory
    }
}

$PSDefaultParameterValues["Find-Links:MastodonCsvFilepath"] = $MastodonCsvFilepath
$PSDefaultParameterValues["Find-Links:TwitterCsvFilepath"] = $TwitterCsvFilepath

<#

            Process

#>

# reduce the number of calls by batching
$batches = Split-Array -Objects $AccountsFollowing -Size 99

foreach ($batch in $batches) {
    Write-Output "Processing followers for account(s): $($batch -join ', ')"
    $users = Get-ThrottledTwitterUser -User $batch -IncludeExpansions:$false

    foreach ($id in $users.Id) {
        Write-Output "Processing followers for user ID: $id"
        $followers = Get-ThrottledTwitterFriends -Id $id
        Find-Links -Users $followers
    }
}

$batches = Split-Array -Objects $AccountFollowers -Size 99

foreach ($batch in $batches) {
    Write-Output "Processing follows (friends) for account(s): $($batch -join ', ')"
    $users = Get-ThrottledTwitterUser -User $batch -IncludeExpansions:$false
    foreach ($id in $users.Id) {
        Write-Output "Processing following for user ID: $id"
        $followers = Get-ThrottledTwitterFollowers -Id $id
        Find-Links -Users $followers
    }
}

foreach ($list in $ListMembers) {
    if ($list.Id) {
        $listnumber = $list.Id
    } else {
        $listnumber = [decimal]$list
    }

    Write-Output "Getting members for list number $listnumber"
    $members = Get-ThrottledTwitterListMember -Id $listnumber
    Find-Links -Users $members
}

foreach ($list in $ListFollowers) {
    if ($list.Id) {
        $listnumber = $list.Id
    } else {
        $listnumber = [decimal]$list
    }
    Write-Output "Getting followers for list number $listnumber"
    $subscribers = Get-ThrottledTwitterListSubscriber -Id $listnumber
    Find-Links -Users $subscribers
}

$batches = Split-Array -Objects $SpecificTwitterAccounts -Size 99
foreach ($batch in $batches) {
    Write-Output "Processing the specific account(s): $($batch -join ', ')"
    $users = Get-ThrottledTwitterUser -User $batch
    Find-Links -Users $users
}

foreach ($hashtag in $Hashtags) {
    $search = @{
        SearchString      = $hashtag
        NoPagination      = $true
        IncludeExpansions = $false
    }

    $authors = (Search-Tweet @search).AuthorId | Sort-Object -Unique | Select-Object -First 99
    $hashtagusers = Get-ThrottledTwitterUser -User $authors
    Find-Links -Users $hashtagusers
}

if ($My) {
    Write-Output "My has been specified, let's check"
    if ("$My" -match "follows|all") {
        Write-Output "Processing all follows"
        $users = Get-ThrottledTwitterFriends
        Find-Links -Users $users
    }

    if ("$My" -match "followers|all") {
        Write-Output "Processing all followers"
        $users = Get-ThrottledTwitterFollowers
        Find-Links -Users $users
    }

    if ("$My" -match "lists|all") {
        $lists = Get-TwitterList
        Write-Output "Processing all lists"
        foreach ($list in $lists) {
            if ($list.Id) {
                $listnumber = $list.Id
            } else {
                $listnumber = [decimal]$list
            }
            Write-Output "Getting members for list number $listnumber"
            $members = Get-ThrottledTwitterListMember -Id $listnumber
            Find-Links -Users $members
        }
    }
}

if ($MySpecificListNames) {
    $lists = Get-TwitterList -IncludeExpansions:$false
}
foreach ($list in $MySpecificListNames) {
    Write-Output "Getting followers for my list named $list"
    $members = $lists | Where-Object Name -eq $list | Get-ThrottledTwitterListMember
    Find-Links -Users $members
}

foreach ($keyword in $MySpecificListKeywords) {
    Write-Output "Getting followers for my list matching keyword $keyword"
    $members = Get-TwitterList -SearchName $keyword -IncludeExpansions:$false | Get-ThrottledTwitterListMember
    Find-Links -Users $members
}

<#

            Output

#>

if ((Test-Path -Path $TwitterCsvFilepath)) {

    if ((Test-Path -Path $MastodonCsvFilepath)) {
        Remove-Item $MastodonCsvFilepath
    }

    Import-Csv -Path $TwitterCsvFilepath | Sort-Object MastodonAccountAddress |
        Select-Object @{
            Label      = "Account address"
            Expression = { $PSItem.MastodonAccountAddress }
        },
        @{
            Label      = "Show boosts"
            Expression = { "true" }
        } | Export-Csv -Path $MastodonCsvFilepath

    Get-ChildItem $MastodonCsvFilepath | Select-Object FullName
    $exported = Import-Csv -Path $MastodonCsvFilepath
    Write-Output "Found $($exported.Count) Mastodon addresses in $($exported.Count + $script:checked.Count) Twitter accounts, including cache from CSV files"

    $mcsv = Resolve-Path -Path $MastodonCsvFilepath
    $tcsv = Resolve-Path -Path $TwitterCsvFilepath

    "mastodon-csv-filepath=$mcsv" >> $env:GITHUB_OUTPUT
    "twitter-csv-filepath=$tcsv" >> $env:GITHUB_OUTPUT
}