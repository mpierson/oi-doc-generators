# SPP Configuration Exporter
#
# Exports SPP appliance/cluster configuration details in XML-ish format
#
# v0.90  Feb 2025
#
# Copyright 2025 One Identity Inc.
#
# Usage:
#   >  Connect-Safeguard
#   > ./ExportSPP.ps1 > spp-configs.xml
#
# Pre-requisites:
#  - Safeguard Powershell commands installed
#  - certutil.exe installed and in path (for Base64 decoding)
#  - active safeguard connection with (at least) Auditor permissions
#
# Notes:
#  - secrets and other encrypted content is not exported
#  - user information is not exported, although user names are referenced, e.g. in entitlement scope
#  - IP addresses of assets, mail server, archive servers, etc. are included in export
#


# convert ConvertTo-Xml output to a well formed fragment
function ConvertTo-XmlFragment {
     [CmdletBinding()]
     param(
         [Parameter(ValueFromPipeline)]
         [pscustomobject]$obj
     )
	 process {
	$obj | ConvertTo-xml -Depth 8 -As String  -NoTypeInformation |
									foreach {$_ -Replace "<\?xml.*\?>",""} |
									foreach {$_ -Replace "<Objects>",""} |
									foreach {$_ -Replace "</Objects>",""} |
									foreach {$_ -Replace "<Object>",""} |
									foreach {$_ -Replace "</Object>",""}

#	$obj | ConvertTo-xml -Depth 8 -As String  -NoTypeInformation | Select-String -NotMatch -Pattern '<?xml '
	 }
}

