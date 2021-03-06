Set-StrictMode -Version Latest
function Get-AzSKADOInfo
{
	
	<#
	.SYNOPSIS
	This command would help users to get details of various components of AzSK.ADO.
	
	.DESCRIPTION
	This command will fetch details of AzSK.ADO components and help user to provide details of different component using single command. Refer https://aka.ms/adoscanner/docs for more information 
	
	.PARAMETER InfoType
		InfoType for which type of information required by user.
	.PARAMETER ResourceTypeName
		Friendly name of resource type. e.g.: Build, Release, etc. (combo types e.g., Build_Release are not currently supported).
	.PARAMETER DoNotOpenOutputFolder
		Switch to specify whether to open output folder containing all security evaluation report or not.
	.PARAMETER UseBaselineControls
		This switch would scan only for baseline controls defined at org level
	.PARAMETER ControlIds
		Comma-separated control ids to filter the security controls. e.g.: ADO_Release_AuthZ_Disable_Inherited_Permissions, ADO_ServiceConnection_AuthZ_Dont_Grant_All_Pipelines_Access
	.PARAMETER ControlSeverity
		Select one of the control severity (Critical, High, Low, Medium)
	.PARAMETER ControlIdContains
		The list of control ids for which fixes should be applied.

	.NOTES
	This command helps the application team to verify whether their ADO resources are compliant with the security guidance or not 

	.LINK
	https://aka.ms/ADOScanner 

	#>
	Param(
		[Parameter(Mandatory = $false)]
		[ValidateSet("OrganizationInfo", "ControlInfo", "HostInfo")] 
		[Alias("it")]
		$InfoType,

		[string]
		[Parameter(Mandatory = $true)]
		[Alias("oz")]
		$OrganizationName,

		[string]
		[Parameter( HelpMessage="Project names for which the security evaluation has to be performed.")]
		[ValidateNotNullOrEmpty()]
		[Alias("pns", "ProjectName", "pn")]
		$ProjectNames,

		[string]
		[Parameter(Mandatory = $false, HelpMessage="Name of the project hosting organization policy with which the scan should run.")]
		[ValidateNotNullOrEmpty()]
		[Alias("pp")]
		$PolicyProject,
		
		[ResourceTypeName]
		[Alias("rtn")]
		$ResourceTypeName = [ResourceTypeName]::All,

		[string]
		[Alias("cids")]
        $ControlIds,

		[switch]
		[Alias("ubc")]
		$UseBaselineControls,

		[switch]
		[Alias("upbc")]
        $UsePreviewBaselineControls,

		[Alias("cs")]
		$ControlSeverity,

		[string]
		[Alias("ft")]
		$FilterTags,

		[string]
		[Alias("cidc")]
		$ControlIdContains,
		
		[switch]
		[Parameter(Mandatory = $false, HelpMessage = "Switch to specify whether to open output folder.")]
		[Alias("dnof")]
		$DoNotOpenOutputFolder
    )
	Begin
	{
		[CommandHelper]::BeginCommand($PSCmdlet.MyInvocation);
		[ListenerHelper]::RegisterListeners();
	}

	Process
	{
		try 
		{
			$SubscriptionId = $OrganizationName
			$unsupported = $false
			if([string]::IsNullOrWhiteSpace($ResourceTypeName))
			{
				$ResourceTypeName = [ResourceTypeName]::All
			}
			elseif ($ResourceTypeName -match "_")
			{
				$unsupported = $true
				Write-Host -ForegroundColor Yellow "Combo ResourceTypeNames are not supported in this command.`r`nUse individual names or run use All and apply filter in CSV."
			}


			if(-not ([string]::IsNullOrEmpty($InfoType) -or $unsupported))
			{
				switch ($InfoType.ToString()) 
				{
					OrganizationInfo
					{
						Write-Host -ForegroundColor Yellow "OrganizationInfo support is yet to be implemented."
					}
					ControlInfo 
					{
						If($PSCmdlet.MyInvocation.BoundParameters["Verbose"] -and $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent)
						{
							$Full = $true
						}
						else
						{
							$Full = $false
						}

						$controlsInfo = [ControlsInfo]::new($SubscriptionId, $PSCmdlet.MyInvocation, $ResourceTypeName, $ControlIds, $UseBaselineControls, $UsePreviewBaselineControls, $FilterTags, $Full, $ControlSeverity, $ControlIdContains);
						if ($controlsInfo) 
						{
							return $controlsInfo.InvokeFunction($controlsInfo.GetControlDetails);
						}
					}
					HostInfo 
					{
						$hInfo = [HostInfo]::new($SubscriptionId, $PSCmdlet.MyInvocation);
						if ($hInfo) 
						{
							return $hInfo.InvokeFunction($hInfo.GetHostInfo);
						}
					}
					AttestationInfo
					{
						Write-Host -ForegroundColor Yellow "AttestationInfo support is yet to be implemented."
					}
					Default
					{
						Write-Host $([Constants]::DefaultInfoCmdMsg)
					}
				}
			}
			else
			{
				Write-Host $([Constants]::DefaultInfoCmdMsg)
			}
		}
		catch 
		{
			[EventBase]::PublishGenericException($_);
		}  
	}

	End
	{
		[ListenerHelper]::UnregisterListeners();
	}
}
