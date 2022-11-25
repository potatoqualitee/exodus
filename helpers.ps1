function Get-ThrottledTwitterUser {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]]$User,
        [Parameter(ValueFromPipelineByPropertyName)]
        [switch]$IncludeExpansions
    )

    try {
        Write-Output "Getting info for $($User.Count) Twitter users"
        Get-TwitterUser @PSBoundParameters
    } catch {
        if ($PSItem -match "rate") {
            $waitdate = (Get-BluebirdPSHistory -Last 1).RateLimitReset
            $wait = (New-TimeSpan -End $waitdate).TotalSeconds + 1
            Write-Warning "Throttled until $waitdate, sleeping $wait seconds"
            Start-Sleep -Seconds $wait
        } elseif ($PSitem -match "pinned_tweet_id") {
            # do nothing
        } else {
            Write-Warning "$PSItem"
        }
    }
}

function Get-ThrottledTwitterFriends {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Id
    )
    try {
        Write-Output "Getting follows for user id: $Id"
        Get-TwitterFriends @PSBoundParameters
    } catch {
        if ($PSItem -match "rate") {
            $waitdate = (Get-BluebirdPSHistory -Last 1).RateLimitReset
            $wait = (New-TimeSpan -End $waitdate).TotalSeconds + 1
            Write-Warning "Throttled until $waitdate, sleeping $wait seconds"
            Start-Sleep -Seconds $wait
        } elseif ($PSitem -match "pinned_tweet_id") {
            # do nothing
        } else {
            Write-Warning "$PSItem"
        }
    }
}


function Get-ThrottledTwitterFollowers {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Id
    )
    try {
        Write-Output "Getting followers for user id: $Id"
        Get-TwitterFollowers @PSBoundParameters
    } catch {
        if ($PSItem -match "rate") {
            $waitdate = (Get-BluebirdPSHistory -Last 1).RateLimitReset
            $wait = (New-TimeSpan -End $waitdate).TotalSeconds + 1
            Write-Warning "Throttled until $waitdate, sleeping $wait seconds"
            Start-Sleep -Seconds $wait
        } elseif ($PSitem -match "pinned_tweet_id") {
            # do nothing
        } else {
            Write-Warning "$PSItem"
        }
    }
}

function Get-ThrottledTwitterListMember {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Id,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$SearchName

    )
    try {
        if ($Id) {
            Write-Output "Getting list members for list id: $Id"
        } else {
            Write-Output "Getting list members for lists names matching $SearchName"
        }

        Get-TwitterListMember @PSBoundParameters
    } catch {
        if ($PSItem -match "rate") {
            $waitdate = (Get-BluebirdPSHistory -Last 1).RateLimitReset
            $wait = (New-TimeSpan -End $waitdate).TotalSeconds + 1
            Write-Warning "Throttled until $waitdate, sleeping $wait seconds"
            Start-Sleep -Seconds $wait
        } elseif ($PSitem -match "pinned") {
            # do nothing
        } else {
            Write-Warning "$PSItem"
        }
    }
}
function Get-ThrottledTwitterListSubscriber {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Id,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$SearchName
    )
    try {
        if ($Id) {
            Write-Output "Getting subscribers for list id: $Id"
        } else {
            Write-Output "Getting subscribers for lists names matching $SearchName"
        }
        Get-TwitterList @PSBoundParameters -IncludeExpansions:$false | Get-TwitterListSubscriber
    } catch {
        if ($PSItem -match "rate") {
            $waitdate = (Get-BluebirdPSHistory -Last 1).RateLimitReset
            $wait = (New-TimeSpan -End $waitdate).TotalSeconds + 1
            Write-Warning "Throttled until $waitdate, sleeping $wait seconds"
            Start-Sleep -Seconds $wait
        } elseif ($PSitem -match "pinned_tweet_id") {
            # do nothing
        } else {
            Write-Warning "$PSItem"
        }
    }
}