# convert ConvertTo-Xml output to a well formed node
function ConvertTo-XmlNode {
     param(
		[Parameter(Mandatory=$true)]
        [string]$Name,

		[hashtable] $Attributes,
		[Object] $ChildContentScript,

        [Parameter(ValueFromPipeline)]
        [pscustomobject]$obj
     )
	 process {

		 if ($Attributes -eq $null -or $Attributes.count -eq 0 ) {
			Write-Output "<$Name>"
		 }
		 else
		 {
			$nodeAttrs = ""
			foreach ($key in $Attributes.Keys) {
				$nodeAttrs = $nodeAttrs + "$key=`"" + $Attributes[$key] + "`" "
			}
			Write-Output "<$Name $nodeAttrs>"
		 }

		If ($PSBoundParameters.ContainsKey('ChildContentScript')) {
			# put the object props in their own node
			Write-Output "<${Name}Object>"
			$obj | ConvertTo-XmlFragment
			Write-Output "</${Name}Object>"

			# now process the children
			Invoke-Command $ChildContentScript
		} Else {
			# just spit out the XML encoded properties
			$obj | ConvertTo-XmlFragment
		}

		 Write-Output "</$Name>"
	 }
}

# convert ConvertTo-Xml output to a well formed parent with child nodes
function ConvertTo-XmlParentNode {
     param(
		[Parameter(Mandatory=$false)]
        [string]$ParentName,

		[Parameter(Mandatory=$true)]
        [string]$ChildName,

		[Object] $AttributeMapScript,
		[Object] $ChildContentScript,

        $Content
     )
		If (-Not $PSBoundParameters.ContainsKey('ParentName')) {
			$ParentName = $ChildName + "s"
		}

		If (-Not $PSBoundParameters.ContainsKey('AttributeMapScript')) {
			$AttributeMapScript = { @{'id' = $_.Id; 'name' = $_.Name } }
		}


		Write-Output "<$ParentName>"
		$Content | foreach-object {
			$attrs = Invoke-Command $AttributeMapScript

			If  (-Not $PSBoundParameters.ContainsKey('ChildContentScript')) {
				$_ |ConvertTo-XmlNode -Name $ChildName -Attributes $attrs
			} Else {
				$_ | ConvertTo-XmlNode -Name $ChildName -Attributes $attrs -ChildContentScript $childContentScript
			}
		}
		Write-Output "</$ParentName>"
}

# =======================================================

if (-not $SafeguardSession)
{
    throw "This cmdlet requires that you log in with the Connect-Safeguard cmdlet"
}


# SPP API responds with UTF16 (!) content
Write-Output '<?xml version="1.0" encoding="UTF-16" ?>'

$name = Get-SafeguardApplianceName
$dnsName = Get-SafeguardApplianceDnsName
$health = Get-SafeguardHealth
Write-Output( '<SPP id="{0}" name="{1}" dnsName="{2}" checkDate="{3}" exporterVersion="0.90">' -f $health.ApplianceId, $name, $dnsName, $health.CheckDate)

Get-SafeguardVersion | ConvertTo-XmlNode -Name "Version"
$health 			 | ConvertTo-XmlNode -Name "Health"

Write-Output "<Cluster>"
    $members = Get-SafeguardClusterMember
	ConvertTo-XmlParentNode -Content $members -ChildName 'Member' -AttributeMapScript { @{'id' = $_.Id; 'name' = $_.Name; 'IsLeader' = $_.IsLeader  } }

    $spsNodes = Get-SafeguardSessionCluster
	ConvertTo-XmlParentNode -Content $spsNodes -ParentName 'SessionAppliances' -ChildName 'SessionNode' -AttributeMapScript { @{'id' = $_.Id; 'name' = $_.SpsHostName } }
Write-Output "</Cluster>"


$servers = Get-SafeguardArchiveServer
ConvertTo-XmlParentNode -Content $servers -ChildName 'ArchiveServer' -AttributeMapScript { @{'id' = $_.Id; 'name' = $_.Name; 'networkAddress' = $_.NetworkAddress } }

$settings = Get-SafeguardCoreSetting
ConvertTo-XmlParentNode -Content $settings -ParentName 'CoreSettings' -ChildName 'Setting' -AttributeMapScript { @{'name' = $_.Name; 'category' = $_.Category } }

$settings = Get-SafeguardApplianceSetting
ConvertTo-XmlParentNode -Content $settings -ParentName 'ApplianceSettings' -ChildName 'Setting' -AttributeMapScript { @{'name' = $_.Name; 'category' = $_.Category } }


Get-SafeguardPurgeSettings |ConvertTo-XmlNode -Name 'PurgeSettings'

$providers = Get-SafeguardAuthenticationProvider
ConvertTo-XmlParentNode -Content $providers -ChildName 'AuthProvider' -AttributeMapScript { @{'id' = $_.Id; 'name' = $_.Name; 'type' = $_.TypeReferenceName } }

$allUsers = Get-SafeguardUser
$admins = $allUsers | Where-Object {
	$roles = $_.AdminRoles
	Return $roles.count -GT 0
}
ConvertTo-XmlParentNode -Content $admins -ChildName 'Administrator' `
		-AttributeMapScript { @{'id' = $_.Id; 'name' = $_.Name; 'adminRoles' = ($_.AdminRoles -join ',') } }



Write-Output "<Partitions>"

# fetch list of all partitions
$partitions = Get-SafeguardAssetPartition

$partitions | ForEach-Object {
  Write-Output( '<Partition id="{0}" name="{1}">' -f $_.Id, $_.Name)

  $_ | ConvertTo-XmlNode -Name "PartitionObject"

  $owners = $_.ManagedBy
  ConvertTo-XmlParentNode -Content $owners -ChildName 'Owner' `
			-AttributeMapScript {
				@{'id' = $_.Id; 'name' = $_.Name; 'displayName' = $_.DisplayName; 'identityProvider' = $_.IdentityProviderName; 'kind' = $_.PrincipalKind }
			}

  $profiles = Get-SafeguardPasswordProfile -AssetPartition $_.Id
  ConvertTo-XmlParentNode -Content $profiles -ParentName 'PasswordProfiles' -ChildName 'Profile'

  $checkScheds =  Get-SafeguardPasswordCheckSchedule -AssetPartition $_.Id
  ConvertTo-XmlParentNode -Content $checkScheds -ChildName 'CheckRule'

  $changeScheds =  Get-SafeguardPasswordChangeSchedule -AssetPartition $_.Id
  ConvertTo-XmlParentNode -Content $changeScheds -ChildName 'ChangeRule'

  $passwordRules =  Get-SafeguardAccountPasswordRule -AssetPartition $_.Id
  ConvertTo-XmlParentNode -Content $passwordRules -ChildName 'PasswordRule'

  Write-Output "<AssetDiscoveryJobs>"
  	$url = "AssetPartitions/DiscoveryJobs"
	$partitionId = $_.Id
    $assetJobs = Invoke-Safeguardmethod  -Service core -Method GET -RelativeUrl $url -Accept 'application\json'
	$assetJobs | Where-Object AssetPartitionId -EQ $partitionId  | ForEach-Object {
		Write-Output( '<Job id="{0}" name="{1}" type="{2}">' -f $_.Id, $_.Name, $_.DiscoveryType)

		$_ | ConvertTo-XmlNode -Name "JobObject"

		Write-Output("<Rules>")
		$rules = $_.Rules
		$rules | ForEach-Object {
			Write-Output( '<Rule name="{0}">' -f $_.Name)

			$_ | ConvertTo-XmlNode -Name "RuleObject"

			ConvertTo-XmlParentNode -Content $_.Conditions -ChildName 'Condition' `
				-AttributeMapScript { @{'type' = $_.ConditionType; } }

			Write-Output("</Rule>")
		}
		Write-Output("</Rules>")

		Write-Output "</Job>"
	}
  Write-Output "</AssetDiscoveryJobs>"

  $url = "AssetPartitions/${partitionId}/AccountDiscoverySchedules"
  $accountDJobs = Invoke-Safeguardmethod  -Service core -Method GET -RelativeUrl $url -Accept 'application\json'
  ConvertTo-XmlParentNode -Content $accountDJobs -ChildName 'AccountDiscoveryJob' `
				-ChildContentScript {
					$rules = $_.AccountDiscoveryRules
					ConvertTo-XmlParentNode -Content $Rules -ChildName 'Rule' `
						-AttributeMapScript { @{'name' = $_.Name } }
				}

  $assets = Get-SafeguardAsset -AssetPartitionId $_.Id
  ConvertTo-XmlParentNode -Content $assets -ChildName 'Asset' `
				-AttributeMapScript {
					$platform = $_.Platform
					Return @{'id' = $_.Id; 'name' = $_.Name; 'platform'=$_.PlatformDisplayName; 'platformFamily'=$platform.PlatformFamily; 'platformId'=$platform.Id }
					}	`
				-ChildContentScript {
					$owners = $_.ManagedBy
					ConvertTo-XmlParentNode -Content $owners -ChildName 'Owner' `
						-AttributeMapScript {
							@{'id' = $_.Id
							  'name' = $_.Name;
							  'displayName' = $_.DisplayName;
							  'identityProvider' = $_.IdentityProviderName;
							  'kind' = $_.PrincipalKind
							 }
						}
					$accounts = Get-SafeguardAssetAccount -AssetToGet $_.Id
					ConvertTo-XmlParentNode -Content $accounts -ChildName 'Account' `
							-AttributeMapScript { @{'id' = $_.Id; 'name' = $_.Name; 'type'=$_.AccountType } }	`
				}

  $url = "AssetPartitions/${partitionId}/Tags"
  $tags = Invoke-Safeguardmethod  -Service core -Method GET -RelativeUrl $url -Accept 'application\json'
  ConvertTo-XmlParentNode -Content $tags -ChildName 'Tag' `
				-ChildContentScript {
					$owners = $_.ManagedBy
					ConvertTo-XmlParentNode -Content $owners -ChildName 'Owner' `
						-AttributeMapScript {
							@{'id' = $_.Id; 'name' = $_.Name; 'displayName' = $_.DisplayName; 'identityProvider' = $_.IdentityProviderName; 'kind' = $_.PrincipalKind }
						}
				}


  Write-Output "</Partition>"
}
Write-Output "</Partitions>"


Write-Output "<Entitlements>"
$ents = Get-SafeguardEntitlement
$ents | ForEach-Object {
    Write-Output( '<Entitlement id="{0}" name="{1}">' -f $_.Id, $_.Name)

        $_ | ConvertTo-XmlNode -Name "EntitlementObject"

		ConvertTo-XmlParentNode -Content $_.Members -ChildName 'Member' `
				-AttributeMapScript { @{'id' = $_.Id; 'name' = $_.Name; 'kind'=$_.PrincipalKind } }


		Write-Output "<RequestPolicies>"
		$entitlementId = $_.Id
		$arps = Get-SafeguardAccessPolicy -EntitlementToGet $entitlementId
		$arps | ForEach-Object {
		  $reqProps = $_.AccessRequestProperties
			Write-Output( '<RequestPolicy id="{0}" name="{1}" type="{2}">' -f $_.Id, $_.Name, $reqProps.AccessRequestType)
			$_ | ConvertTo-XmlFragment

			ConvertTo-XmlParentNode -Content $_.ScopeItems -ChildName 'ScopeItem' `
				-AttributeMapScript { @{'id' = $_.Id; 'name' = $_.Name; 'type'=$_.ScopeItemType } }

			Write-Output "</RequestPolicy>"
		}
		Write-Output "</RequestPolicies>"

	Write-Output "</Entitlement>"
}
Write-Output "</Entitlements>"

Write-Output "<Groups>"

  $assetGroups = Get-SafeguardAssetGroup
  ConvertTo-XmlParentNode -Content $assetGroups -ChildName 'AssetGroup' `
				-AttributeMapScript { @{'id' = $_.Id; 'name' = $_.Name; 'isDynamic'=$_.IsDynamic } }	`
				-ChildContentScript {
					if ( $_.IsDynamic ){
						# additional API call to get the human friendly description of rule conditions
						$dynRule = Get-SafeguardDynamicAssetGroup $_.Id
						$dynRule | ConvertTo-XmlNode -Name 'GroupingRule'
					}
					$assets = $_.Assets
					ConvertTo-XmlParentNode -Content $assets -ChildName 'Asset' `
						-AttributeMapScript {
							$platform = $_.Platform
							Return @{'id' = $_.Id; 'name' = $_.Name; 'platform'=$platform.DisplayName; 'platformId'=$platform.Id }
							}	`
				}


  $accountGroups = Get-SafeguardAccountGroup
  ConvertTo-XmlParentNode -Content $accountGroups -ChildName 'AccountGroup' `
				-AttributeMapScript { @{'id' = $_.Id; 'name' = $_.Name; 'isDynamic'=$_.IsDynamic } }	`
				-ChildContentScript {
					if ( $_.IsDynamic ){
						# additional API call to get the human friendly description of rule conditions
						$dynRule = Get-SafeguardDynamicAccountGroup $_.Id
						$dynRule | ConvertTo-XmlNode -Name 'GroupingRule'
					}
					$accounts = $_.Accounts
					ConvertTo-XmlParentNode -Content $accounts -ChildName 'Account' `
							-AttributeMapScript { @{'id' = $_.Id; 'name' = $_.Name; 'type'=$_.AccountType } }	`
				}


  $userGroups = Get-SafeguardUserGroup
  ConvertTo-XmlParentNode -Content $userGroups -ChildName 'UserGroup' `
				-AttributeMapScript {
					$idProvider = $_.IdentityProvider
					Return @{'id' = $_.Id; 'name' = $_.Name; 'type' = $idProvider.TypeReferenceName }
				}	`
				-ChildContentScript {
					$users = $_.Members
					ConvertTo-XmlParentNode -Content $users -ChildName 'User' `
							-AttributeMapScript { @{'id' = $_.Id; 'name' = $_.Name; 'adminRoles' = ($_.AdminRoles -join ',') } }
				}



Write-Output "</Groups>"

Write-Output "<CustomPlatforms>"

 $platforms = Get-SafeguardPlatform
 $platforms |
	Where-Object PlatformType -EQ "Custom" |
	ForEach-Object {
    Write-Output "<!--"
		$pformIn = New-TemporaryFile
		$pformOut = New-TemporaryFile
		$url = "Platforms/" + $_.Id + "/Script"
		Write-Output $url
		Invoke-Safeguardmethod  -Service core -Method GET -RelativeUrl $url -Accept 'application\json' > $pformIn
		certutil.exe -decode -f $pformIn $pformOut
		Write-Output "-->"
		Write-Output( '<Platform id="{0}" name="{1}">' -f $_.Id, $_.Name )
		Write-Output '<Script type="json">'
		Write-Output "<![CDATA[ "
		Get-Content $pformOut
		Write-Output "]]>"
		Write-Output '</Script>'
		Write-Output "</Platform>"
		rm $pformIn
		rm $pformOut
 }

Write-Output "</CustomPlatforms>"

Write-Output "</SPP>"

