# Secure-Boot-UEFI-Zertifikate prüfen und aktualisieren 

Dieses Skript prüft, ob dein Windows-PC bereits die **neuen Secure-Boot-UEFI-Zertifikate (\"Windows UEFI CA 2023\")** verwendet und kann bei Bedarf die von Microsoft vorgesehenen Schritte zum Umstieg anstoßen.
Windows PCs mit alten Zertifikaten starten nach dem 24.–27. Juni 2026 nicht mehr !!!

Wenn du mehr dazu möchten willst, kannst du die Infos offiziell bei Microsoft nachlesen: https://support.microsoft.com/de-de/topic/ablauf-des-windows-secure-boot-zertifikats-und-updates-der-zertifizierungsstelle-7ff40d33-95dc-4c3c-8725-a9b95457578e

Das Skript ist für **Einzelgeräte** gedacht (Privatrechner) und stellt dem Benutzer einfache Ja/Nein-Fragen. Wenn du einen Firmenrechner hast, wird sich (hoffentlich) deine IT-Abteilung darum kümmern.

Das Skript und diese Anleitung wurde mit Hilfe von KI generiert und wurde NICHT auf Herz und Nieren geprüft. Alle durchlaufenen Tests waren aber erfolgreich.

***

## Funktionen des Skripts

- Prüft, ob Secure Boot auf dem Gerät unterstützt und aktiviert ist.
- Liest die Secure-Boot-Datenbank (UEFI-DB) aus und prüft, ob die neuen Zertifikate \"Windows UEFI CA 2023\" bereits vorhanden sind.
- Liest den Registry-Status `UEFICA2023Status`, der anzeigt, ob das Zertifikatsupdate laut Windows bereits abgeschlossen ist.
- Wenn die neuen Zertifikate noch nicht aktiv sind, fragt das Skript den Benutzer, ob die empfohlenen Schritte ausgeführt werden sollen.
- Setzt bei Zustimmung die notwendigen Registry-Werte und startet die zuständige geplante Aufgabe.
- Bietet am Ende einen Neustart des Computers an.

***

## Voraussetzungen

- Windows 10 oder Windows 11
- UEFI-Firmware mit aktiviertem **Secure Boot** (moderne Geräte erfüllen das in der Regel)
- Ein Benutzerkonto mit **Administratorrechten**

***

## 1. Skript speichern

Lade Das PowershellScript (https://github.com/DerSucker/SecureBootUEFI/blob/main/Check-SecureBootUEFI.ps1) z.B. nach C:\Tools runter oder speichere es folgendermaßen:

1. Öffne den Windows-Editor (**Notepad**):
   - Startmenü öffnen, nach **"Editor"** oder **"Notepad"** suchen und starten.
2. Kopiere den vollständigen PowerShell-Code des Skripts (https://github.com/DerSucker/SecureBootUEFI/blob/main/Check-SecureBootUEFI.ps1) in das leere Editor-Fenster.
3. Klicke im Editor auf **"Datei" → "Speichern unter…"**.
4. Wähle einen Ordner, z. B. `C:\Tools`.
5. Gib als Dateinamen z. B. ein:

   ```text
   Check-SecureBootUEFI.ps1
   ```

6. Stelle bei **Dateityp** sicher, dass **"Alle Dateien (*.*)"** ausgewählt ist.
7. Klicke auf **"Speichern"**.

Jetzt liegt die Datei z. B. unter:

```text
C:\Tools\Check-SecureBootUEFI.ps1
```

***

## 2. PowerShell als Administrator starten

Damit das Skript die benötigten Änderungen durchführen kann, muss es mit Administratorrechten laufen.

1. Klicke auf den **Start-Button**.
2. Tippe **"PowerShell"** in die Suche.
3. Klicke mit der rechten Maustaste auf **"Windows PowerShell"** (oder **"Windows Terminal"**).
4. Wähle **"Als Administrator ausführen"**.
5. Bestätige die Sicherheitsabfrage (UAC) mit **"Ja"**.

Im Fenstertitel sollte jetzt etwas wie **"Administrator: Windows PowerShell"** stehen.

***

## 3. Ausführen von Skripten erlauben (einmalig)

Standardmäßig blockiert Windows die Ausführung eigener PowerShell-Skripte. Du kannst die Richtlinie für dein Benutzerkonto auf eine sichere Einstellung ändern.

1. Gib im (administrativen) PowerShell-Fenster folgenden Befehl ein und bestätige mit Enter:

   ```powershell
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. Wenn eine Sicherheitsabfrage erscheint, gib **`J`** ein und bestätige mit Enter.

Mit **RemoteSigned** dürfen lokal erstellte Skripte ausgeführt werden, Skripte aus dem Internet müssen signiert sein.

Hinweis: Diese Einstellung gilt nur für dein Benutzerkonto und kann bei Bedarf später wieder geändert werden.

***

## 4. In den Skript-Ordner wechseln

Wechsle nun in den Ordner, in dem du das Skript gespeichert hast. Beispiel `C:\Tools`:

```powershell
Set-Location C:\Tools
```

Du erkennst am Prompt (Eingabezeile), dass du jetzt in `C:\Tools>` bist.

***

## 5. Skript ausführen

Starte das Skript mit folgendem Befehl:

```powershell
.\Check-SecureBootUEFI.ps1
```

Das Skript führt nun mehrere Prüfungen aus, z. B.:

- ob Secure Boot auf deinem Gerät aktiv ist,
- ob die neuen Zertifikate ("Windows UEFI CA 2023") bereits in der Secure-Boot-Datenbank vorhanden sind,
- welchen Status der Registry-Wert `UEFICA2023Status` hat.

Die Ergebnisse werden dir im Fenster angezeigt.

***

## 6. Rückfragen des Skripts beantworten

Wenn das Skript feststellt, dass dein System die neuen Zertifikate noch nicht vollständig nutzt, stellt es dir eine Frage wie:

```text
Möchten Sie fortfahren? (J/N)
```

- Gib **`J`** ein und drücke Enter, wenn du möchtest, dass das Skript die empfohlenen Änderungen vornimmt.
- Gib **`N`** ein und drücke Enter, wenn du keine Änderungen durchführen möchtest.

Wenn du **`J`** wählst, versucht das Skript unter anderem:

- Windows Update anzustoßen (soweit möglich),
- die von Microsoft vorgesehenen Registry-Werte für das Zertifikatsupdate zu setzen,
- eine interne Windows-Aufgabe zu starten, die das Update vorbereitet.

Alle Schritte werden kurz im Fenster beschrieben.

***

## 7. Neustart durchführen

Damit die Änderungen an den Secure-Boot-Zertifikaten vollständig wirksam werden, ist ein **Neustart** des PCs notwendig.

Am Ende fragt dich das Skript zum Beispiel:

```text
Computer jetzt neu starten? (J/N)
```

- Gib **`J`** ein und drücke Enter, wenn der Rechner sofort neu starten darf.
- Gib **`N`** ein, wenn du später manuell neu starten möchtest (z. B. über Start → Ein/Aus → Neu starten).

Ohne Neustart werden die neuen Zertifikate in der Regel nicht vollständig aktiv.

***

## 8. Skript später erneut verwenden

Du kannst das Skript jederzeit wieder starten, um den Status zu prüfen:

1. PowerShell erneut **als Administrator** öffnen.
2. In den Skript-Ordner wechseln, z. B.:

   ```powershell
   Set-Location C:\Tools
   ```

3. Skript ausführen:

   ```powershell
   .\Check-SecureBootUEFI.ps1
   ```

Wenn alles erfolgreich war, zeigt dir das Skript an, dass die neuen Zertifikate bereits vorhanden sind und keine weiteren Maßnahmen nötig sind.

***

## 9. Fehler und typische Meldungen

- **Hinweis zu Administratorrechten**  
  Wenn das Skript meldet, dass Administratorrechte benötigt werden, starte PowerShell erneut mit Rechtsklick → **"Als Administrator ausführen"**.

- **Skriptausführung ist deaktiviert**  
  Falls eine Meldung erscheint, dass die Ausführung von Skripten deaktiviert ist, wiederhole Schritt 3 (`Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`).

- **Secure Boot nicht verfügbar oder nicht aktiviert**  
  Wenn das Skript ausgibt, dass Secure Boot nicht unterstützt oder nicht aktiviert ist, liegt das meist an älterer BIOS-Hardware oder an einer deaktivierten Secure-Boot-Option im UEFI-Setup deines PCs. In diesem Fall beendet sich das Skript ohne Änderungen.

***

## 10. Sicherheitshinweise

- Führe das Skript nur aus, wenn du den Code aus einer vertrauenswürdigen Quelle erhalten hast (z. B. eigene IT-Dokumentation, bekannte Admins).
- Das Skript nimmt Änderungen an sicherheitsrelevanten Einstellungen (Secure Boot / Zertifikate) vor, allerdings im Rahmen der offiziellen Microsoft-Empfehlungen.
- Wenn du unsicher bist, teste das Skript zuerst auf einem weniger kritischen Gerät.

***

## 11. Support

Leider nicht vorhanden :-(
