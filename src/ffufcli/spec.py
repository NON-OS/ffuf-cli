"""Descrizione di ffuf: profili, flag vietati, formato dei risultati."""

from __future__ import annotations

import json

from ffufcli.profili import Profilo
from ffufcli.risultati import Voce

NOME = "ffuf"
BINARIO = "ffuf"
DESCRIZIONE = "Fuzzing di percorsi con scope validato, dry-run di default e audit a catena di hash."
MODO = "url"
PASSA = ("uno", "-u")
UNO_EXTRA = ("-noninteractive", "-of", "json")
USCITA = "-o"
VERSIONE = ("-V",)
RICONOSCI = "ffuf version"  # testo che il binario vero stampa con {VERSIONE}: distingue da programmi omonimi
INSTALLAZIONE = "Kali/Debian: sudo apt install ffuf. macOS: brew install ffuf. Ovunque con Go: go install github.com/ffuf/ffuf/v2@latest"
SEGRETI = frozenset({"h"})
GRUPPO = "Status HTTP"
NOTA_ATTIVITA = (
    "il fuzzing invia migliaia di richieste: è molto visibile nei log, può far scattare WAF e blocchi, "
    "e su servizi fragili può degradare le prestazioni."
)

_SL = "/usr/share/seclists/Discovery/Web-Content"

PROFILI = {
    p.nome: p
    for p in (
        Profilo("triage", "Wordlist piccola per capire come risponde il target.", (), "medio",
                "Prima di qualunque scansione lunga: vedi che tipo di risposte da' il server.",
                modello="{origine}/FUZZ", wordlist=f"{_SL}/common.txt"),
        Profilo("cartelle", "Scoperta di directory con auto-calibrazione.", ("-ac",), "alto",
                "Il lavoro principale: struttura tipica di un'applicazione moderna.",
                modello="{origine}/FUZZ", wordlist=f"{_SL}/raft-medium-directories.txt"),
        Profilo("ricorsivo", "Come cartelle, entra nelle directory trovate.",
                ("-ac", "-recursion", "-recursion-depth", "2"), "alto",
                "Dopo aver trovato /admin, cerca dentro /admin. La profondità è limitata a 2: senza, la coda esplode.",
                modello="{origine}/FUZZ", wordlist=f"{_SL}/raft-medium-directories.txt"),
        Profilo("file", "File con estensioni comuni.", ("-e", ".php,.bak,.old,.txt,.zip"), "alto",
                "Per trovare script e archivi dimenticati.",
                modello="{origine}/FUZZ", wordlist=f"{_SL}/raft-medium-files.txt"),
        Profilo("backup", "File di backup e residui di editor.",
                ("-e", ".bak,.old,.backup,.copy,.orig,.save,.swp,.tmp", "-mc", "200"), "alto",
                "Cerca copie del codice lasciate sul server: spesso contengono credenziali.",
                modello="{origine}/FUZZ", wordlist=f"{_SL}/raft-medium-files.txt"),
        Profilo("api", "Endpoint di API.", ("-mc", "200,201,401,403,405"), "alto",
                "Un 401 o un 403 su un endpoint esistente è un risultato utile quanto un 200.",
                modello="{origine}/api/FUZZ", wordlist=f"{_SL}/api-endpoints.txt"),
        Profilo("parametri", "Nomi di parametri.", ("-fs", "0"), "alto",
                "Per scoprire parametri non documentati di un endpoint.",
                modello="{origine}/api?FUZZ=test", wordlist=f"{_SL}/burp-parameter-names.txt"),
        Profilo("prudente", "Cartelle con 10 thread e 2 richieste al secondo.",
                ("-ac", "-t", "10", "-rate", "2"), "medio",
                "Il profilo da usare di default su infrastrutture di clienti.",
                modello="{origine}/FUZZ", wordlist=f"{_SL}/raft-medium-directories.txt"),
    )
}  # fmt: skip

_MOTIVO_AUTH = "i tentativi con credenziali (POST, dati, brute force) non fanno parte di questo strumento"

