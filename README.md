# Fedora 44 Workstation Setup v5

Bootstrap idempotente per una workstation Fedora 44 GNOME destinata allo sviluppo.
Lo script deve essere avviato come utente normale: richiede `sudo` solo per le operazioni di sistema.

## Contenuto

- cartelle XDG standard in inglese (`Downloads`, `Documents`, `Pictures`, ecc.);
- directory personali `~/Tools` e `~/Progetti`;
- Zsh e Oh My Zsh;
- strumenti di base, compilazione e diagnostica, incluso il browser Gitk;
- supporto per montare condivisioni SMB/CIFS tramite `cifs-utils`;
- supporto OpenVPN e OpenConnect/Cisco-compatible;
- SDKMAN con Java, Maven e Gradle;
- NVM con Node LTS;
- Miniconda senza attivazione automatica di `base`;
- VS Code tramite repository RPM Microsoft;
- JetBrains Toolbox in `~/Tools`;
- DBeaver e Bruno via RPM;
- Discord e Obsidian via Flatpak/Flathub;
- Thunderbird e LibreOffice dai repository Fedora;
- Dash to Dock e pulsanti minimizza/massimizza per GNOME;
- Docker Engine CE, Buildx e Docker Compose V2;
- Docker Engine in modalità Rootless vera, senza daemon root e senza gruppo `docker`;
- Docker Desktop per Linux (installato, non avviato automaticamente);
- KVM/QEMU + libvirt + virt-manager per VM Windows/Linux;
- Vagrant + provider libvirt per VM dichiarative e riproducibili;
- configurazione Git multi-account e multi-server;
- gestione energetica per laptop Intel tramite TuneD e `intel_pstate`.

Non installa Ansible, OpenTofu, Kubernetes o Helm. Installa KVM/QEMU + libvirt/virt-manager per le VM locali.

## Uso

```bash
cp config/local.env.example config/local.env
# modifica config/local.env se necessario
./install.sh --development
```

Profilo minimo:

```bash
./install.sh --base
```

## Wallpaper

Inserisci uno o più file JPG, PNG o WebP nella cartella `wallpapers/`, quindi
scegli quello da applicare a GNOME con:

```bash
./install.sh --set-wallpaper
```

Il comando mostra un elenco numerato e configura l'immagine scelta sia per il
tema chiaro sia per quello scuro.

## Applicazioni desktop

Le applicazioni desktop sono facoltative e non vengono installate dal profilo `--development`. La sezione comprende Thunderbird e LibreOffice dai repository Fedora, Discord e Obsidian per il solo utente da Flathub, Dash to Dock e i pulsanti minimizza/massimizza nelle barre del titolo. Dash to Dock e i pulsanti vengono configurati solo quando è rilevata GNOME Shell; sugli altri desktop il passaggio viene saltato. Il setup è idempotente e configura automaticamente il remote `flathub`.

Le applicazioni sono abilitate per impostazione predefinita e possono essere escluse in `config/local.env`:

```bash
INSTALL_DISCORD=false
INSTALL_OBSIDIAN=false
INSTALL_THUNDERBIRD=false
INSTALL_LIBREOFFICE=false
INSTALL_DASH_TO_DOCK=false
ENABLE_WINDOW_BUTTONS=false
```

Per installare soltanto la sezione desktop:

```bash
./install.sh --desktop
```

Questa modalità esegue esclusivamente `modules/70-desktop-apps.sh` e non modifica la shell o la configurazione Git. Dopo la prima installazione di Dash to Dock potrebbe essere necessario un logout/login affinché GNOME carichi l’estensione; rilanciando `--desktop` verrà abilitata. Al termine lo script indica il comando di verifica.

Per installare sia l'ambiente di sviluppo sia la sezione desktop:

```bash
./install.sh --all
```

Gli argomenti storici `base` e `development` restano accettati per compatibilità. `--develop` è un alias di `--development`.

Per verificarne poi l’installazione:

```bash
flatpak info --user com.discordapp.Discord
flatpak info --user md.obsidian.Obsidian
rpm -q thunderbird libreoffice-core
./bin/doctor.sh
```

## Aggiornamento del sistema e delle app

Il modulo della shell configura l’alias:

```bash
update-a
```

che esegue in sequenza `sudo dnf upgrade --refresh -y` e `flatpak update -y`. L’aggiornamento Flatpak parte solo se quello Fedora termina correttamente.

Controllo sintattico senza installare nulla:

```bash
./bin/check-setup.sh
```

Verifica della workstation:

