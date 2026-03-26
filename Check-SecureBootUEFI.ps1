<# 
    Skript: Check-SecureBootUEFI.ps1
    Zweck:
      - Prüft, ob die neuen Secure-Boot-UEFI-Zertifikate (Windows UEFI CA 2023) verwendet werden.
      - Bietet auf Wunsch an, die von Microsoft vorgesehenen Maßnahmen zum Umstieg anzustoßen.
      - Eignet sich für Windows 10/11 mit UEFI Secure Boot.

    WICHTIG:
      - Nur mit Administratorrechten ausführen.
      - Änderungen an Secure-Boot-Zertifikaten können Auswirkungen auf das Bootverhalten haben.
#>

Write-Host "=== Secure Boot / UEFI-Zertifikate prüfen und aktualisieren ===`n"

# 1. Prüfen, ob das Skript mit Administratorrechten läuft
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Dieses Skript muss mit Administratorrechten ausgeführt werden."
    Write-Host "Bitte klicken Sie mit der rechten Maustaste auf PowerShell und wählen Sie 'Als Administrator ausführen'."
    Read-Host "Drücken Sie Enter, um das Skript zu beenden"
    exit 1
}

# 2. Prüfen, ob Secure Boot unterstützt und aktiviert ist
try {
    $secureBootEnabled = Confirm-SecureBootUEFI -ErrorAction Stop
} catch {
    Write-Warning "Dieses System unterstützt das Cmdlet 'Confirm-SecureBootUEFI' nicht."
    Write-Warning "Vermutlich handelt es sich um ein BIOS-System oder Secure Boot ist nicht verfügbar."
    Read-Host "Drücken Sie Enter, um das Skript zu beenden"
    exit 1
}

if (-not $secureBootEnabled) {
    Write-Warning "Secure Boot ist auf diesem Gerät NICHT aktiviert."
    Write-Host  "Ohne aktiven Secure Boot sind die UEFI-Secure-Boot-Zertifikate nicht relevant."
    Read-Host "Drücken Sie Enter, um das Skript zu beenden"
    exit 0
}

# 3. UEFI-Datenbank auslesen und nach alten/neuen Zertifikaten suchen
$hasNewCA = $false
$hasOldCA = $false

try {
    $dbBytes = (Get-SecureBootUEFI -Name db -ErrorAction Stop).Bytes
    $dbText  = [System.Text.Encoding]::ASCII.GetString($dbBytes)

    # Neue Zertifikate (z.B. Windows UEFI CA 2023)
    if ($dbText -match "Windows UEFI CA 2023") {
        $hasNewCA = $true
    }

    # Alte Zertifikate (z.B. 2011er UEFI CA)
    if ($dbText -match "UEFI CA 2011") {
        $hasOldCA = $true
    }
} catch {
    Write-Warning "Die Secure-Boot-Datenbank (db) konnte nicht gelesen werden: $($_.Exception.Message)"
}

# 4. Registry-Status der Zertifikatsmigration auswerten
$uefiStatus = "Nicht vorhanden"
try {
    $servicingKey = "HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\Servicing"
    $uefiStatusValue = (Get-ItemProperty -Path $servicingKey -Name "UEFICA2023Status" -ErrorAction Stop).UEFICA2023Status
    if ($uefiStatusValue) {
        $uefiStatus = $uefiStatusValue
    }
} catch {
    # Key/Value nicht vorhanden -> bleibt "Nicht vorhanden"
}

Write-Host "Aktueller Status:"
Write-Host ("  Secure Boot aktiv:               {0}" -f $secureBootEnabled)
Write-Host ("  Neue Zertifikate (2023) in DB:   {0}" -f $hasNewCA)
Write-Host ("  Alte Zertifikate (2011) in DB:   {0}" -f $hasOldCA)
Write-Host ("  Registry UEFICA2023Status:       {0}" -f $uefiStatus)
Write-Host ""

