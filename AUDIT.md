# Audit di provenienza — 2026-08-22

## Politica e controlli

Il setup preferisce repository Fedora ufficiale, poi repository/installer vendor,
poi release upstream ufficiale verificata. Registry generici, COPR, mirror, fork e
repository community non sono automaticamente ufficiali. Gli URL runtime sono in
`config/sources.env`; download statici e RPM diretti usano SHA-256, la chiave
Docker anche la fingerprint pubblicata.

```bash
./bin/provenance-audit.sh       # locale, senza Internet
./bin/audit-urls.sh             # policy/centralizzazione URL
./bin/audit-urls.sh --online    # raggiungibilità endpoint
./bin/check-secrets.sh
./bin/test.sh
./bin/doctor.sh                 # include provenance locale
```

## Coding agents

| Agente | Vendor e documentazione verificata | Metodo ufficiale corrente | Setup/workstation dopo audit |
|---|---|---|---|
| Codex 0.149.0 | OpenAI, `learn.chatgpt.com/docs/codex/cli` | standalone `chatgpt.com/codex/install.sh` | `~/.local/bin/codex` → release sotto `~/.codex` |
| Claude Code 2.1.239 | Anthropic, `code.claude.com/docs/en/setup` | native `claude.ai/install.sh` | `~/.local/bin/claude` → `~/.local/share/claude/versions/2.1.239` |
| Copilot CLI | GitHub, guida ufficiale Copilot CLI | `gh.io/copilot-install` (o Homebrew) | checksum installer verificato, `~/.local/bin/copilot` |

Homebrew non è stato introdotto perché assente. I package npm legacy
`@openai/codex`, `@anthropic-ai/claude-code` e `@github/copilot` sono rimossi e
controllati come assenti. Ogni agente ha una sola destinazione nel `PATH`.
Autenticazione e configurazioni sono state preservate; i test mostrano soltanto
`authentication present: yes/no`.

## Risultato software

| Software | Versione | Path/metodo | Fonte | Verifica/azione |
|---|---:|---|---|---|
| Git, Zsh, Kitty, tmux, OpenSSH | Fedora 44 corrente | `/usr/bin`, RPM | Fedora ufficiale | conformi |
| Plugin Zsh | 0.8.0 / 0.7.1 | RPM | Fedora ufficiale | migrati dai clone ai pacchetti Fedora |
| Oh My Zsh | commit fissato | clone ufficiale | upstream ufficiale | origin e installer/checksum verificati |
| Starship | 1.26.0 | `~/.local/bin` | release upstream | SHA-256 verificato |
| Java/Maven/Gradle | 21.0.12 Temurin / 3.9.16 / 9.7.0 | SDKMAN | progetti ufficiali | conformi |
| Node/NVM | 24.19.0 / 0.40.6 | `~/Tools/nvm` | `nvm-sh/nvm` | installer fissato e verificato |
| Python/Miniconda | 3.14.7 / 26.5.3 | Fedora / Anaconda | ufficiali | installer esatto e SHA-256 |
| Docker/Compose | 29.7.2 / 5.5.0 RPM | RPM vendor | Docker ufficiale | GPG/fingerprint; rootless configurato |
| Docker Desktop | 4.87.0 | RPM diretto | Docker ufficiale | aggiornato, SHA-256 vendor |
| VS Code | 1.134.0 | RPM | Microsoft ufficiale | repo e GPG conformi |
| libvirt/QEMU/Vagrant | Fedora / 2.3.4 | RPM | Fedora ufficiale | Fedora scelto per `vagrant-libvirt` |
| DBeaver | 26.1.5 | RPM diretto | DBeaver ufficiale | checksum; corretto bug symlink `%post` |
| Bruno | 4.1.0 | RPM release | `usebruno/bruno` ufficiale | digest; gestito bug `%postun` upstream |
| JetBrains Toolbox | 3.7.2 | `~/Tools` | JetBrains ufficiale | API e checksum vendor |
| Discord | Flatpak | Flathub | community/unofficial | mantenuto per preservare dati/sessione; nessun RPM Fedora/vendor |
| Obsidian | Flatpak | Flathub | verificato dal team, community-maintained | metodo indicato anche dal vendor |
| Ollama | 0.32.14 | `/usr/local/bin`, preesistente | storia non attestabile | non gestito/non modificato; warning |

Il COPR `phracek/PyCharm`, abilitato ma senza pacchetti installati, è stato rimosso.
Gli IDE Toolbox e i dati utente non sono stati toccati. RPM Fusion, Google Chrome e
OpenAI ChatGPT sono esterni al setup: inventariati ma non modificati.

Docker Desktop installa intenzionalmente i propri plugin sotto
`/usr/lib/docker/cli-plugins`, mentre Engine installa Compose/Buildx sotto
`/usr/libexec/docker/cli-plugins`: entrambi sono RPM Docker ufficiali. Nella
sessione audit `docker compose` seleziona il plugin Desktop 5.4.0 invece del plugin
Engine 5.5.0. La coesistenza è documentata e non è stata alterata rimuovendo file
posseduti dai rispettivi pacchetti vendor.

## Esecuzione

Dal parser corrente è stato ricavato ed eseguito:

```bash
./install.sh --all --config-zsh-theme
```

`--all` include già development e desktop; nel file locale ignorato è stato posto
`SET_KITTY_AS_DEFAULT_TERMINAL=true`. Sono stati applicati TeX Live medium, agenti,
Docker rootless/Desktop, virtualizzazione, app desktop, Kitty, tmux e tema Zsh.
L'ultima ripresa si è fermata prima delle operazioni root del modulo power-mode per
un prompt PolicyKit chiuso; su successiva richiesta dell'utente non sono state fatte
altre richieste root. Tutto il resto e il provenance audit locale sono completati.
Il controllo finale ha inoltre rilevato una preferenza GNOME preesistente, più
prioritaria del file generico, che mantiene GNOME Terminal: il modulo è stato
corretto per gestire anche quel file con backup, ma la correzione non è stata
applicata alla home corrente dopo lo stop alle richieste di permesso.
