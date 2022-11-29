# exodus

 Helps Twitter communities find members on Mastodon. Searches lists, hashtags, account followers and more for Mastodon links in their name, bio or pinned tweet. Once found, their info is exported to a CSV file that can be imported into Mastodon.

 This CSV file can be updated and published on a regular basis for others to import, either manually or using this other GitHub Action.

> **Note**
>
> Because this is intended to help Twitter communities find their people on Mastodon, the default is to exclude any accounts set to private so the CSV files are built using purely public information.
>
> Examples below will outline how to include private accounts in the CSV output. This is useful when using exodus to export Mastodon CSV files only for yourself.

If any Mastodon addresses are found in your query, this Action will generate two files named `./mastodon-import.csv` and `./twitter-match-archive.csv`. The `./mastodon-import.csv` can be used to import new followers and the `./twitter-match-archive.csv` can be used to cross-reference the matches.

As of late November, I've found that only about 5% of my community tests result in a Mastodon address. This is because people have migrated, but have not added their address to their Twitter name, bio or pinned Tweet. If you'd like to see more of your friends and community migrate to Mastodon, let them know how Actions like this and services like fedifinder are evaluating Twitter accounts for Matodon addresses.

## Documentation

There are a ton of options available in this Action, but here's how to check your own followers and friends:

```yaml
- name: Check Twitter friends for Maston accounts
  uses: potatoqualitee/exodus@v1.1
    with:
        my: follows, followers
    env:
        BLUEBIRDPS_API_KEY: "${{ secrets.BLUEBIRDPS_API_KEY }}"
        BLUEBIRDPS_API_SECRET: "${{ secrets.BLUEBIRDPS_API_SECRET }}"
        BLUEBIRDPS_ACCESS_TOKEN: "${{ secrets.BLUEBIRDPS_ACCESS_TOKEN }}"
        BLUEBIRDPS_ACCESS_TOKEN_SECRET: "${{ secrets.BLUEBIRDPS_ACCESS_TOKEN_SECRET }}"
```

This will save two files for you to work with: `./mastodon-import.csv` and `./twitter-match-archive.csv`.

If you're wondering about the environmental variables, they are detailed next in the [Pre-requisites](#pre-requisites) section.

# Usage

## Pre-requisites

### Get some Twitter API keys