```bash
./bin/doctor.sh
```

## Condivisioni SMB/CIFS

Il pacchetto `cifs-utils` viene installato in entrambi i profili e fornisce
`mount.cifs`, necessario per montare condivisioni SMB da terminale o tramite
`/etc/fstab`.

Verifica dell'installazione:

```bash
rpm -q cifs-utils
command -v mount.cifs
./bin/doctor.sh
```

Esempio di test con una condivisione SMB (sostituisci server, condivisione e
utente):

```bash
sudo mkdir -p /mnt/smb-test
sudo mount -t cifs //server/condivisione /mnt/smb-test \
  -o username=utente,vers=3.0
mountpoint /mnt/smb-test
sudo umount /mnt/smb-test
```

La password viene richiesta interattivamente da `mount.cifs`, evitando di
inserirla nella cronologia della shell.

## Cartelle standard in inglese

Con il valore predefinito:

```bash
USE_ENGLISH_XDG_DIRS=true
```

il setup configura:

- `Scaricati` → `Downloads`;
- `Documenti` → `Documents`;
- `Immagini` → `Pictures`;
- `Musica` → `Music`;
- `Video` → `Videos`;
- `Scrivania` → `Desktop`;
- `Modelli` → `Templates`;
- `Pubblici` → `Public`.

Se sia la cartella italiana sia quella inglese contengono file, il modulo non le unisce automaticamente e mostra un avviso per evitare sovrascritture.

## Gestione energetica

Il modulo `90-power-mode.sh`:

1. installa e abilita TuneD/tuned-ppd;
2. conserva una copia sorgente in `~/Tools/laptop-power-mode/laptop-power-mode.sh`;
3. installa l’eseguibile root-owned `/usr/local/bin/laptop-power-mode`;
4. collega `~/.local/bin/laptop-power-mode` alla copia di sistema, sostituendo eventuali vecchi link;
5. crea `/etc/laptop-power-mode.conf`;
6. crea e abilita `laptop-power-mode.service`;
7. applica al boot la modalità configurata.

Configurazione predefinita:

```bash
POWER_MODE_AUTOSTART=true
POWER_MODE_DEFAULT="dev"
POWER_MODE_DEV_MAX=60
POWER_MODE_QUIET_MAX=45
POWER_MODE_MIN_PERF=10
```

Comandi disponibili:

```bash
laptop-power-mode status
laptop-power-mode dev       # usa POWER_MODE_DEV_MAX
laptop-power-mode dev 70
laptop-power-mode quiet     # usa POWER_MODE_QUIET_MAX
laptop-power-mode normal    # balanced, 100%, turbo attivo
laptop-power-mode full      # performance, 100%, turbo attivo
laptop-power-mode default   # riapplica il valore configurato
```

Per i test termici usa:

```bash
laptop-power-mode normal
```

Per lo sviluppo quotidiano:

```bash
laptop-power-mode dev
```

Il servizio usa `/usr/local/bin/laptop-power-mode`, non il file nella home, così evita problemi di esecuzione dei servizi di sistema e di contesto SELinux.

Dopo una modifica manuale della copia in `~/Tools`, sincronizzala e riapplica il profilo con:

```bash
sudo install -m 0755 \
  ~/Tools/laptop-power-mode/laptop-power-mode.sh \
  /usr/local/bin/laptop-power-mode
sudo restorecon -F /usr/local/bin/laptop-power-mode
sudo systemctl restart laptop-power-mode.service
```

Verifica del servizio:

```bash
systemctl status laptop-power-mode.service
journalctl -u laptop-power-mode.service -b --no-pager
```

Per disattivare l’applicazione automatica al boot imposta in `config/local.env`:

```bash
POWER_MODE_AUTOSTART=false
```

poi riesegui il setup.

## Più identità Git

Esegui una volta per ogni combinazione account/server/directory:

```bash
./bin/add-git-identity.sh
```

Esempi di profili indipendenti:

- `personal-github` per `~/Progetti/personali/github/`;
- `azienda-github` per `~/Progetti/lavoro/azienda/github/`;
- `cliente-gitlab` per `~/Progetti/lavoro/cliente/gitlab/`;
- `gitea-interno` per `~/Progetti/lavoro/azienda/gitea/`.

L’identità Git viene scelta dalla directory del repository; la chiave SSH viene scelta dall’alias usato nel remote.

## Docker

La v5 usa Docker Rootless come runtime container predefinito. La configurazione standard è:

