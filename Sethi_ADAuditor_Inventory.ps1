param(
  [Parameter(Mandatory)]
  [String]$exportPath,
  [Parameter(Mandatory)]
  [String]$Domains,
  [Parameter(Mandatory)]
  [int16]$days
)

function ReportDirectory {
  $reportfolder = "$exportPath"
  if (!(Test-Path -path $reportfolder)) {
    Write-Host $reportfolder "Not found, Creating it."
    New-Item $reportfolder -type directory
  }
}

ReportDirectory

$90days = (Get-Date).AddDays($days)

foreach ($DomainName in $Domains) {
  
  Write-Warning "Checking $($DomainName)"
  $Domain = (Get-ADDomain $DomainName).DNSRoot
  
  Get-GPO -All -Server $Domain | Where-Object {$_.ModificationTime -gt $90days -or $_.CreationTime -gt $90days} | Select-Object DisplayName,DomainName,CreationTime,ModificationTime | Export-CSV $exportPath\GPOUpdateReport.csv -NoTypeInformation

  Get-ADObject -Filter * -Server $Domain -Properties Name,WhenCreated,whenChanged,ObjectClass | Where-Object {$_.whenCreated -gt $90days -and ` ($_.ObjectClass -like "computer" -or $_.ObjectClass -like "User" -or $_.ObjectClass -like "Group")} | Select-Object Name,@{N="ObjectType";E={$_.ObjectClass}},WhenCreated,whenChanged | Export-Csv $exportPath\ADOjectReport.csv -NoTypeInformation
  
  Get-ADObject -Filter "Name -like '*DEL:*'" -Server $Domain -IncludeDeletedObjects -Properties Name,whenChanged,ObjectClass,LastKnownParent,Deleted | Where-Object {$_.whenChanged -gt $90days} | Select-Object Name,whenChanged,@{N="ObjectType";E={$_.ObjectClass}},LastKnownParent,Deleted | Export-Csv $exportPath\ADOjectDeletedReport.csv -NoTypeInformation
  
  Get-ADUser -Filter "Enabled -eq '$True'" -Server $Domain -Properties AccountExpirationDate | Where-Object {$_.AccountExpirationDate -gt $90days} | Select-Object -Property SamAccountName, AccountExpirationDate |Export-Csv $exportPath\ADUserExpiredReport.csv -NoTypeInformation

}

