# Fedora 44 Workstation Setup v5

Bootstrap idempotente per una workstation Fedora 44 GNOME destinata allo sviluppo.
Lo script deve essere avviato come utente normale: richiede `sudo` solo per le operazioni di sistema.

## Contenuto

- cartelle XDG standard in inglese (`Downloads`, `Documents`, `Pictures`, ecc.);
- directory personali `~/Tools` e `~/Progetti`;
- Zsh e Oh My Zsh;
- ambiente terminale Kitty + tmux, con tema Zsh/Starship opzionale coordinato;
- strumenti di base, compilazione e diagnostica, incluso il browser Gitk;
- supporto per montare condivisioni SMB/CIFS tramite `cifs-utils`;
- supporto OpenVPN e OpenConnect/Cisco-compatible;
- SDKMAN con Java, Maven e Gradle;
- NVM con Node LTS;
- Miniconda senza attivazione automatica di `base`;
- LaTeX/TeX Live tramite i pacchetti ufficiali Fedora;
- Codex, Claude Code e GitHub Copilot CLI con home sotto `~/Tools/Agents`;
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

## Tema Zsh/Starship opzionale

La configurazione avanzata della shell non è abilitata implicitamente, così il setup
non cambia il prompt o le preferenze Zsh di chi non la richiede. Si può aggiungere a
qualunque profilo, oppure usare da sola con il profilo development predefinito:

```bash
./install.sh --development --config-zsh-theme
# oppure
./install.sh --config-zsh-theme
```

Installa `zsh` dai repository Fedora, Starship dal suo archivio ufficiale e i due
plugin nei custom plugin di Oh My Zsh; riutilizza Oh My Zsh se presente e non modifica né duplica la
lista `plugins=(...)`. Starship mostra in modo contestuale directory, Git e operazioni
in corso, Docker, Kubernetes/namespace, Java, Maven, Node, Python, Conda, Vagrant,
durata dei comandi lenti, errori e job. Hostname e IPv4 compaiono soltanto via SSH.

URL, versione Starship, checksum SHA-256 e commit completi dei plugin sono centralizzati
in `config/sources.env`. Anche l'installer Oh My Zsh è fissato a un commit e verificato
prima dell'esecuzione. I file gestiti sono `~/.config/starship.toml` e
`~/.config/workstation-setup/zsh-theme.zsh`; `.zshrc` riceve un solo blocco marcato.
Al primo intervento viene conservato `~/.zshrc.workstation-setup.bak`. Per modificare
il tema si possono personalizzare i due file (una nuova esecuzione del flag ripristina
i template del repository). Per disabilitarlo basta rimuovere da `.zshrc` il blocco
compreso tra `workstation-setup zsh theme`; per il rollback completo, ripristinare il
backup e rimuovere i due file gestiti. I pacchetti e Oh My Zsh non vengono rimossi,
perché potrebbero essere usati da altre configurazioni personali. Se non servono ad
altro, si possono inoltre eliminare i due plugin da
`~/.oh-my-zsh/custom/plugins/` e `~/.local/bin/starship`.

## Terminale: Kitty + tmux

Kitty è il contenitore grafico: cura rendering GPU, font monospace Fedora, colori,
scrollback, URL e clipboard. tmux è invece il workspace manager persistente per
sessioni, window e pane. Entrambi vengono installati e configurati automaticamente
dal profilo development e da `--all`; non fanno parte di `--base` o `--desktop`:

```bash
./install.sh --development
# oppure: --all
```

Il tema Zsh/Starship, inclusi syntax highlighting e autosuggestions, resta una
scelta separata tramite `--config-zsh-theme`; Kitty e tmux non ne duplicano la
configurazione.

Nessun flag avvia tmux automaticamente e nessuna sessione viene creata al login.
Le configurazioni sono `~/.config/kitty/kitty.conf` e `~/.tmux.conf`. Se esiste un
file personale non gestito, la prima esecuzione lo conserva accanto all'originale
con suffisso `.workstation-setup.bak`; il backup non viene moltiplicato. Kitty si
ricarica aprendo una nuova finestra (oppure con `kitty @ load-config` se il remote
control è stato abilitato personalmente). tmux si ricarica con `Ctrl+b r`.

Kitty mantiene queste scorciatoie per la clipboard:

| Scorciatoia | Operazione |
|---|---|
| `Ctrl+Shift+A` | Copy entire terminal scrollback |
| `Ctrl+Shift+C` | Copy selection |
| `Ctrl+Shift+V` | Paste |