VIETATI = {
    "u": "l'URL lo costruisce il profilo a partire dal target validato",
    "w": "la wordlist si passa con --wordlist",
    "o": "l'output lo gestisce ffuf-cli",
    "of": "l'output lo gestisce ffuf-cli",
    "d": _MOTIVO_AUTH,
    "x": "metodo HTTP o proxy: " + _MOTIVO_AUTH,
    "request": "una richiesta salvata può contenere un host diverso dal target validato",
    "request-proto": "una richiesta salvata può contenere un host diverso dal target validato",
    "mode": "le modalità multi-wordlist servono al brute force di credenziali",
    "replay-proxy": "reinvia le richieste a un terzo",
    "input-cmd": "esegue un comando per generare l'input",
    "r": "seguire i redirect può portare su host fuori scope",
    "preflight": "una richiesta salvata può puntare a un host diverso",
    "postflight": "una richiesta salvata può puntare a un host diverso",
    "config": "un file di configurazione può cambiare URL, metodo e proxy",
}

ESEMPI_VIETATI = [
    ["-u", "x"],
    ["-w", "x"],
    ["-d", "a=b"],
    ["-X", "POST"],
    ["-mode", "clusterbomb"],
    ["-request=r.txt"],
    ["-r"],
    ["-config", "x"],
]
ESEMPI_AMMESSI = [["-mc", "200"], ["-H", "X-A: b"], ["-t", "5"], ["-fs", "123"]]


def voci(testo: str) -> list[Voce]:
    try:
        dati = json.loads(testo)
    except json.JSONDecodeError:
        return []
    out = []
    for r in dati.get("results", []) if isinstance(dati, dict) else []:
        url = str(r.get("url", ""))
        if url:
            stato = str(r.get("status", ""))
            out.append(Voce(url, f"{url} [{stato}] {r.get('length', '')}B", stato))
    return out