```bash
INSTALL_PODMAN=false
INSTALL_DOCKER=true
INSTALL_DOCKER_DESKTOP=true
DOCKER_ROOTLESS=true
DOCKER_ROOTLESS_AUTOSTART=true
```

Il modulo `55-docker.sh` configura il repository RPM ufficiale Docker e installa:

- `docker-ce`;
- `docker-ce-cli`;
- `containerd.io`;
- `docker-ce-rootless-extras`;
- `docker-buildx-plugin`;
- `docker-compose-plugin`.

Con `DOCKER_ROOTLESS=true` il daemon Docker e i container vengono eseguiti nello user namespace dell’utente. `docker ps`, `docker build` e `docker compose` funzionano senza `sudo`, mentre il daemon di sistema resta disabilitato.

Docker Desktop viene installato dal pacchetto RPM ufficiale in `/opt/docker-desktop`. Su GNOME viene installata anche l'estensione AppIndicator e l'utente viene aggiunto al gruppo `kvm` quando disponibile. Il primo avvio di Docker Desktop va fatto dall'applicazione grafica per accettare i termini.

Docker Desktop e Docker Engine possono coesistere, ma usano storage e daemon separati. Per evitare consumo di risorse e conflitti sulle porte, la v5 lascia Docker Rootless come runtime predefinito e non abilita Docker Desktop all'accesso. È disponibile il comando:

```bash
docker-runtime status
docker-runtime rootless
docker-runtime desktop
```

`docker-runtime desktop` ferma il daemon rootless prima di avviare Desktop; `docker-runtime rootless` ferma Desktop e torna al context `rootless`.

Podman resta opzionale e non viene più installato di default:

```bash
INSTALL_PODMAN=true
```

## Aggiornamento di sistema

Per evitare che ogni esecuzione del setup avvii anche un aggiornamento completo:

```bash
RUN_SYSTEM_UPGRADE=false
```

Il valore predefinito resta `true`.

## Sicurezza e riproducibilità

Il repository non conserva password, token, chiavi private, profili VPN o certificati aziendali.

Alcuni strumenti vengono ancora scaricati dai relativi endpoint “latest” ufficiali. Questo rende il setup comodo ma non completamente riproducibile. Per una pipeline strettamente riproducibile restano da aggiungere version pinning e checksum per Oh My Zsh, SDKMAN, NVM, Miniconda, DBeaver, Bruno e JetBrains Toolbox.


## Endpoint esterni centralizzati (v5)

Gli URL usati dagli installer sono raccolti in:

```text
config/sources.env
```

Qui puoi cambiare in un solo punto gli endpoint di Oh My Zsh, SDKMAN, NVM, Miniconda, Docker, Docker Desktop, VS Code, DBeaver, Bruno e JetBrains Toolbox. `config/local.env` viene caricato dopo `sources.env`, quindi può sovrascrivere anche un singolo URL.

## Docker Rootless (v5)

Configurazione predefinita:

```bash
INSTALL_DOCKER=true
DOCKER_ROOTLESS=true
DOCKER_ROOTLESS_AUTOSTART=true
INSTALL_DOCKER_DESKTOP=true
```

Il modulo installa `docker-ce-rootless-extras`, verifica `newuidmap/newgidmap` e almeno 65.536 subordinate UID/GID, disabilita il daemon Docker di sistema e crea il servizio systemd utente `docker.service`. Con autostart attivo abilita anche il linger dell’utente.

Runtime disponibili:

```bash
docker-runtime status
docker-runtime rootless
docker-runtime desktop
```

Non viene più usato il gruppo `docker`. Se viene rilevata una precedente appartenenza dovuta alla v4, il setup la rimuove; serve logout/login per aggiornare i gruppi della sessione corrente.

## Virtualizzazione KVM/QEMU (v5)

Il profilo `development` installa:

- KVM/QEMU;
- libvirt e rete NAT predefinita;
- `virt-manager` per la GUI;
- `virsh`, `virt-install` e `virt-viewer` per CLI e automazione;
- Vagrant + `vagrant-libvirt` per ambienti VM riproducibili da `Vagrantfile`;
- OVMF/UEFI;
- `swtpm` per TPM virtuale, utile per guest Windows moderni.

Avvio:

```bash
virt-manager
```

Controlli:

```bash
ls -l /dev/kvm
virsh -c qemu:///system list --all
```

Dopo la prima installazione può essere necessario logout/login per applicare i gruppi `kvm` e `libvirt`. Per workflow DevOps puoi poi usare `vagrant up --provider=libvirt`.