# 5. Wenn neue Zertifikate bereits vorhanden oder Status 'Updated' ist, nichts tun
if ($hasNewCA -or ($uefiStatus -eq "Updated")) {
    Write-Host "Ihr System verwendet bereits die neuen UEFI-Zertifikate oder der Status ist 'Updated'." -ForegroundColor Green
    Write-Host "Es ist keine weitere Aktion erforderlich."
    Read-Host "Drücken Sie Enter, um das Skript zu beenden"
    exit 0
}

# 6. Anwender fragen, ob die Umstellung gestartet werden soll
Write-Host "Ihr System scheint die neuen UEFI-Zertifikate noch nicht vollständig zu verwenden." -ForegroundColor Yellow
Write-Host ""
Write-Host "Dieses Skript kann jetzt Folgendes tun:"
Write-Host "  - Windows Update anstoßen (soweit möglich),"
Write-Host "  - die von Microsoft vorgesehenen Registry-Flags setzen,"
Write-Host "  - die Secure-Boot-Update-Aufgabe starten und"
Write-Host "  - einen Neustart anbieten."
Write-Host ""
$answer = Read-Host "Möchten Sie fortfahren? (J/N)"

if ($answer.ToUpper() -notin @("J","Y")) {
    Write-Host "Es wurden KEINE Änderungen vorgenommen."
    Read-Host "Drücken Sie Enter, um das Skript zu beenden"
    exit 0
}

# 7. Windows Update bestmöglich anstoßen (optional, best effort)
Write-Host ""
Write-Host "Starte Windows Update. Dies kann einige Zeit dauern..."
try {
    UsoClient StartScan    | Out-Null
    UsoClient StartDownload | Out-Null
    UsoClient StartInstall | Out-Null
} catch {
    Write-Warning "Windows Update konnte nicht automatisch angestoßen werden."
    Write-Warning "Bitte stellen Sie sicher, dass Ihr System über Windows Update aktuell ist."
}

# 8. Registry-Flag AvailableUpdates = 0x5944 setzen (vollständige Secure-Boot-Migration)
Write-Host ""
Write-Host "Setze Secure-Boot-Update-Flags (AvailableUpdates = 0x5944)..."

try {
    $secureBootKey = "HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot"
    # Sicherstellen, dass der Key existiert
    if (-not (Test-Path $secureBootKey)) {
        New-Item -Path $secureBootKey -Force | Out-Null
    }

    New-ItemProperty -Path $secureBootKey -Name "AvailableUpdates" -PropertyType DWord -Value 0x5944 -Force | Out-Null
    Write-Host "Der Registry-Wert 'AvailableUpdates' wurde erfolgreich auf 0x5944 gesetzt."
} catch {
    Write-Error "Fehler beim Setzen des Registry-Werts 'AvailableUpdates': $($_.Exception.Message)"
    Read-Host "Drücken Sie Enter, um das Skript zu beenden"
    exit 1
}

# 9. Geplante Aufgabe 'Secure-Boot-Update' starten
Write-Host "Starte die geplante Aufgabe 'Secure-Boot-Update'..."
try {
    Start-ScheduledTask -TaskName "\Microsoft\Windows\PI\Secure-Boot-Update"
    Write-Host "Die Aufgabe 'Secure-Boot-Update' wurde gestartet."
} catch {
    Write-Warning "Die Aufgabe 'Secure-Boot-Update' konnte nicht gestartet werden."
    Write-Warning "In vielen Fällen wird sie automatisch beim nächsten Neustart ausgeführt."
}

Write-Host ""
Write-Host "Die Änderungen wurden vorbereitet." -ForegroundColor Yellow
Write-Host "Damit die neuen Zertifikate in den UEFI-Secure-Boot-Speicher übernommen werden,"
Write-Host "ist mindestens ein Neustart erforderlich (oft sind mehrere Reboots nötig)."
Write-Host ""

$rebootAnswer = Read-Host "Computer jetzt neu starten? (J/N)"
if ($rebootAnswer.ToUpper() -in @("J","Y")) {
    Write-Host "Der Computer wird jetzt neu gestartet..."
    Restart-Computer -Force
} else {
    Write-Host "Bitte starten Sie den Computer später manuell neu, damit das Update abgeschlossen werden kann." -ForegroundColor Yellow
    Read-Host "Drücken Sie Enter, um das Skript zu beenden"
}
