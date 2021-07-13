Param (
	[Parameter (Mandatory=$true, Position=1)]
	[string]$WebServer,
	[Parameter (Mandatory=$true, Position=2)]
	[string]$ApplicationPool
)

Write-Host "Trying to stop application pool: $ApplicationPool"

$WebServerСommand = {
	param (
		$ApplicationPool
	)
	
	Import-Module WebAdministration
	
	Write-Output "Stopping application pool $ApplicationPool"
	
	$PoolState = (Get-WebAppPoolState -Name $ApplicationPool).Value
	Write-Output "Current application pool state is `'$PoolState`'"
	if ($PoolState -ne "Stopped") {
		$Counter = 0
		do {
			$Counter += 1
			if ($Counter -gt 120) {
				throw "Application pool is not stopped too long"
			}
			Stop-WebAppPool -Name $ApplicationPool
			Write-Output "Waiting until application pool is stopped 5 seconds..."
			Start-Sleep -Seconds 5
			Write-Output "Getting application pool `'$ApplicationPool`' state information"
			$PoolState = (Get-WebAppPoolState -Name $ApplicationPool).Value
			Write-Output "Current application pool state is `'$PoolState`'"
		} while ($PoolState -ne "Stopped")
	}
	
	Write-Output "Application pool $ApplicationPool stoped successfully!"
}


Invoke-Command -ComputerName $WebServer -Command $WebServerСommand -ArgumentList $ApplicationPool