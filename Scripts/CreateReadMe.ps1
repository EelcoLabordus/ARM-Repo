param (
	[Parameter(Mandatory=$true)]
    [string]$WorkingDir,
    [Parameter(Mandatory=$true)]
    [string]$PipelineName,
    [Parameter(Mandatory=$true)]
    [string]$PipelineID,
    [string]$DocTemplatePath = 'Scripts\ReadMe.doc.ps1',
    [string]$LinkedTemplatePath = 'https://<storageaccount>.blob.core.windows.net/arm/'
)

Install-Module -Name PSDocs -Force -Verbose

$templatefile = "$WorkingDir\Repo\StorageAccount\StorageAccount.json"
$metadatafile = "$WorkingDir\Repo\StorageAccount\StorageAccount.metadata.json"



$PSDocsInputObject = New-Object PsObject -property @{
    'MetadataFile' = $metadatafile
    'ARMTemplate' = $templatefile
    'LinkedTemplateURI' = [uri]::EscapeDataString($LinkedTemplatePath + $PipelineName +"/azuredeploy.json")
    'PipelineID' = $PipelineID
    'PipelineName' = $PipelineName
}

Invoke-PSDocument -Path "$WorkingDir\$DocTemplatePath" -InputObject $PSDocsInputObject -OutputPath "$WorkingDir$WorkingDir\Repo\StorageAccount" -Instance README -Verbose