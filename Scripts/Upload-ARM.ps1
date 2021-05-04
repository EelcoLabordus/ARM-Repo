<#
  .SYNOPSIS
  This script will upload the ARm templates to the Azure template spec.

  .DESCRIPTION
  This script will upload the ARm templates to the Azure template spec.

  .PARAMETER path
   Specified path were the ARM files are located.

  .PARAMETER ResourceGroupName
  Specified the Resource Group Name.

  .PARAMETER Location
  Specified location where the resource group is located

  .INPUTS
  None

  .OUTPUTS
  None

  .NOTES
  Version:         1.0.0
  Author:          Eelco Labordus
  Change Log

  .EXAMPLE

#>

[CmdletBinding()]
Param (
    [Parameter(HelpMessage = "Specified path were the ARM files are located.")][string]$path,
    [Parameter(HelpMessage = "Specified the Resource Group Name.")][string]$ResourceGroupName,
    [Parameter(HelpMessage = "Specified location where the resource group is located.")][string]$Location = "WestEurope"
)

#requires -Version 5.0
#requires -Module PowerShellGet

#region----------------------------------------------------------[ Declarations ]----------------------------------------------------------

#endregion----------------------------------------------------------[ Declarations ]----------------------------------------------------------

#region---------------------------------------------------------[ Initializations ]--------------------------------------------------------

#Install required resources
if (!(Get-InstalledModule -Name Az.Resources -ErrorAction SilentlyContinue)) {
    Write-Output -InputObject "Installing Az.Resources module!"

    #ToDo: Currently only the prerelease module support Azure Template Specs. Remove when official released.
    Install-Module -Name Az.Resources -AllowPrerelease -Force -AllowClobber -SkipPublisherCheck | Out-Null
}

Import-Module -Name Az.Resources -ErrorAction Stop

#Validation check if script is connected to correct Tenant and subscription. If not login required.
$CheckResourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue

if (!($CheckResourceGroup)) {
    #Todo : Cleanup code at error validation
    Write-Output -InputObject "$ResourceGroupName not found logging of end trying again."
    #Pipelines functionality is build into this.
    Disconnect-AzAccount

    Connect-AzAccount

    Get-AzSubscription | Out-GridView -PassThru | Select-AzSubscription

}

#endregion---------------------------------------------------------[ Initializations ]--------------------------------------------------------

#region-----------------------------------------------------------[ Execution ]------------------------------------------------------------

#Retrieve all metadata files from the repository, this files are necessary to retrieve name and descriptions.
$ARMmetadataFiles = Get-ChildItem -Path $path -Recurse  -filter *.metadata.json

#Proces all templates
foreach ($ARMmetadataFile in $ARMmetadataFiles) {

    #Setting up variables
    $BaseName = $ARMmetadataFile.BaseName.Split(".")[0]
    $DirectoryName = $ARMmetadataFile.DirectoryName
    $JSONInfo = Get-Content -raw -Path $ARMmetadataFile.FullName | ConvertFrom-Json

    Write-Output -InputObject "Uploading $BaseName to Azure"

    if ($env:BUILD_BUILDNUMBER) {
        #When running script from Azure DevOps buildnumbers are used for versioning.
        [String]$NewAzTemplateSpecVersion = $env:BUILD_BUILDNUMBER
        Write-Output -InputObject "RELEASE_ARTIFACTS found version number will be $NewAzTemplateSpecVersion"
    }
    else {
        #When script is not triggered from Azure Devops. Versioning number is generated.

        #Checking if the template already exist, if that is the case update version number.
        $AzTemplateSpec = Get-AzTemplateSpec -ResourceGroupName azr-cmp-t-ARMStorage-rg -Name $JSONInfo.itemDisplayName -ErrorAction SilentlyContinue

        if ($AzTemplateSpec) {
            #When version is found Minor version is updated.
            $v = [version]$AzTemplateSpec.Versions.name[-1]
            [String]$NewAzTemplateSpecVersion = [version]::New($v.Major, $v.Minor + 1)
            Write-Output -InputObject "Existing template found changing version from $v to $NewAzTemplateSpecVersion"
        }
        else {
            #No version has been found generate new version 1.0
            [String]$NewAzTemplateSpecVersion = "1.0"
            Write-Output -InputObject "Existing template not found version number will be $NewAzTemplateSpecVersion"
        }
    }

    $AzTemplateSpec = @{
        Name              = $JSONInfo.itemDisplayName
        Version           = $NewAzTemplateSpecVersion
        ResourceGroupName = $ResourceGroupName
        Location          = $Location
        TemplateFile      = "$DirectoryName\$BaseName.json"
        Description       = $JSONInfo.description
        Force             = $true
    }

    #Adding the template to Azure.
    Write-Output -InputObject $AzTemplateSpec
    New-AzTemplateSpec @AzTemplateSpec
}

#endregion-----------------------------------------------------------[ Execution ]------------------------------------------------------------