Function Test-Number ($item) {
    $rtn = ""
    [double]::TryParse($item, [ref]$rtn)
}
function Find-Links {
    [CmdletBinding()]
    param(
        [psobject[]]$Users,
        [string]$TwitterCsvFilepath,
        [switch]$Protected
    )
    if (-not $Users) { return }
    $export = $false
    Write-Output "Starting with $($Users.Count) users"

    if ($Protected) {
        $Users = $Users | Sort-Object UserName -Unique
    } else {
        $Users = $Users | Where-Object Protected -eq $false | Sort-Object UserName -Unique
    }

    $Users = $Users | Where-Object UserName -notin $script:checked

    if ((Test-Path -Path $TwitterCsvFilepath)) {
        $csv = @((Import-Csv -Path $TwitterCsvFilepath))
    } else {
        $csv = @()
    }

    $Users = $Users | Where-Object UserName -notin $csv.TwitterUserName
    Write-Output "Now processing $($Users.Count) users"

    foreach ($user in $Users) {
        $script:checked += $user.UserName
        try {
            $ignored = "youtube.com", "medium.com", "withkoji.com", "counter.social", "twitter.com"
            $results = $user | Find-TwitterMastodonLinks -Verbose -IgnoreUrl $ignored | Sort-Object -Unique
            foreach ($result in $results) {
                $export = $true
                $result.MastodonAccountAddress = $result.MastodonAccountAddress.Replace("/web", "")
                Write-Output "Found $($result.MastodonAccountAddress)"
                $csv += $result
            }
        } catch {
            if ($PSItem -match "rate") {
                $waitdate = (Get-BluebirdPSHistory -Last 1).RateLimitReset
                $wait = (New-TimeSpan -End $waitdate).TotalSeconds + 1
                Write-Warning "Throttled until $waitdate, sleeping $wait seconds"
                Start-Sleep -Seconds $wait
            } elseif ($PSitem -match "pinned_tweet_id") {
                # do nothing
            } else {
                Write-Warning "$PSItem"
            }
        }
    }
    if ($export) {
        Write-Output "Exporting to $TwitterCsvFilepath"
        $csv | Sort-Object TwitterUserName | Export-Csv -Path $TwitterCsvFilepath
        Get-ChildItem $TwitterCsvFilepath | Select-Object FullName
    }
}


# thanks https://www.powershellgallery.com/packages/PSSharedGoods/0.0.252/Content/PSSharedGoods.psm1
function Split-Array {
    <#
    .SYNOPSIS
    Split an array into multiple arrays of a specified size or by a specified number of elements

    .DESCRIPTION
    Split an array into multiple arrays of a specified size or by a specified number of elements

    .PARAMETER Objects
    Lists of objects you would like to split into multiple arrays based on their size or number of parts to split into.

    .PARAMETER Parts
    Parameter description

    .PARAMETER Size
    Parameter description

    .EXAMPLE
    This splits array into multiple arrays of 3
    Example below wil return 1,2,3 + 4,5,6 + 7,8,9
    Split-array -Objects @(1,2,3,4,5,6,7,8,9,10) -Parts 3

    .EXAMPLE
    This splits array into 3 parts regardless of amount of elements
    Split-array -Objects @(1,2,3,4,5,6,7,8,9,10) -Size 3

    .NOTES

    #>
    [CmdletBinding()]
    param([alias('InArray', 'List')][Array] $Objects,
        [int]$Parts,
        [int]$Size)
    if ($Objects.Count -eq 1) { return $Objects }
    if ($Parts) { $PartSize = [Math]::Ceiling($inArray.count / $Parts) }
    if ($Size) {
        $PartSize = $Size
        $Parts = [Math]::Ceiling($Objects.count / $Size)
    }
    $outArray = [System.Collections.Generic.List[Object]]::new()
    for ($i = 1; $i -le $Parts; $i++) {
        $start = (($i - 1) * $PartSize)
        $end = (($i) * $PartSize) - 1
        if ($end -ge $Objects.count) { $end = $Objects.count - 1 }
        $outArray.Add(@($Objects[$start..$end]))
    }
    , $outArray
}