# -- lingua -------------------------------------------------------------------
# Testi tradotti, generati da l10n/. L'italiano resta quello definito sopra.
_TR_TESTI: dict[str, dict[str, str]] = {
    "en": {
        "descrizione": "Path fuzzing with a validated scope, dry-run by default and a hash-chained audit.",
        "nota_attivita": "fuzzing sends thousands of requests: it is very visible in the logs, it can trip WAFs and blocks, and on fragile services it can degrade performance.",
        "installazione": "Kali/Debian: sudo apt install ffuf. macOS: brew install ffuf. Anywhere with Go: go install github.com/ffuf/ffuf/v2@latest",
        "gruppo": "HTTP status",
    },
    "zh": {
        "descrizione": "路径模糊测试，带作用域校验、默认 dry-run 以及哈希链审计。",
        "nota_attivita": "模糊测试会发送成千上万个请求：在日志中非常显眼，可能触发 WAF 和封禁，对脆弱的服务还可能拖累其性能。",
        "installazione": "Kali/Debian：sudo apt install ffuf。macOS：brew install ffuf。任何装了 Go 的环境：go install github.com/ffuf/ffuf/v2@latest",
        "gruppo": "HTTP 状态码",
    },
}
_TR_PROFILI: dict[str, dict[str, list[str]]] = {
    "en": {
        "triage": [
            "Small wordlist to see how the target responds.",
            "Before any long scan: see what kind of responses the server gives.",
        ],
        "cartelle": [
            "Directory discovery with auto-calibration.",
            "The main job: typical structure of a modern application.",
        ],
        "ricorsivo": [
            "Like cartelle, it descends into the directories it finds.",
            "After finding /admin, search inside /admin. Depth is capped at 2: without it, the queue explodes.",
        ],
        "file": ["Files with common extensions.", "To find forgotten scripts and archives."],
        "backup": [
            "Backup files and editor leftovers.",
            "Looks for copies of the code left on the server: they often contain credentials.",
        ],
        "api": ["API endpoints.", "A 401 or 403 on an existing endpoint is as useful a result as a 200."],
        "parametri": ["Parameter names.", "To discover undocumented parameters of an endpoint."],
        "prudente": [
            "Directories with 10 threads and 2 requests per second.",
            "The default profile on client infrastructure.",
        ],
    },
    "zh": {
        "triage": ["小字典，用于了解目标如何响应。", "在任何长时间扫描之前：先看看服务器返回哪种类型的响应。"],
        "cartelle": ["目录发现，带自动校准。", "主要工作：现代应用的典型目录结构。"],
        "ricorsivo": [
            "与 cartelle 相同，并进入找到的目录。",
            "在找到 /admin 后，继续在 /admin 内部查找。深度限制为 2：否则队列会急剧膨胀。",
        ],
        "file": ["带常见扩展名的文件。", "用于查找被遗忘的脚本和归档文件。"],
        "backup": ["备份文件和编辑器残留文件。", "查找遗留在服务器上的代码副本：它们常常包含凭据。"],
        "api": ["API 端点。", "对一个存在的接口返回 401 或 403，和返回 200 一样是有用的结果。"],
        "parametri": ["参数名。", "用于发现某个接口未公开的参数。"],
        "prudente": ["目录发现，10 个线程、每秒 2 个请求。", "在客户基础设施上默认使用的配置。"],
    },
}
_TR_VIETATI: dict[str, dict[str, str]] = {
    "en": {
        "esegue un comando per generare l'input": "runs a command to generate the input",
        "i tentativi con credenziali (POST, dati, brute force) non fanno parte di questo strumento": "credential attempts (POST, data, brute force) aren't part of this tool",
        "l'URL lo costruisce il profilo a partire dal target validato": "the URL is built by the profile from the validated target",
        "l'output lo gestisce ffuf-cli": "output is handled by ffuf-cli",
        "la wordlist si passa con --wordlist": "the wordlist is passed with --wordlist",
        "le modalità multi-wordlist servono al brute force di credenziali": "multi-wordlist modes are for credential brute force",
        "metodo HTTP o proxy: i tentativi con credenziali (POST, dati, brute force) non fanno parte di questo strumento": "HTTP method or proxy: credential attempts (POST, data, brute force) aren't part of this tool",
        "reinvia le richieste a un terzo": "resends the requests to a third party",
        "seguire i redirect può portare su host fuori scope": "following redirects can lead to out-of-scope hosts",
        "un file di configurazione può cambiare URL, metodo e proxy": "a config file can change URL, method and proxy",
        "una richiesta salvata può contenere un host diverso dal target validato": "a saved request can contain a host different from the validated target",
        "una richiesta salvata può puntare a un host diverso": "a saved request can point to a different host",
    },
    "zh": {
        "esegue un comando per generare l'input": "执行命令来生成输入",
        "i tentativi con credenziali (POST, dati, brute force) non fanno parte di questo strumento": "凭据相关的尝试（POST、数据、暴力破解）不属于本工具的范畴",
        "l'URL lo costruisce il profilo a partire dal target validato": "URL 由配置根据经过校验的目标构建",
        "l'output lo gestisce ffuf-cli": "输出由 ffuf-cli 管理",
        "la wordlist si passa con --wordlist": "字典通过 --wordlist 传入",
        "le modalità multi-wordlist servono al brute force di credenziali": "多字典模式用于凭据暴力破解",
        "metodo HTTP o proxy: i tentativi con credenziali (POST, dati, brute force) non fanno parte di questo strumento": "HTTP 方法或代理：凭据相关的尝试（POST、数据、暴力破解）不属于本工具的范畴",
        "reinvia le richieste a un terzo": "会把请求重新转发给第三方",
        "seguire i redirect può portare su host fuori scope": "跟随重定向可能跳转到作用域之外的主机",
        "un file di configurazione può cambiare URL, metodo e proxy": "配置文件可能改变 URL、方法和代理",
        "una richiesta salvata può contenere un host diverso dal target validato": "一个已保存的请求可能包含与经过校验的目标不同的主机",
        "una richiesta salvata può puntare a un host diverso": "一个已保存的请求可能指向另一个主机",
    },
}
_ORIGINALI = (DESCRIZIONE, NOTA_ATTIVITA, INSTALLAZIONE, GRUPPO, PROFILI, VIETATI)


def applica_lingua(lingua: str) -> None:
    """Passa testi, profili e motivi dei flag vietati alla lingua scelta. Ripartendo
    sempre dagli originali italiani, chiamarla più volte non accumula niente."""
    global DESCRIZIONE, NOTA_ATTIVITA, INSTALLAZIONE, GRUPPO, PROFILI, VIETATI
    from dataclasses import replace

    DESCRIZIONE, NOTA_ATTIVITA, INSTALLAZIONE, GRUPPO, PROFILI, VIETATI = _ORIGINALI
    testi = _TR_TESTI.get(lingua)
    if not testi:
        return
    DESCRIZIONE = testi["descrizione"] or DESCRIZIONE
    NOTA_ATTIVITA = testi["nota_attivita"] or NOTA_ATTIVITA
    INSTALLAZIONE = testi["installazione"] or INSTALLAZIONE
    GRUPPO = testi["gruppo"] or GRUPPO
    prof = _TR_PROFILI.get(lingua, {})
    PROFILI = {
        n: replace(p, descrizione=prof[n][0] or p.descrizione, quando=prof[n][1] or p.quando) if n in prof else p
        for n, p in PROFILI.items()
    }
    viet = _TR_VIETATI.get(lingua, {})
    VIETATI = {k: viet.get(v, v) for k, v in VIETATI.items()}