`Ctrl+Shift+A` copia come testo semplice lo schermo e tutto lo scrollback
disponibile nel buffer della finestra Kitty corrente. `Ctrl+A` resta volutamente
libero e raggiunge shell/readline/Zsh con il significato standard di inizio riga.
Kitty mantiene anche `Ctrl+Shift+U` per gli URL hints e non definisce split o tab
custom. Usa `xterm-kitty`, mentre tmux espone
`tmux-256color` alle applicazioni e dichiara RGB/clipboard tramite
`terminal-features`. `set-clipboard on` usa le sequenze terminale/OSC 52 e funziona
su Wayland senza dipendere da helper X11; la copia resta semplicemente interna a
tmux se il terminale esterno non offre la clipboard.

La scorciatoia è gestita da Kitty anche quando la finestra contiene tmux e non
interferisce con il prefix `Ctrl+b`. Lo scrollback di Kitty non equivale però alla
history interna di tmux: contenuto conservato soltanto da tmux (per esempio per
l'uso dell'alternate screen) non può essere recuperato dal buffer esterno di Kitty.

tmux mantiene il prefix standard `Ctrl+b`. In breve: il server tmux ospita una o
più sessioni; ogni sessione contiene window, e ogni window contiene pane.

| Operazione | Comando / tasto |
|---|---|
| crea o collega `dev` | `tmux new -As dev` |
| elenca / collega sessioni | `tmux ls` / `tmux attach -t nome` |
| detach | `Ctrl+b d` |
| nuova window / precedente / successiva | `Ctrl+b c` / `Ctrl+b p` / `Ctrl+b n` |
| scegli sessione | `Ctrl+b s` |
| split destra / sotto | `Ctrl+b \|` / `Ctrl+b -` |
| naviga pane | `Ctrl+b h/j/k/l` |
| ridimensiona di 5 celle | `Ctrl+b H/J/K/L` |
| chiudi pane | `exit` oppure `Ctrl+b x` |
| copy mode / copia selezione | `Ctrl+b [` / `v`, poi `y` |
| reload config | `Ctrl+b r` |

Kitty usa correttamente `TERM=xterm-kitty`; il setup non sostituisce o avvolge il
comando `ssh`, che rimane il client OpenSSH standard. Il collegamento si effettua
sempre normalmente con `ssh user@host`. Se il sistema remoto conosce già
`xterm-kitty` non serve altro; in caso contrario, dopo avere configurato l'accesso
SSH, preparare una volta quella specifica combinazione utente/host con:

```bash
./bin/install-kitty-terminfo-remote user@host
# oppure, dopo avere eseguito il setup:
install-kitty-terminfo-remote user@host
```

L'helper legge localmente `xterm-kitty` con `infocmp`, lo invia tramite OpenSSH e lo
compila sul remoto con `tic` in `~/.terminfo`, senza `sudo` e senza modificare shell,
configurazione SSH o `TERM`. È idempotente e accetta anche alias di `~/.ssh/config`.
Non effettua connessioni durante il normale setup. `kitten ssh` resta disponibile
come funzione manuale di Kitty, ma non viene usato automaticamente né è necessario
nel workflow predefinito.

OpenSSH trasmette il valore di `TERM`, ma non il relativo database terminfo: non
esiste quindi una configurazione esclusivamente locale di Kitty che possa rendere
`xterm-kitty` disponibile su qualunque distribuzione remota. Per ottenere questo
risultato senza preparare i singoli account bisognerebbe usare automaticamente
`kitten ssh` oppure degradare `TERM`; il setup evita entrambe le modifiche.

Con tmux annidato, `Ctrl+b Ctrl+b` invia il prefix al livello interno. Dopo avere
installato il terminfo remoto, tmux può essere avviato da una sessione SSH con
`TERM=xterm-kitty` e continua poi a esporre `tmux-256color` alle applicazioni.

Per tornare al terminale precedente basta avviarlo normalmente: il setup non cambia
le associazioni globali GNOME per impostazione predefinita e non rimuove GNOME
Terminal. Per fare in modo che le applicazioni compatibili aprano Kitty tramite il
meccanismo standard di Fedora, abilitare questa opzione in `config/local.env`:

```bash
SET_KITTY_AS_DEFAULT_TERMINAL=true
```

L'opzione installa `xdg-terminal-exec` e gestisce
`~/.config/xdg-terminals.list`, conservando l'eventuale file personale come
`~/.config/xdg-terminals.list.workstation-setup.bak`. Per ripristinare la scelta
precedente, rimettere al suo posto il backup oppure rimuovere il file gestito.
Per disabilitare le configurazioni di Kitty e tmux, rinominare i rispettivi file
gestiti; per il rollback ripristinare i file `.workstation-setup.bak`, se presenti.
I pacchetti restano installati perché possono essere usati da altre configurazioni.

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

Per visualizzare una guida rapida dei comandi disponibili e degli alias creati,
senza eseguire l'installazione:

```bash
./install.sh --info
```

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
