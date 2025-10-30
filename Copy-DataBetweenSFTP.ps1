# Framework: Powershell CUSD template for vendor student data upload
# Please familiarize yourself with the code and packages and use at your own risk
# Copy file(s) between two SFTP servers
# Requires the Posh-SSH module: Install-Module -Name Posh-SSH
[cmdletbinding()]
param (
 [Parameter(Mandatory = $True)][Alias('srcSrv')][string]$SourceSFTPServer,
 [Parameter(Mandatory = $false)][Alias('srcPort')][int]$SourceSFTPPort = 22,
 [Parameter(Mandatory = $True)][Alias('srcCred')][System.Management.Automation.PSCredential]$SourceSFTPCredential,
 [Parameter(Mandatory = $true)][Alias('srcDir')][string]$SourceSFTPDirectory,
 [Parameter(Mandatory = $true)][Alias('srcFile')][string]$SourceSFTPFileName,
 [Parameter(Mandatory = $True)][Alias('destSrv')][string]$DestinationSftpServer,
 [Parameter(Mandatory = $false)][Alias('destPort')][int]$DestinationSftpPort = 22,
 [Parameter(Mandatory = $True)][Alias('destCred')][System.Management.Automation.PSCredential]$DestinationSftpCredential,
 [Parameter(Mandatory = $True)][Alias('destDir')][string]$DestinationSFTPDirectory,
 [Parameter(Mandatory = $True)][Alias('destFile')][string]$DestinationSFTPFileName,
 [Alias('wi')][switch]$WhatIf
)

function Copy-LatestToLocal {
 process {
  [string]$remoteFilePath = '{0}/{1}' -f $_.srcParams.remoteDirectory, $_.newName
  Write-Host ('{0},{1},{2}' -f $MyInvocation.MyCommand.Name, $remoteFilePath, $_.localDataPath) -F Blue
  Get-SFTPItem -SessionId $_.srcSession.SessionId -Path $remoteFilePath -Destination $_.localDataPath -Force -Verbose
  return $_
 }
}

function Copy-LatestToRemote {
 process {
  $_.localFilePath = (Join-Path -Path $_.localDataPath -ChildPath $_.newName)
  Write-Host ('{0},{1},{2}' -f $MyInvocation.MyCommand.Name, $_.localFilePath, $_.destParams.remoteDirectory) -F Blue
  Set-SFTPItem -SessionId $_.destSession.SessionId -Path $_.localFilePath -Destination $_.destParams.remoteDirectory -Force -Verbose
  $_
 }
}

function Get-LatestFile {
 process {
  [string]$matchName = $_.srcParams.fileName
  Write-Host ('{0},{1}' -f $MyInvocation.MyCommand.Name, $_.srcParams.fileName) -F Green
  #TODO
  $_.latestFile = Get-SFTPChildItem -SessionId $_.srcSession.SessionId -Path $_.srcParams.remoteDirectory |
   Where-Object { ($_.LastWriteTime -gt (Get-Date).AddDays(-2)) -and ($_.FullName -match $matchName) } | Select-Object -First 1
  Write-Host ('{0},Found: {1}' -f $MyInvocation.MyCommand.Name, $_.latestFile.FullName) -F Green
  return $_
 }
}

function New-CopyObject ($srcSession, $destSession, $srcParams, $destParams, $dataPath) {
 process {
  [PSCustomObject]@{
   srcSession    = $srcSession
   srcParams     = $srcParams
   destSession   = $destSession
   destParams    = $destParams
   latestFile    = $null
   localDataPath = $dataPath
   localFilePath = $null
   newName       = $null
  }
 }
}

function Rename-LatestFile {
 process {
  $_.newName = '{0}-{1}-{2}' -f $_.srcParams.remoteDirectory.Replace('/', ''), $_.srcParams.fileName.ToUpper(), (Get-Date -Format 'yyyy-MM-dd')
  if ($_.latestFile.FullName -match $_.newName) {
   Write-Host ('{0},No rename needed for {1}' -f $MyInvocation.MyCommand.Name, $_.latestFile.FullName) -F Yellow
   return $_
  }
  Write-Host ('{0},{1}' -f $MyInvocation.MyCommand.Name, $_.newName)
  Rename-SFTPFile -SessionId $_.srcSession.SessionId -Path $_.latestFile.FullName -NewName $_.newName
  $_
 }
}

function Remove-LocalCopy {
 process {
  Write-Host ('{0},{1}' -f $MyInvocation.MyCommand.Name, $_.localFilePath) -F Yellow
  Remove-Item -Path $_.localFilePath -Force -Confirm:$false
 }
}

# ==================== Main =====================
# Imported Functions
Import-Module -Name CommonScriptFunctions -Cmdlet New-SqlOperation, Show-BlockInfo
Import-Module -Name Posh-SSH -Cmdlet New-SFTPSession, Set-SFTPItem, Remove-SFTPSession

$sourceParams = @{
 remoteDirectory = $SourceSFTPDirectory
 sourcePath      = $SourceSFTPDirectory
 fileName        = $SourceSFTPFileName
}
$destinationParams = @{
 remoteDirectory = $DestinationSFTPDirectory
 destinationPath = $DestinationSFTPDirectory
 fileName        = $DestinationSFTPFileName
}
Write-Host ('{0},Connecting to Source SFTP {1}' -f $MyInvocation.MyCommand.Name, $SourceSFTPServer) -F Green
$sourceSession = New-SFTPSession -ComputerName $SourceSFTPServer -Credential $SourceSFTPCredential -Port $SourceSFTPPort -AcceptKey
Write-Host ('{0},Connecting to Destination SFTP {1}' -f $MyInvocation.MyCommand.Name, $DestinationSftpServer) -F Green
$destinationSession = New-SFTPSession -ComputerName $DestinationSftpServer -Credential $DestinationSftpCredential -Port $DestinationSftpPort -AcceptKey

$outPath = '.\data\'

New-CopyObject $sourceSession $destinationSession $sourceParams $destinationParams $outPath |
 Get-LatestFile |
  Rename-LatestFile |
   Copy-LatestToLocal |
    Copy-LatestToRemote |
     Remove-LocalCopy

Get-SFTPSession | Remove-SFTPSession