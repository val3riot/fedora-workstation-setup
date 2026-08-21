# Audit del setup v5

## Novità v5

### Tema Zsh opzionale
- aggiunto `--config-zsh-theme`, combinabile con i profili esistenti;
- aggiunti Starship e i plugin dai rispettivi upstream, con URL centralizzati;
- configurazione separata e blocco `.zshrc` gestito, idempotente e con backup;
- controlli condizionali aggiunti al doctor.

### Endpoint configurabili
- aggiunto `config/sources.env` come unico punto per gli URL dei vendor;
- migrati Oh My Zsh, SDKMAN, NVM, Miniconda, Docker, Docker Desktop, VS Code, DBeaver, Bruno e JetBrains Toolbox;
- `config/local.env` può sovrascrivere singoli endpoint.

### Docker Rootless vero
- sostituita la precedente modalità tramite gruppo `docker`;
- aggiunto `docker-ce-rootless-extras`;
- verifica di `newuidmap`, `newgidmap`, `/etc/subuid` e `/etc/subgid`;
- daemon rootful disabilitato;
- servizio Docker eseguito come servizio systemd dell'utente;
- `loginctl enable-linger` configurabile per autostart;
- context `rootless` come default;
- rimozione dell'utente dal gruppo `docker` durante upgrade v4→v5;
- `docker-runtime` seleziona `rootless` oppure `desktop`.

### Virtualizzazione
- aggiunti KVM/QEMU, libvirt, virt-manager, virt-install e virt-viewer;
- aggiunti Vagrant e `vagrant-libvirt` come layer DevOps per VM dichiarative;
- aggiunti rete NAT libvirt, OVMF/UEFI e swtpm;
- gestione compatibile con libvirtd classico o socket modulari;
- diagnostica KVM/libvirt aggiunta al doctor.

## Limitazioni note
- Docker Rootless usa networking in user space e ha differenze rispetto al daemon rootful, ad esempio sulle porte privilegiate;
- Docker Desktop resta un runtime separato e non viene avviato automaticamente;
- Windows può richiedere driver VirtIO aggiuntivi in base al tipo di disco/rete scelto;
- alcuni endpoint puntano deliberatamente alla release `latest`, quindi il setup non è ancora completamente riproducibile bit-per-bit.
