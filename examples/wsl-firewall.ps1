# Run this script as Administrator (right-click → Run with PowerShell)
# Adds inbound UDP 7777 for Astroneer dedicated server

$ruleName = "Astroneer UDP 7777"
$existing = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue

if ($existing) {
    Write-Host "Firewall rule '$ruleName' already exists."
} else {
    New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Protocol UDP -LocalPort 7777 -Action Allow
    Write-Host "Created firewall rule '$ruleName'."
}
