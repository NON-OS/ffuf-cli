# Profili e flag vietati

🌐 **Italiano** · [English](en/04-profili.md) · [中文](zh/04-profili.md)

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

`ffuf-cli profili` stampa i flag esatti di ciascuno.

## Cosa fa ciascun profilo

**triage** (`nessun flag aggiuntivo`). Wordlist piccola per capire come risponde il target. Prima di qualunque scansione lunga: vedi che tipo di risposte da' il server. URL: `{origine}/FUZZ`, wordlist di default: `/usr/share/seclists/Discovery/Web-Content/common.txt`.

**cartelle** (`-ac`). Scoperta di directory con auto-calibrazione. Il lavoro principale: struttura tipica di un'applicazione moderna. URL: `{origine}/FUZZ`, wordlist di default: `/usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt`.

**ricorsivo** (`-ac -recursion -recursion-depth 2`). Come cartelle, entra nelle directory trovate. Dopo aver trovato /admin, cerca dentro /admin. La profondità è limitata a 2: senza, la coda esplode. URL: `{origine}/FUZZ`, wordlist di default: `/usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt`.

**file** (`-e .php,.bak,.old,.txt,.zip`). File con estensioni comuni. Per trovare script e archivi dimenticati. URL: `{origine}/FUZZ`, wordlist di default: `/usr/share/seclists/Discovery/Web-Content/raft-medium-files.txt`.

**backup** (`-e .bak,.old,.backup,.copy,.orig,.save,.swp,.tmp -mc 200`). File di backup e residui di editor. Cerca copie del codice lasciate sul server: spesso contengono credenziali. URL: `{origine}/FUZZ`, wordlist di default: `/usr/share/seclists/Discovery/Web-Content/raft-medium-files.txt`.

**api** (`-mc 200,201,401,403,405`). Endpoint di API. Un 401 o un 403 su un endpoint esistente è un risultato utile quanto un 200. URL: `{origine}/api/FUZZ`, wordlist di default: `/usr/share/seclists/Discovery/Web-Content/api-endpoints.txt`.

**parametri** (`-fs 0`). Nomi di parametri. Per scoprire parametri non documentati di un endpoint. URL: `{origine}/api?FUZZ=test`, wordlist di default: `/usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt`.

**prudente** (`-ac -t 10 -rate 2`). Cartelle con 10 thread e 2 richieste al secondo. Il profilo da usare di default su infrastrutture di clienti. URL: `{origine}/FUZZ`, wordlist di default: `/usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt`.

## Passare flag a mano

Tutto ciò che scrivi dopo `--` finisce a ffuf, dopo i flag del profilo, a patto che non sia nell'elenco dei vietati. Il confronto non distingue maiuscole e minuscole e accetta sia `-flag valore` sia `-flag=valore`, con uno o due trattini.

```sh
ffuf-cli lancia prudente https://app.example.org --scope scope.toml -- -timeout 5
```

## Elenco dei vietati

| Flag | Perché |
|---|---|
| `-u` | l'URL lo costruisce il profilo a partire dal target validato |
| `-w` | la wordlist si passa con --wordlist |
| `-o`, `-of` | l'output lo gestisce ffuf-cli |
| `-d` | i tentativi con credenziali (POST, dati, brute force) non fanno parte di questo strumento |
| `-x` | metodo HTTP o proxy: i tentativi con credenziali (POST, dati, brute force) non fanno parte di questo strumento |
| `-request`, `-request-proto` | una richiesta salvata può contenere un host diverso dal target validato |
| `-mode` | le modalità multi-wordlist servono al brute force di credenziali |
| `-replay-proxy` | reinvia le richieste a un terzo |
| `-input-cmd` | esegue un comando per generare l'input |
| `-r` | seguire i redirect può portare su host fuori scope |
| `-preflight`, `-postflight` | una richiesta salvata può puntare a un host diverso |
| `-config` | un file di configurazione può cambiare URL, metodo e proxy |

## Quello che il filtro non fa

Non è una sandbox. Se vuoi aggirarlo ci riesci, per esempio chiamando `ffuf` direttamente. Serve a fermare gli errori e le abitudini sbagliate, non un malintenzionato che ha già accesso al tuo terminale. Se ti serve un flag vietato per un'attività concordata con il cliente, usa ffuf direttamente e annota la scelta nell'ingaggio.
