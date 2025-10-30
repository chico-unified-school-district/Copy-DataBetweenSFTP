# Framework: Powershell CUSD template for vendor student data upload
# This is just a sample template to serve as an example of how SQL and SFTP tasks can be automated.
# Please familiarize yourself with the code and packages and use at your own risk
# Extract file(s) and send via SFTP
[cmdletbinding()]
param (
 [Parameter(Mandatory = $True)][string]$SourceSFTPServer,
 [Parameter(Mandatory = $True)][int]$SourceSFTPPort = 22,
 [Parameter(Mandatory = $True)][System.Management.Automation.PSCredential]$SourceSFTPCredential,
 [Parameter(Mandatory = $true)][string]$SourceSFTPDirectory,
 [Parameter(Mandatory = $true)][string]$SourceSFTPFileName,
 [Parameter(Mandatory = $True)][string]$DestinationSftpServer,
 [Parameter(Mandatory = $True)][int]$DestinationSftpPort = 22,
 [Parameter(Mandatory = $True)][System.Management.Automation.PSCredential]$DestinationSftpCredential,
 [Parameter(Mandatory = $True)][string]$DestinationSFTPDirectory,
 [Parameter(Mandatory = $True)][string]$DestinationSFTPFileName,
 [Alias('wi')][switch]$WhatIf
)

function Copy-ExportToRemote ($server, $port, $user, $exportedFilePath, $exportPath, $destinationDirectory) {
 Write-Host ('{0}' -f $MyInvocation.MyCommand.Name)
 $Session = New-SFTPSession -ComputerName $server -Credential $user -Port $port -AcceptKey:$true
 Set-SFTPItem -SessionId $Session.SessionId -Path $exportedFilePath -Destination $destinationDirectory -Force -Verbose
 Remove-SFTPSession -SessionId $Session.SessionId
}

function Get-RemoteData ($server, $user, $port, $rootDir, $sourceFile, $destinationDirectory) {
 Write-Host ('{0}' -f $MyInvocation.MyCommand.Name)
 $Session = New-SFTPSession -ComputerName $server -Credential $user -Port $port -AcceptKey:$true
 Get-SFTPItem -SessionId $Session.SessionId -Path (Join-Path -Path $rootDir -ChildPath $sourceFile) -Destination $destinationDirectory -Force -Verbose
 Remove-SFTPSession -SessionId $Session.SessionId
}

function New-DataDir ($dataPath) {
 if (Test-Path -Path $dataPath) { return }
 New-Item -Path $dataPath -ItemType Directory -Confirm:$false -Force
}

function New-Object () {
 process {
  Write-Host ('{0}' -f $MyInvocation.MyCommand.Name)

 }
}

# ==================== Main =====================

# Imported Functions
Import-Module -Name CommonScriptFunctions -Cmdlet New-SqlOperation, Show-BlockInfo
Import-Module -Name Posh-SSH -Cmdlet New-SFTPSession, Set-SFTPItem, Remove-SFTPSession

$outPath = '.\data\'
# $sourceExportPath = (Join-Path -Path $outPath -ChildPath $SourceSFTPFileName)
New-DataDir $outPath

$fullExportPath = (Join-Path -Path $outPath -ChildPath $ExportName)

$sourceParams = @{
 # Server           = $SourceSFTPServer
 # Port             = $SourceSFTPPort
 # Credential       = $SourceSFTPCredential
 RemoteDirectory  = $SourceSFTPDirectory
 FileName         = $SourceSFTPFileName
 DestinationPath  = $outPath
}

$destinationParams = @{
 # Server           = $DestinationSftpServer
 # Port             = $DestinationSftpPort
 # Credential       = $DestinationSftpCredential
 RemoteDirectory  = $DestinationSFTPDirectory
 FileName         = $DestinationSFTPFileName
 DestinationPath  = $fullExportPath
}

$sourceSession = New-SFTPSession -ComputerName $SourceSFTPServer -Credential $SourceSFTPCredential -Port $SourceSFTPPort -AcceptKey
$destinationSession = New-SFTPSession -ComputerName $DestinationSftpServer -Credential $DestinationSftpCredential -Port $DestinationSftpPort -AcceptKey

Get-RemoteData $SourceSFTPServer $SourceSFTPPort $SourceSFTPCredential $SourceSFTPDirectory $SourceSFTPFileName $outPath
# | Export-Csv -NoTypeInformation -Path $fullExportPath
# $csvContent = Get-Content -Path $fullExportPath -Raw
# Remove double quotes from the CSV content
# $csvContent = $csvContent.Replace('"', '')
# Write-Host "Double quotes removed from '$fullExportPath'."
# Write the modified content back to the CSV file
# Set-Content -Path $fullExportPath -Value $csvContent -Encoding UTF8

# Copy-ExportToRemote $SftpServer $DestinationSftpPort $SftpCredential $fullExportPath $RemoteDirectory
# Remove-Item -Path $fullExportPath -Confirm:$false -Force