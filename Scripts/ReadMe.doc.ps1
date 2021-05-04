#
# Azure Resource Manager documentation definitions
#

# https://mscloud.be/azure/Dynamically-create-README-from-azdo-pipeline-and-commit-repository/

# A function to break out parameters from an ARM template
function GetTemplateParameter {
    param (
        [Parameter(Mandatory = $True)]
        [String]$Path
    )

    process {
        $template = Get-Content $Path | ConvertFrom-Json;
        foreach ($property in $template.parameters.PSObject.Properties) {
            [PSCustomObject]@{
                Name = $property.Name
                Description = $property.Value.metadata.description
            }
        }
    }
}

# A function to import metadata
function GetTemplateMetadata {
    param (
        [Parameter(Mandatory = $True)]
        [String]$Path
    )

    process {
        $metadata = Get-Content $Path | ConvertFrom-Json;
        return $metadata;
    }
}

# Description: A definition to generate markdown for an ARM template
document 'README' {

    # Read JSON files
    $metadata = GetTemplateMetadata -Path $InputObject.MetadataFile;
    $parameters = GetTemplateParameter -Path $InputObject.ARMTemplate;

    "[![Build Status](https://dev.azure.com/#######/IaC/_apis/build/status/$($InputObject.PipelineName)?branchName=Dev)](https://dev.azure.com/#######/IaC/_build/latest?definitionId=$($InputObject.PipelineID)&branchName=Dev)"

    # Set document title
    Title $metadata.itemDisplayName

    # Write opening line
    $metadata.Description

    # Add each parameter to a table
    Section 'Parameters' {
        $parameters | Table -Property @{ Name = 'Parameter name'; Expression = { $_.Name }},Description
    }

    # Generate example command line
    Section 'Use the template' {
        Section 'PowerShell' {
            'New-AzResourceGroupDeployment -Name <deployment-name> -ResourceGroupName <resource-group-name> -TemplateFile <path-to-template>' | Code powershell
        }

        Section 'Azure CLI' {
            'az group deployment create --name <deployment-name> --resource-group <resource-group-name> --template-file <path-to-template>' | Code text
        }

        Section 'Azure Custom Template' {
            "[![Deploy to Azure](https://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/$($InputObject.LinkedTemplateURI))"
        }
    }
}