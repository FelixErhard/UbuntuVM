# Node.js Development Server Template

Multi-User Node.js Development Environment für Gruppenarbeit und Web Engineering Kurse an der DHBW.

## Überblick

Dieses Template erstellt einen vollständig konfigurierten Node.js Development Server mit:

- ✅ **Multi-User Support**: Separate Accounts für jeden Studierenden
- ✅ **Node.js v20 LTS**: Aktuelle LTS-Version mit NPM
- ✅ **Development Tools**: PM2, Nodemon, TypeScript, NVM vorinstalliert
- ✅ **Shared Workspace**: Kollaboratives Arbeiten ohne Berechtigungskonflikte
- ✅ **Process Management**: PM2 für persistente App-Ausführung
- ✅ **Automatische User-Erstellung**: Alle Studierenden werden beim Deployment angelegt
- ✅ **Resource Management**: CPU/RAM-Quotas über OpenStack Flavors
- ✅ **Secure Password Generation**: Zufällige, starke Passwörter für jeden User

## Architektur

```
┌─────────────────────────────────────────────┐
│          Internet (HTTP:3000, 8080)         │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│         Node.js Development VM              │
│   ┌─────────────────────────────────────┐   │
│   │  student1_test_de                   │   │
│   │  → /home/student1_test_de/project   │   │
│   │  → Node.js + NPM + PM2 + NVM       │   │
│   └─────────────────────────────────────┘   │
│                                             │
│   ┌─────────────────────────────────────┐   │
│   │  student2_test_de                   │   │
│   │  → Individual project directory     │   │
│   │  → Git repo auto-cloned (optional)  │   │
│   └─────────────────────────────────────┘   │
│                                             │
│   ┌─────────────────────────────────────┐   │
│   │  Ubuntu User (SSH Access)          │   │
│   │  → Server administration           │   │
│   │  → PM2 process monitoring          │   │
│   └─────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

## Parameter

### Pflichtparameter

| Parameter | Typ | Beschreibung |
|-----------|-----|--------------|
| `project_name` | `string` | Projektname (definiert Hostname und Ordnername) |
| `student_emails` | `array` | Liste der Studierenden-E-Mails |
| `admin_email` | `string` | Email-Adresse des Admins |
### Optional

| Parameter | Typ | Standard | Beschreibung |
|-----------|-----|----------|--------------|
| `node_version` | `selection` | `"20"` | Node.js Version ("20" LTS oder "18") |
| `git_repo_url` | `string` | `""` | Git-Repository URL zum auto-clonen |
| `flavor_name` | `selection` | `"gp1.medium"` | VM-Größe (Small/Medium/Large) |

### Infrastruktur (in `terraform.tfvars`)

| Parameter | Typ | Standard | Beschreibung |
|-----------|-----|----------|--------------|
| `image_name` | `string` | `"Ubuntu 22.04"` | OS Image Name |
| `network_name` | `string` | `"NAT"` | Internes Netzwerk |
| `external_network_name` | `string` | `"DHBW"` | Externes Netzwerk für Floating IP |
| `floating_ip_pool` | `string` | `"DHBW"` | Pool für öffentliche IPs |

## Deployment-Beispiel

### Über CloudStore API

```json
{
  "template_id": 4,
  "user_id": 1,
  "parameters": {
    "project_name": "web-engineering-group-a",
    "student_emails": [
      "student1@dhbw.de",
      "student2@dhbw.de",
      "student3@dhbw.de"
    ],
    "node_version": "20",
    "flavor_name": "gp1.medium",
    "git_repo_url": "https://github.com/username/project.git"
  }
}
```

### Manuelles Deployment

```bash
cd terraform
terraform init

# terraform.tfvars anpassen
nano terraform.tfvars

# Deployment starten
terraform apply
```

## Outputs

### Public Outputs

| Output | Beschreibung | Beispiel |
|--------|--------------|----------|
| `ssh_command` | SSH-Verbindungskommando | `ssh ubuntu@141.72.XXX.XXX` |
| `app_url` | Node.js App URL (Port 3000) | `http://141.72.XXX.XXX:3000` |
| `server_info` | VM-Details | `{"deployment_id": "...", "student_count": 3}` |
| `installed_tools` | Entwicklungstools | `["Node.js 20", "NPM", "PM2", ...]` |
| `access_instructions` | Zugangsanleitung | Multi-line Text |

### Sensitive Outputs (via `/deployments/{id}/keys`)

