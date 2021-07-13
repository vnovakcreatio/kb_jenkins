param (
	[Parameter (Mandatory=$true, Position=1)]
	[string] $ApplicationPath,
	[Parameter (Mandatory=$true, Position=1)]
	[string] $WCDirectory
)

Clear-Host 

Import-Module "$PSScriptRoot\Invoke-WorkspaceConsole.ps1"

[hashtable] $WCArgs = @{
	"-operation" = "InstallFromRepository";
	"-skipValidateActions" = "True";
	"-updateDBStructure" = "True";
	"-installPackageSqlScript" = "True";
	"-continueIfError" = "True";
	"-configurationPath" = "$ApplicationPath\Terrasoft.WebApp\Terrasoft.Configuration";
	"-workspaceName" = "Default";
	"-webApplicationPath" = $ApplicationPath;
	"-confRuntimeParentDirectory" = "$ApplicationPath\Terrasoft.WebApp";
	"-sourcePath" = "$ApplicationPath\Pkg";
	"-regenerateSchemaSources" = "True";
	"-installPackageData" = "True";
	"-destinationPath" = "$PSScriptRoot\Temp";
	"-autoExit" = "True";
}

Invoke-WorkspaceConsole -WCArgs $WCArgs -WCDirectory $WCDirectory