This project uses [BluebirdPS](https://github.com/thedavecarroll/BluebirdPS) and Twitter API keys are required. If you don't have API access yet, Justin Bird wrote an [awesome tutorial](https://www.justinjbird.me/2022/how-to-set-up-twitter-developer-api-for-bluebirdps/) to help you get going.

When applying for a [Twitter developer account](https://developer.twitter.com/en/portal/petition/essential/basic-info), you will be asked what its intended purpose. If you choose the multiple choice reason as: "This is just for us, help us understand what you want to use this for so we can learn how things get used", you get immediate approval.

### Add GitHub Secrets

Once you have your authentication information, you will need to them to your [repository secrets](https://docs.github.com/en/codespaces/managing-codespaces-for-your-organization/managing-encrypted-secrets-for-your-repository-and-organization-for-github-codespaces#adding-secrets-for-a-repository).

They will be most likely be named like this:

* BLUEBIRDPS_API_KEY
* BLUEBIRDPS_API_SECRET
* BLUEBIRDPS_ACCESS_TOKEN
* BLUEBIRDPS_ACCESS_TOKEN_SECRET
* BLUEBIRDPS_BEARER_TOKEN (sometimes?)

You can modify the names, though you must ensure that your environmental variables are named appropriately, as seen in the sample code.

> **Note**
>
> Sometimes I have to use a Bearer Token and other times I don't. No idea why as I don't know enough about OAUTH but you'll probably need to generate one at some point.

### Create workflows

Finally, create a workflow `.yml` file in your repositories `.github/workflows` directory. An [example workflow](#example-workflow) is available below. For more information, reference the GitHub Help Documentation for [Creating a workflow file](https://help.github.com/en/articles/configuring-a-workflow#creating-a-workflow-file).

## Inputs

* `accounts-following` - Check who these Twitter users are following and search the results for a Mastodon account
* `account-followers` - Search the followers of these Twitter users for a Mastodon account
* `list-members` - Search the members of these Twitter list IDs for a Mastodon account. This has to be one or more numbers in quotes or the Action will automatically turn it into an E notation which Twitter cannot recognize.
* `communities` - Check who these Twitter users are following, check their followers and check their account for Mastodon addreses. An ideal community would be small-to-medium conference accounts like DataGrillen or PSConfEU.
* `list-followers` - Search the followers of these Twitter list IDs for a Mastodon account. This has to be one or more numbers in quotes or the Action will automatically turn it into an E notation which Twitter cannot recognize.
* `specific-twitter-accounts` - Search these specific Twitter accounts to see if they have a Mastodon accoun
* `hashtags` - Search posts for these hashtags to see if the author has a Mastodon account
* `include-private` - Include accounts marked private. False by default since this can be used to migrate communities
* `my` - Search your own follows, followers or list members to see any of them have a Mastodon account
* `my-specific-list-names` - Search your own specific lists
* `my-specific-list-keywords` - Search your own specific lists
* `mastodon-csv-filepath` - The path where the Mastodon import CSV will be stored. Defaults to ./mastodon-import.csv
* `twitter-csv-filepath` - Where the Twitter info for the matches are stored. Defaults to ./twitter-match-archive.csv
* `auto-artifact` - Attach the two CSV files as an artifact to this workflow. Default is true
* `artifact-name` - The name of the artifact. Default is csv-artifacts.

## Outputs

* `mastodon-csv-filepath` - Mastodon CSV file path. This file can be downloaded and imported into Mastodon
* `twitter-csv-filepath` - Twitter CSV file path. This file contains Twitter details about accounts that have Mastodon addresses

### Details

| Input | Literal Example | Another Literal Example
| --- | --- | --- |
| accounts-following | cl | thedavecarroll, DataGrillen
| account-followers | justinjbird7 | psdbatools, MSPowerBI
| communities | PSConfEU | DataGrillen, SQLBits
| list-members | "1569973251161616385" | "1491474973998915587, 1569973251161616385"
| list-followers | "749356646665629696" | "749356646665629696, 1491474973998915587, 1569973251161616385"
| specific-twitter-accounts | SQLBits | DataGrillen, SQLBits, SQLServer
| hashtags | "#sqlfamily, pbifamily" | sqlfamily
| include-private | true | false
| my | follows, lists | all
| my-specific-list-names | PowerShell Team | PowerShell Team, PowerBI
| my-specific-list-keywords | PowerShell | SQL, PowerShell
| mastodon-csv-filepath | mas.csv | "/tmp/mas.csv"
| twitter-csv-filepath | tw.csv | ./tw.csv
| auto-artifact | false | true
| artifact-name | mycsv | csv-artifact

### Example workflows

Check for new accounts at midnight

```yaml
name: check for new accounts at midnight
on:
  workflow_dispatch:
  schedule:
    - cron: "0 0 * * *"
jobs:
  check-exodus:
    runs-on: ubuntu-latest
    steps:
      - name: Run the action
        id: export
        uses: potatoqualitee/exodus@v1.1
        with:
          specific-twitter-accounts: cl, DataGrillen
          list-members: "1569973251161616385, 1491474973998915587"
          list-followers: "1569973251161616385"
        env:
          BLUEBIRDPS_API_KEY: "${{ secrets.BLUEBIRDPS_API_KEY }}"
          BLUEBIRDPS_API_SECRET: "${{ secrets.BLUEBIRDPS_API_SECRET }}"
          BLUEBIRDPS_ACCESS_TOKEN: "${{ secrets.BLUEBIRDPS_ACCESS_TOKEN }}"
          BLUEBIRDPS_ACCESS_TOKEN_SECRET: "${{ secrets.BLUEBIRDPS_ACCESS_TOKEN_SECRET }}"
```

Checking all of your lists, follows and followers. This workflow will execute at midnight, when you initiate a workflow, or each time you push a comit to your repository.

```yaml
name: check for new accounts

on:
  workflow_dispatch:
  schedule:
    - cron: "0 0 * * *"
jobs:
  check-exodus:
    runs-on: ubuntu-latest
    steps:
      - name: Run the action
        id: export
        uses: potatoqualitee/exodus@v1.1
        with:
          my: all
          include-private: true
        env:
          BLUEBIRDPS_API_KEY: "${{ secrets.BLUEBIRDPS_API_KEY }}"
          BLUEBIRDPS_API_SECRET: "${{ secrets.BLUEBIRDPS_API_SECRET }}"
          BLUEBIRDPS_ACCESS_TOKEN: "${{ secrets.BLUEBIRDPS_ACCESS_TOKEN }}"
          BLUEBIRDPS_ACCESS_TOKEN_SECRET: "${{ secrets.BLUEBIRDPS_ACCESS_TOKEN_SECRET }}"
          BLUEBIRDPS_BEARER_TOKEN: "${{ secrets.BLUEBIRDPS_BEARER_TOKEN }}"

```

**REMINDER**, you may not have to use a Bearer token, depending on how you set it up.

#### API Usage

My account has a 2 million Tweet quota per month and all of my wild testing has only used about 3000 of my quota, so this process is either very efficient, not requesting data that is included in the quota, or Twitter isn't tracking right.

## Get Crazy

### Want to try every option?

Here is a workflow that uses every option. I use this for troubleshooting.

```yaml
name: check all fields and cache BluebirdPS
on:
  push:
  workflow_dispatch:
  schedule:
    - cron: "0 0 * * *"
jobs:
  check-exodus:
    runs-on: ubuntu-latest
    steps:
    - name: Install and cache BluebirdPS
      uses: potatoqualitee/psmodulecache@v5.1
      with:
        modules-to-cache: BluebirdPS

    - name: Run the action
      id: export
      uses: potatoqualitee/exodus@v1.1
      with:
        specific-twitter-accounts: PSConfEU
        account-followers: DataGrillen
        accounts-following: DataGrillen, SQLBits
        communities: datasaturdays
        list-members: "1491474973998915587, 1569973251161616385"
        list-followers: "1569973251161616385"
        hashtags: "#sqlfamily, pbifamily"
        include-private: false
        my: all
        my-specific-list-names: Birdie Favorites
        my-specific-list-keywords: Birdie
        mastodon-csv-filepath: ma.csv
        twitter-csv-filepath: tw.csv
      env:
        BLUEBIRDPS_API_KEY: "${{ secrets.BLUEBIRDPS_API_KEY }}"
        BLUEBIRDPS_API_SECRET: "${{ secrets.BLUEBIRDPS_API_SECRET }}"
        BLUEBIRDPS_ACCESS_TOKEN: "${{ secrets.BLUEBIRDPS_ACCESS_TOKEN }}"
        BLUEBIRDPS_ACCESS_TOKEN_SECRET: "${{ secrets.BLUEBIRDPS_ACCESS_TOKEN_SECRET }}"
        BLUEBIRDPS_BEARER_TOKEN: "${{ secrets.BLUEBIRDPS_BEARER_TOKEN }}"
```

I ran this and it only used like 1500 of my 2 million tweet per month quota.

### Want to run this locally?

Just add your `$env:BLUEBIRDPS_*` environmental variables to your `$profile` and reload, clone the repo, change directories, modify this splat and run.

```powershell
$params = @{
    AccountsFollowing         = "cl", "SQLBits"
    AccountFollowers          = "DataGrillen"
    Communities               = "datasaturdays"
    ListMembers               = "1491474973998915587", "1569973251161616385"
    ListFollowers             = "1569973251161616385"
    SpecificTwitterAccounts   = "DataGrillen"
    Hashtags                  = "#sqlfamily", "pbifamily"
    IncludePrivate            = $true
    My                        = "All"
    MySpecificListNames       = "Birdie Favorites"
    MySpecificListKeywords    = "Birdie"
    MastodonCsvFilepath       = "./ma.csv"
    TwitterCsvFilepath        = "./tw.csv"
}

./main.ps1 @params
```

You will see a bunch of messages like the ones below but those are normal. Some tweets got deleted, etc. You may even see a message that you're forbidden from seeing a tweet because the author blocked you. I did 😅!

```
Get-TwitterFollowers: Could not find tweet with pinned_tweet_id: [123456789123456789].

Get-TwitterFollowers: Sorry, you are not authorized to see the Tweet with pinned_tweet_id: [987654321987654321].
```

## Contributing
Pull requests are welcome!

I'd love for someone with web skills to smash Exodus, Influx and Mastodon together to make it easy for people to visuallyu pick and choose who they want.

## TODO
You tell me! I'm open to suggestions.

## License
The scripts and documentation in this project are released under the [MIT License](LICENSE)