| Output | Beschreibung |
|--------|--------------|
| `student_credentials` | Map: `email -> {"username": "student1_test_de", "password": "...", "ssh_command": "...", "project_directory": "..."}` |
| `ssh_private_key` | SSH Private Key (RSA 4096-bit) |
| `floating_ip` | Öffentliche IP-Adresse |
| `internal_ip` | Interne IP-Adresse |

## Benutzernamen-Konvention

**Wichtig**: Email-Adressen werden automatisch in gültige Unix-Usernamen umgewandelt:

- `@` wird zu `_`
- `.` wird zu `_`
- Alles in Kleinbuchstaben

**Beispiele**:

| Email | Username |
|-------|----------|
| `student1@test.de` | `student1_test_de` |
| `Max.Mustermann@dhbw.de` | `max_mustermann_dhbw_de` |
| `developer@mail.dhbw-mannheim.de` | `developer_mail_dhbw-mannheim_de` |

## Zugriff

### Studierende

1. **SSH-Verbindung**: `ssh username@<floating-ip>` (aus `student_credentials`)
2. **Passwort**: Aus `student_credentials[email].password`
3. **Projektverzeichnis**: `/home/<username>/<project_name>/`
4. **App starten**:
   ```bash
   cd ~/my-nodejs-project
   node app.js &
   # oder mit PM2:
   pm2 start app.js --name myapp
   ```
5. **Browser**: `http://<floating-ip>:3000`

### Administrator (SSH-Key)

1. **SSH mit Private Key**:
   ```bash
   ssh -i private_key.pem ubuntu@<floating-ip>
   ```
2. **Benutzer-Übersicht**:
   ```bash
   ls -la /home/
   ```
3. **PM2 Prozesse verwalten**:
   ```bash
   pm2 status
   pm2 logs
   ```

## Resource Allocation

Ressourcen werden **pro Flavor** zugewiesen:

| Flavor | vCPU | RAM | Beschreibung |
|--------|------|-----|--------------|
| `gp1.small` | 1 | 2GB | Für kleine Teams (1-2 Studierende) |
| `gp1.medium` | 2 | 4GB | Standard für 3-4 Studierende |
| `gp1.large` | 4 | 8GB | Für größere Teams oder ressourcenintensive Apps |

**Wichtig**: Die Ressourcen werden von **allen Studierenden geteilt**!

## Technische Details

### Cloud-Init Prozess

1. **System-Setup**: Ubuntu 22.04, Updates, Grundpakete
2. **Node.js Installation**: Spezifizierte Version via NodeSource
3. **NVM Installation**: Global für alle Benutzer
4. **NPM Global Packages**: PM2, Nodemon, TypeScript
5. **User-Erstellung**: Automatisch für alle Studierenden
6. **Projektverzeichnisse**: `/home/<username>/<project_name>/`
7. **Git-Clone**: Optional, falls `git_repo_url` angegeben
8. **Firewall-Setup**: UFW für Ports 22, 3000, 8080

### Installierte Software

| Tool | Version | Zweck |
|------|---------|-------|
| Node.js | v20/v18 | JavaScript Runtime |
| NPM | Latest | Package Manager |
| NVM | Latest | Node Version Manager |
| PM2 | Latest | Process Manager |
| Nodemon | Latest | Development Tool |
| TypeScript | Latest | Type-Safe JavaScript |
| Git | Latest | Versionskontrolle |

## Mock-Modus Testing

```bash
cd terraform
terraform init
terraform apply \
  -var="use_mock_provider=true" \
  -var="deployment_id=test-123" \
  -var="project_name=test-project" \
  -var='student_emails=["test1@example.com","test2@example.com"]'
```

**Erstellt**:
- ✅ Echte Passwörter für alle User
- ✅ SSH-Keys
- ✅ Outputs wie in Production
- ❌ Keine echte VM


## Troubleshooting

### Node.js App startet nicht

```bash
ssh ubuntu@<floating-ip>
pm2 status
pm2 logs
```

### Port 3000 ist nicht erreichbar

```bash
# UFW Status prüfen
sudo ufw status

# Port-Binding prüfen
ss -tulnp | grep :3000
```

### Student kann sich nicht einloggen

```bash
# Benutzer existiert?
sudo cat /etc/passwd | grep student1_test_de

# Passwort zurücksetzen
sudo passwd student1_test_de
```

### Git-Clone fehlgeschlagen

```bash
# Projektverzeichnis prüfen
ls -la /home/student1_test_de/my-nodejs-project/
# Manuell clonen
sudo -u student1_test_de git clone <repo-url> /home/student1_test_de/my-nodejs-project/repo
```

## Lizenz

MIT License - DHBW CloudStore Project