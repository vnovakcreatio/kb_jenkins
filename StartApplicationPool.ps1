Param (
	[Parameter (Mandatory=$true, Position=1)]
	[string]$WebServer,
	[Parameter (Mandatory=$true, Position=2)]
	[string]$ApplicationPool
)

Write-Host "Trying to start application pool: $ApplicationPool"

$WebServerCommand = {
	param (
		$ApplicationPool
	)
	
	Import-Module WebAdministration
	
	if(!(Test-Path IIS:\AppPools\$ApplicationPool))
	{
		Write-Error "Application pool $ApplicationPool is not exists"
		return
	}
	
	
	Write-Output "Starting application pool $ApplicationPool"
	
	$PoolState = (Get-WebAppPoolState -Name $ApplicationPool).Value
	Write-Output "Current application pool state is `'$PoolState`'"
	if ($PoolState -ne "Started") {
		$Counter = 0
		do {
			$Counter += 1
			if ($Counter -gt 20) {
				throw "Application pool is not start too long"
			}
			Start-WebAppPool -Name $ApplicationPool
			Write-Output "Waiting until application pool start 5 seconds..."
			Start-Sleep -Seconds 5
			Write-Output "Getting application pool `'$ApplicationPool`' state information"
			$PoolState = (Get-WebAppPoolState -Name $ApplicationPool).Value
			Write-Output "Current application pool state is `'$PoolState`'"
		} while ($PoolState -ne "Started")
	}
	
	Write-Output "Application pool $ApplicationPool started successfully!"
}


Invoke-Command -ComputerName $WebServer -Command $WebServerCommand -ArgumentList $ApplicationPool