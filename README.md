# Node.js Group Project Server (IaC)

> **Modul:** Cloud Computing & Web Engineering  
> **Status:** Production Ready (v1.1.0)  
> **Technologie:** Terraform, Cloud-Init, OpenStack

## Projektbeschreibung

Dieses Repository stellt eine **Infrastructure-as-Code (IaC)** Definition bereit, um eine vollautomatisierte, kollaborative Entwicklungsumgebung für Studierenden-Gruppen zu deployen.

Das Ziel ist die Bereitstellung eines **"Zero-Configuration" Servers**, der spezifisch auf die Anforderungen der Lehrveranstaltung zugeschnitten ist (User Story ID 101):
1.  **Sofort einsatzbereit:** Node.js, NVM, Git und PM2 sind vorinstalliert.
2.  **Kollaborativ:** Ein Shared-Workspace-Konzept erlaubt das gemeinsame Bearbeiten von Dateien ohne Berechtigungskonflikte.
3.  **Ressourcen-Kontrolle:** CPU/RAM-Quotas werden über OpenStack Flavors strikt durchgesetzt.

---

## Architektur & Design

Die Infrastruktur basiert auf einer einzelnen Ubuntu 22.04 Instanz, die durch Security Groups abgeschirmt ist. Die Besonderheit liegt in der **internen Berechtigungsstruktur**.

```mermaid
graph TD
    Internet((Internet)) -->|TCP 22| SSH[SSH-Daemon]
    Internet -->|TCP 3000| App[Node.js-App]
    Internet -->|TCP 8080| Alt[Alt-Port]
    
    subgraph VM["Ubuntu VM (Quota Managed)"]
        SSH --> Admin[Dozent-Sudo]
        SSH --> S1[Student1]
        SSH --> S2[Student2]
        
        Admin -.->|Link| Shared[/opt/project]
        S1 -.->|Link| Shared
        S2 -.->|Link| Shared
        
        subgraph WS["Shared Workspace (SGID)"]
            Shared --> Code[Source-Code]
            Code --> Git[Git-Repo]
        end
    end
```

### Technische Highlights

**SetGID Bit (chmod 2775):** Der zentrale Projektordner `/opt/project` nutzt das SetGID-Bit. Dadurch erben alle neu erstellten Dateien automatisch die Gruppe `webdevs` statt der primären Gruppe des Erstellers. Dies verhindert effektiv "Permission Denied"-Fehler bei der Gruppenarbeit.

**Welcome-App:** Ein via cloud-init injiziertes Node.js-Skript startet beim Booten automatisch auf Port 3000. Dies dient als "Alive-Check" für die Studierenden.

**Passwort-Auth:** Aus Usability-Gründen wurde PasswordAuthentication aktiviert, um die Hürde des SSH-Key-Austauschs in studentischen Gruppen zu eliminieren.

## Deployment (Für Dozenten)

### Voraussetzungen
- Terraform >= 1.6.0
- Zugriff auf OpenStack (via clouds.yaml oder Environment Variables)

### Installation

**Initialisierung:**
```bash
cd terraform
terraform init
```

**Konfiguration:**
Passen Sie die Variablen in `terraform.tfvars` an (oder übergeben Sie sie via CLI):
```terraform
project_name   = "web-engineering-group-a"
admin_email    = "dozent@dhbw.de"
student_emails = ["s1@dhbw.de", "s2@dhbw.de", "s3@dhbw.de"]
flavor_name    = "gp1.medium"  # Steuert die Quotas (2 vCPU, 4GB RAM)
```

**Deployment:**
```bash
terraform apply
```

**Übergabe:**
Nach erfolgreichem Durchlauf gibt Terraform die Zugangsdaten aus. Diese müssen sicher an die Studierenden übermittelt werden:
```bash
terraform output student_credentials
terraform output admin_credentials
```

## Nutzungshandbuch (Für Studierende)

Ihr Team hat Zugriff auf einen gemeinsamen Linux-Server. Gehen Sie wie folgt vor:

### 1. Verbinden
Nutzen Sie die erhaltenen Zugangsdaten:
```bash
ssh username@<SERVER-IP>
# Passwort eingeben
```

### 2. Arbeitsumgebung vorbereiten
Wenn Sie sich einloggen, läuft bereits eine Demo-App ("Welcome App").
- Prüfen Sie im Browser: `http://<SERVER-IP>:3000`
- Stoppen Sie die Demo, um den Port freizumachen:
```bash
pm2 stop welcome
```

### 3. Entwickeln
Arbeiten Sie ausschließlich im Ordner `project` in Ihrem Home-Verzeichnis. Dieser ist magisch mit Ihren Teamkollegen verknüpft.
```bash
cd ~/project
# Hier git clone, npm install, etc. durchführen
```

### 4. App starten
Nutzen Sie pm2, damit Ihre App auch weiterläuft, wenn Sie die Konsole schließen:
```bash
# Beispiel
pm2 start index.js --name mein-projekt
```

## Technische Details

### Installierte Software
| Tool | Version | Zweck |
|------|---------|-------|
| Node.js | v20 (LTS) oder v18 | Laufzeitumgebung |
| NVM | Latest | Node Version Manager (Versionswechsel) |
| PM2 | Latest | Process Manager (Keep-Alive, Logs) |
| Git | Latest | Versionierung |
| UFW | - | Uncomplicated Firewall |

### Dateistruktur im Repo
```
NodeJS-Group-Project/
├── template.yaml           # CloudStore Template Definition
├── README.md               # Diese Datei
└── terraform/
    ├── main.tf             # Hauptlogik (Server, Network, Security)
    ├── variables.tf        # Variablendefinitionen
    ├── outputs.tf          # Rückgabewerte (Credentials)
    └── cloud-init.yaml     # Server-Konfiguration & User-Skripte
```

## Wartung & Sicherheit

**Persistenz:** Dies ist eine ephemere Entwicklungsumgebung. Code sollte regelmäßig in ein externes Git-Repository gepusht werden. Bei einem `terraform destroy` sind alle Daten auf der VM verloren.

**Updates:** Systemupdates (`apt upgrade`) werden automatisch beim ersten Start durchgeführt.

**Ports:** Nur Ports 22 (SSH), 3000 (App) und 8080 (Alt) sind von außen erreichbar.

---

**Autor:** DHBW Cloud Engineering Team  
**Lizenz:** MIT