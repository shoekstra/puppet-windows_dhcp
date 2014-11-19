Param (
  [Parameter(Mandatory=$true)]
  [String]$Name,
  [Parameter(Mandatory=$true)]
  $ScopeId
)

$foScope = (Get-DhcpServerv4Failover -Name $Name).ScopeId

foreach ($fs in $foScope) {
  # loop through existing scopes and remove them if they're not in $ScopeId.
  if ($ScopeId -notcontains $fs) {
    Write-Host Remove-DhcpServerv4FailoverScope -Name $Name -ScopeId $fs
  }
}

foreach ($s in $ScopeId) {
  # loop through $ScopeId and add scopes if they're missing from existing scopes.
  if ($foScope -notcontains $s) {
    Write-Host Add-DhcpServerv4FailoverScope -Name $Name -ScopeId $s
  }
}
