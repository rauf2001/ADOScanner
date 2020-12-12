Set-StrictMode -Version Latest 
class Repo: ADOSVTBase {    
    hidden [PSObject] $RepoId = "";

    Repo([string] $subscriptionId, [SVTResource] $svtResource): Base($subscriptionId,$svtResource) {
        $this.RepoId = $this.ResourceContext.ResourceDetails.id
    }

    hidden [ControlResult] CheckInactiveRepo([ControlResult] $controlResult) {
        $currentDate = Get-Date
        try {
            $projectId = ($this.ResourceContext.ResourceId -split "project/")[-1].Split('/')[0]
            # check if repo has commits in past RepoHistoryPeriodInDays days
            $inactiveLimit = $this.ControlSettings.Repo.RepoHistoryPeriodInDays
            $thresholdDate = $currentDate.AddDays(-$inactiveLimit);
            $url = "https://dev.azure.com/$($this.SubscriptionContext.SubscriptionName)/$projectId/_apis/git/repositories/$($this.RepoId)/commits?searchCriteria.fromDate=$($thresholdDate)&&api-version=6.0"
            $responseObj = [WebRequestHelper]::InvokeGetWebRequest($url);
            
            # When there are no commits, CheckMember in the below condition returns false when checknull flag [third param in CheckMember] is not specified (default value is $true). Assiging it $false.
            if(([Helpers]::CheckMember($responseObj[0],"count",$false)) -and ($responseObj[0].count -eq 0))
            {
                $controlResult.AddMessage([VerificationResult]::Failed, "Repository is inactive. It has no commits in last $inactiveLimit days.");
            }
            # When there are commits - the below condition will be true.
            elseif((-not ([Helpers]::CheckMember($responseObj[0],"count"))) -and ($responseObj.Count -gt 0))
            {
                $controlResult.AddMessage([VerificationResult]::Passed, "Repository is active. It has commits in last $inactiveLimit days.");
            }
        }
        catch 
        {
            $controlResult.AddMessage([VerificationResult]::Error, "Could not fetch the list of commits in the repository.");
        }
        return $controlResult
    }

}