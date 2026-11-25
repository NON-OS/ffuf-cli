# ffuf-cli

🌐 **Italiano** · [English](README.en.md) · [中文](README.zh.md)

[![ci](https://github.com/NON-OS/ffuf-cli/actions/workflows/ci.yml/badge.svg)](https://github.com/NON-OS/ffuf-cli/actions/workflows/ci.yml)
![License MIT](https://img.shields.io/badge/License-MIT-yellow)
![python 3.11+](https://img.shields.io/badge/python-3.11%2B-blue)
![Kali · Parrot · Linux](https://img.shields.io/badge/Kali%20%C2%B7%20Parrot%20%C2%B7%20Linux-primario-1793d1)
![ffuf](https://img.shields.io/badge/wrapper%20di-ffuf-green)
![dipendenze 0](https://img.shields.io/badge/dipendenze-0-lightgrey)

```
  ┌─ scope ─┐   ┌─ dry-run ─┐   ┌─ conferma ─┐   ┌─ ffuf ─┐   ┌─ audit ─┐   ┌─ rapporto ─┐
  │ valida  │ → │ mostra    │ → │ riferimento│ → │ parte   │ → │ catena  │ → │ riepilogo  │
  └─────────┘   └───────────┘   └────────────┘   └─────────┘   └─────────┘   └────────────┘
```

Fuzzing di percorsi web con scope validato, dry-run di default e audit a catena di hash. Solo target autorizzati.

> **Solo sistemi tuoi o con autorizzazione scritta.** Leggi [DISCLAIMER.md](DISCLAIMER.md) prima di lanciare qualsiasi cosa.

## Cos'è

`ffuf-cli` è un orchestratore sottile attorno a ffuf. Non lo sostituisce. Controlla che l'host sia nello scope, costruisce l'URL dal profilo (non lo scrivi tu) e limita lo strumento alla scoperta di contenuti: percorsi, file, endpoint, parametri.

ffuf è un fuzzer generico: con `-d` e `-X POST` diventa uno strumento di brute force di credenziali, con `-mode clusterbomb` prova tutte le combinazioni. Sono attività con regole d'ingaggio proprie (blocco degli account, soglie, orari) che non si improvvisano con un flag. Questo wrapper le lascia fuori: `-d`, `-data`, `-X`, `-mode` sono vietati. Per quello che resta serve comunque una wordlist, e l'unico modo di sapere quanto è grande è contarla prima.

## In azione

![ffuf-cli in modalità guidata su Kali Linux](docs/img/guida-kali.png)

*Modalità guidata (`ffuf-cli guida`) eseguita su Kali Linux: logo, scelta del profilo, validazione dello scope, anteprima del comando. Screenshot reale.*

```console
$ ffuf-cli lancia prudente https://app.example.org --scope scope.toml
Ingaggio : ACME-2026 (ACME-2026-014)
Profilo  : prudente - Cartelle con 10 thread e 2 richieste al secondo. [rumore medio]
  ok  https://app.example.org  (host app.example.org: combacia con app.example.org)
Comando  : ffuf -u https://app.example.org/FUZZ -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt -ac -t 10 -rate 2 -noninteractive -of json -o out/esempio/risultati-1.json
Attività: il fuzzing invia migliaia di richieste: è molto visibile nei log, può far scattare WAF e blocchi, e su servizi fragili può degradare le prestazioni.

Dry-run: non ho lanciato niente. Aggiungi --esegui per partire davvero.
```

Con un target fuori scope, anche in mezzo a target validi, non parte niente:

```console
$ ffuf-cli lancia prudente https://app.example.org https://evil.example --scope scope.toml
ffuf-cli: target fuori scope, non eseguo nulla:
  https://evil.example: host evil.example: hostname non presente tra gli inclusi
$ echo $?
3
```

Il comando `lancia` non parte mai senza `--esegui`. Quello che vedi sopra è un'anteprima.

L'output parla la lingua che scegli: `--lang it|en|zh` oppure la variabile `NONOS_LANG` (comoda per impostarla a livello di sistema). Si parte sempre in italiano. Il README è anche in [English](README.en.md) e [中文](README.zh.md).

## Cosa fa

| | |
|---|---|
| Scope | Dominio, host o URL (modalità `url`), con esclusioni e date di validità. Nel dubbio rifiuta. |
| Dry-run | Di default non parte niente. `--esegui` chiede conferma. |
| Profili | 8, con indicazione di rumore e di quando usarli. |
| Filtro flag | I flag che aggirano lo scope o rubano il controllo dell'output sono bloccati. |
| Filtro liste | `filtra` legge una lista da stdin e lascia passare solo ciò che è nello scope. |
| Scope firmato | Il cliente firma lo scope con la sua chiave SSH. Se il file cambia dopo la firma, non parte niente. |
| Audit | Registro a catena di hash. Hash dello scope e firmatario inclusi, valori sensibili oscurati. |
| Rapporto | Riepilogo dei risultati in testo, Markdown o JSON. |
| Confronto | Cosa è cambiato tra due lanci, con codice di uscita per la CI. |
| Dipendenze | Nessuna: solo la libreria standard di Python. |

## Piattaforma

Pensato per **Kali**, **Parrot** e Linux in generale: è lì che questi strumenti vivono e dove `ffuf-cli` viene usato. Gira anche su macOS. Windows non è provato, e lì alcuni controlli sui privilegi (`os.geteuid`) non valgono.

## Installazione

Serve Python 3.11 o più recente e ffuf nel `PATH`. Kali/Debian: sudo apt install ffuf. macOS: brew install ffuf. Ovunque con Go: go install github.com/ffuf/ffuf/v2@latest

```sh
git clone git@github.com:NON-OS/ffuf-cli.git
cd ffuf-cli
python3 -m venv .venv && . .venv/bin/activate
pip install -e .
ffuf-cli doctor
```

## Primo uso

### Il modo più semplice: modalità guidata

`ffuf-cli guida` ti fa le domande una alla volta — scope, profilo, target — mostra l'anteprima del comando e non lancia niente senza la tua conferma finale. È il modo consigliato per iniziare:

```sh
ffuf-cli guida
```

### Oppure a comandi

```sh
ffuf-cli init scope.toml          # crea il modello
$EDITOR scope.toml               # compilalo con il cliente
ffuf-cli verifica https://app.example.org --scope scope.toml
ffuf-cli lancia prudente https://app.example.org --scope scope.toml            # dry-run
ffuf-cli lancia prudente https://app.example.org --scope scope.toml --esegui   # parte davvero
```

In un terminale `--esegui` ti chiede di scrivere il riferimento dell'ingaggio. In uno script usa `--conferma`. Altri flag di ffuf si passano dopo `--`, se non sono tra i vietati ([docs/04-profili.md](docs/04-profili.md)).

Un flusso completo:

```sh
ffuf-cli lancia prudente https://app.example.org --scope scope.toml --wordlist ~/wordlist.txt --esegui
ffuf-cli rapporto out/*-prudente/
```

## Comandi

| Comando | Cosa fa |
|---|---|
| `guida` | modalità interattiva passo per passo: scope → profilo → target → conferma |
| `lancia <profilo> <target...>` | valida e costruisce (o lancia) ffuf. Con `-` legge i target da stdin |
| `filtra` | legge target da stdin e stampa solo quelli nello scope |
| `verifica <target...>` | dice se i target sono nello scope, senza lanciare |
| `scope-firma <file>` / `scope-verifica <file>` | firma e controlla lo scope con una chiave SSH |
| `rapporto <file_o_cartella>` | riepilogo dei risultati: percorsi trovati |
| `confronta <vecchio> <nuovo>` | differenze tra due lanci |
| `profili` | elenca i profili con i flag esatti |
| `audit [file]` | verifica la catena del registro |
| `init [file]` | crea un file di scope da compilare |
| `doctor` | controlla ffuf, versione, privilegi |

## Profili

| Profilo | Cosa fa | Rumore | Root |
|---|---|---|---|
| `triage` | Wordlist piccola per capire come risponde il target. | medio | no |
| `cartelle` | Scoperta di directory con auto-calibrazione. | alto | no |
| `ricorsivo` | Come cartelle, entra nelle directory trovate. | alto | no |
| `file` | File con estensioni comuni. | alto | no |
| `backup` | File di backup e residui di editor. | alto | no |
| `api` | Endpoint di API. | alto | no |
| `parametri` | Nomi di parametri. | alto | no |
| `prudente` | Cartelle con 10 thread e 2 richieste al secondo. | medio | no |

![ffuf-cli doctor e profili su Kali Linux](docs/img/info-kali.png)

*`ffuf-cli doctor` (trova il binario reale di ffuf in `/usr/bin/`) e l'elenco dei profili, su Kali Linux.*

## Codici di uscita

| Codice | Significato |
|---|---|
| 0 | tutto a posto |
| 1 | `confronta --exit-code` ha trovato differenze |
| 2 | argomenti sbagliati o flag vietato |
| 3 | almeno un target fuori scope |
| 4 | scope illeggibile, malformato o scaduto |
| 5 | ffuf assente |
| 6 | esecuzione senza conferma, o profilo che richiede root senza sudo |
| 7 | ffuf è uscito con errore, o la catena di audit è spezzata |

## La catena di strumenti

Questo repository è uno di otto, pensati per lavorare insieme. Ognuno controlla lo scope per conto suo.

```mermaid
flowchart LR
    subfinder[subfinder-cli]
    dnsx[dnsx-cli]
    subfinder --> dnsx
    naabu[naabu-cli]
    dnsx --> naabu
    httpx[httpx-cli]
    naabu --> httpx
    katana[katana-cli]
    httpx --> katana
    ffuf[ffuf-cli]
    katana --> ffuf
    nuclei[nuclei-cli]
    ffuf --> nuclei
    style ffuf stroke-width:3px
```

- [subfinder-cli](https://github.com/NON-OS/subfinder-cli): enumerazione di sottodomini
- [dnsx-cli](https://github.com/NON-OS/dnsx-cli): risoluzione dns
- [naabu-cli](https://github.com/NON-OS/naabu-cli): scansione di porte
- [httpx-cli](https://github.com/NON-OS/httpx-cli): sonde http
- [katana-cli](https://github.com/NON-OS/katana-cli): crawling web
- [nuclei-cli](https://github.com/NON-OS/nuclei-cli): scansione di vulnerabilità
- [nmap-cli](https://github.com/NON-OS/nmap-cli): scansione di porte e servizi con nmap

## Documentazione

1. [Introduzione e filosofia](docs/01-introduzione.md)
2. [Autorizzazione: cosa serve prima di toccare un target](docs/02-autorizzazione.md)
3. [Il file di scope](docs/03-scope.md)
4. [Profili e flag vietati](docs/04-profili.md)
5. [Il registro di audit](docs/05-audit.md)
6. [Architettura](docs/06-architettura.md)
7. [Dove provarlo in sicurezza](docs/07-lab.md)
8. [Rapporti e confronti](docs/08-rapporti.md)
9. [Scope firmato](docs/09-firma.md)
10. [Compatibilità e prove](docs/10-compatibilita.md)

Il cheatsheet shell da cui è nato il progetto è in [scripts/](scripts/).

## Cosa non fa

Non scopre se hai il permesso: lo dichiari tu nel file di scope, e il programma ti crede. Non protegge da chi lancia `ffuf` direttamente. Il filtro sui flag è una rete di sicurezza contro gli errori, non una sandbox. I dettagli sono in [docs/06-architettura.md](docs/06-architettura.md).

## Sviluppo

```sh
make check     # ruff (lint + format), mypy --strict, test e coverage
```

Nessuna dipendenza a runtime (solo la libreria standard). Gli strumenti di sviluppo si installano con `pip install -e ".[dev]"`. Vedi [CONTRIBUTING.md](CONTRIBUTING.md) e [SECURITY.md](SECURITY.md).

## Licenza

MIT, vedi [LICENSE](LICENSE). La licenza copre il codice, non autorizza nessuna attività.
