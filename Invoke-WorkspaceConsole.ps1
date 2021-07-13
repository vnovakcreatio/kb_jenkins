function Invoke-WorkspaceConsole {
	<#
	.SYNOPSIS
		Запуск утилиты WorkspaceConsole.
	.PARAMETER $WCDirectory
		Название директории, в которой находится WorkspaceConsole.
	.PARAMETER $WCArgs
		Параметры для запуска утилиты WorkspaceConsole.
	.PARAMETER $SkipInstallDataErrors
		Признак позволяющий пропустить ошибки устновки данных.
	.PARAMETER $SkipInstallSqlScriptErrors
		Признак позволяющий пропустить ошибки выполнения sql скриптов.
	#>
	param (
		[Parameter(Mandatory = $True)]
		[String] $WCDirectory,
		[Parameter(Mandatory = $True)]
		[Hashtable] $WCArgs,
		[Switch] $SkipInstallDataErrors = $False,
		[Switch] $SkipInstallSqlScriptErrors = $False,
		[Switch] $EscapeLogChars = $False,
		[String[]] $SecretArgs = @()
	)
	Write-Host "[Invoke-WorkspaceConsole] Invoking WorkspaceConsole"

	[String[]] $WCPathArgs = @("-workingCopyPath", "-sourcePath", "-destinationPath", "-logPath", "-webApplicationPath", "-confRuntimeParentDirectory")
	[System.Object] $WCArgsList = New-Object System.Collections.ArrayList
	$OutputWCArgs = New-Object System.Collections.ArrayList
	foreach ($WCArgKey in $WCArgs.Keys) {
		[String] $WCArgValue = $WCArgs.Item($WCArgKey)
		if ($WCPathArgs.Contains($WCArgKey)) {
			$WCArgValue = Remove-EndingDirectorySeparator $WCArgValue
		}
		$WCArgsList.Add("`"$WCArgKey=$WCArgValue`"") | Out-Null
		if ($SecretArgs -contains $WCArgKey) {
			$OutputWCArgs.Add("`"$WCArgKey=*****`"") | Out-Null
		} else {
			$OutputWCArgs.Add("`"$WCArgKey=$WCArgValue`"") | Out-Null
		}
	}
	if (-not $WCArgs.ContainsKey("-autoExit")) {
		$WCArgsList.Add("-autoExit=true") | Out-Null
		$OutputWCArgs.Add("-autoExit=true") | Out-Null
	}
	[String] $WCFile = [System.IO.Path]::Combine($WCDirectory, "Terrasoft.Tools.WorkspaceConsole.exe")

	[Int] $ExitCode = -1
	[String] $ErrorOutputValue
	[System.Object] $WCProcess = New-Object System.Diagnostics.Process
	try {
		$WCProcess.StartInfo.UseShellExecute = $False;
		$WCProcess.StartInfo.RedirectStandardInput = $True;
		$WCProcess.StartInfo.RedirectStandardOutput = $True;
		$WCProcess.StartInfo.RedirectStandardError = $True;
		$WCProcess.StartInfo.CreateNoWindow = $True;
		$WCProcess.StartInfo.StandardOutputEncoding = [System.Text.Encoding]::GetEncoding("cp866")
		$WCProcess.StartInfo.FileName = $WCFile;
		$WCProcess.StartInfo.Arguments = $WCArgsList;

		Write-Host "Running WorkspaceConsole"
		Write-Host "Terrasoft.Tools.WorkspaceConsole.exe $OutputWCArgs"

		$ExceptionList = New-Object System.Collections.ArrayList
		$ExceptionList.Add("Delete_Dublicate_LeadType") | Out-Null
		$ExceptionList.Add("RemoveEnglishCountriesFromCountryMSSql") | Out-Null
		$ExceptionList.Add("CompilerError") | Out-Null

		$WCProcess.Start() | Out-Null
		while (-not $WCProcess.StandardOutput.EndOfStream) {
			[string] $OutputValue = $WCProcess.StandardOutput.ReadLine();
			if ($EscapeLogChars) {
				$OutputValue = $OutputValue -replace "\[", "{"
				$OutputValue = $OutputValue -replace "]", "}"
			}
			Write-Host $OutputValue
			foreach ($Exception in $ExceptionList) {
				if (($OutputValue.Contains($Exception))) {
					$OutputValue = ""
				}
			}
			if (($OutputValue -contains "Работа утилиты закончена. Для закрытия окна нажмите 'Ввод'") `
				-or ($OutputValue -contains "Process completed. To close the utility, click 'Enter'") `
				-or ($OutputValue -contains "Работа утилиты закончена.") `
				-or ($OutputValue -contains "Utility finished working.") `
				-or ($OutputValue -contains "Prace utility byla ukoncena.")) {
				$WCProcess.StandardInput.Write([Char]13)
			}
		}
		$WCProcess.WaitForExit()
		$ExitCode = $WCProcess.ExitCode
	} catch {
		Write-Host "Entered into the catch block"
		Write-Error $_
		$ExitCode = -1
	} finally {
		Write-Host "Entered into the finally block"
		if ($WCProcess.StandardError) {
			$ErrorOutputValue = $WCProcess.StandardError.ReadToEnd()
		}
		$WCProcess.Close()
	}
	Write-Host "WorkspaceConsole exited with code $ExitCode."

	[int] $InstallDataErrorCode = -2
	[int] $InstallSqlScriptErrorCode = -3

	if (($ExitCode -eq 0) -or
		($ExitCode -eq $InstallDataErrorCode -and $SkipInstallDataErrors) -or
		($ExitCode -eq $InstallSqlScriptErrorCode -and $SkipInstallSqlScriptErrors)) {
	} else {
		if ($ErrorOutputValue) {
			Write-Host $ErrorOutputValue
		}
		throw "WorkspaceConsole executed with errors"
	}

	Write-Host "[]"
}

function Remove-EndingDirectorySeparator {
	param (
		[Parameter(Mandatory = $True)]
		[String] $Directory
	)
	return [System.IO.Path]::GetDirectoryName([System.IO.Path]::Combine($Directory,"fake"))
}