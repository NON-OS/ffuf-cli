#!/usr/bin/env bash
# ffuf_workflow_v2.sh
# Riferimento operativo completo. Solo target autorizzati.
# Le note spiegano il perché e il quando, non solo il cosa.

TARGET="<HOST_O_IP>"
DOMAIN="<DOMINIO_BASE>"
OUT="<PREFISSO_OUTPUT>"

# ---------------------------------------------------------------
# Directory / file discovery
# ---------------------------------------------------------------

# Triage veloce. common.txt è piccolo: serve a capire che tipo di
# risposte dà il target PRIMA di impegnarsi in scan lunghi.
ffuf -u "https://$TARGET/FUZZ" -w /usr/share/seclists/Discovery/Web-Content/common.txt -c

# Passata profonda con raft-medium-directories. Lista derivata da
# crawl reali, copre meglio le strutture tipiche di un'app moderna.
ffuf -u "https://$TARGET/FUZZ" -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt -c

# Ricorsione. Dopo aver trovato /admin, ffuf entra e fuzza /admin/FUZZ.
# -recursion-depth limita la profondità: senza, su app grandi la coda
# esplode e la scan non finisce più.
ffuf -u "https://$TARGET/FUZZ" -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt -recursion -recursion-depth 2 -ac -c

# Estensioni. Da usare DOPO aver fingerprintato lo stack (PHP, ASP, ecc.).
# Non fuzzo .php su un'app Node. -e moltiplica le richieste per il
# numero di estensioni: è rumore se non ho un motivo.
ffuf -u "https://$TARGET/FUZZ" -w /usr/share/seclists/Discovery/Web-Content/raft-medium-files.txt -e .php,.bak,.old,.txt,.zip -c

# Backup e file sorgente. Questa è la parte che spesso trova più
# di una directory discovery generica. Editor e script di deploy
# lasciano tracce prevedibili: .bak, .old, .swp, .orig, .save.
# Se app.php esegue codice ma app.php.bak viene servito come testo,
# ho appena letto il sorgente (credenziali, chiavi, logica interna).
ffuf -u "https://$TARGET/FUZZ" -w /usr/share/seclists/Discovery/Web-Content/raft-medium-files.txt -e .bak,.old,.backup,.copy,.orig,.save,.swp,.tmp -mc 200 -c

# .git esposto. Se .git/HEAD risponde 200, il repository è pubblico
# e posso ricostruire tutta la storia del codice (inclusi segreti
# cancellati). git-dumper fa il resto. Questo è un finding critico,
# non un semplice "file trovato".
ffuf -u "https://$TARGET/FUZZ" -w /usr/share/seclists/Discovery/Web-Content/raft-medium-files.txt -mc 200 -c | grep -i '\.git'

# ---------------------------------------------------------------
# API endpoint discovery
# Le directory classiche non bastano quando il target è una REST API.
# /api/v1/users è un endpoint, non una directory.
# ---------------------------------------------------------------

# Endpoint REST comuni. -mc include 401/403 perché un endpoint
# protetto è comunque un endpoint che esiste e vale la pena testare.
ffuf -u "https://$TARGET/api/FUZZ" -w /usr/share/seclists/Discovery/Web-Content/api-endpoints.txt -mc 200,201,401,403,405 -c

# Version enumeration. Le API cambiano versione e le vecchie
# restano spesso esposte senza le protezioni aggiunte dopo.
for v in v1 v2 v3; do
    ffuf -u "https://$TARGET/api/$v/FUZZ" -w /usr/share/seclists/Discovery/Web-Content/api-endpoints.txt -mc 200,201,401,403 -c
done

# Swagger / OpenAPI. Se trovo la spec, ho la mappa completa
# dell'API senza fuzzing: endpoint, parametri, modelli.
for doc in swagger.json openapi.json api-docs docs/api swagger/v1/swagger.json; do
    code=$(curl -s -o /dev/null -w "%{http_code}" "https://$TARGET/$doc")
    echo "$code $doc"
done

# GraphQL. Introspection query: se risponde, ho lo schema completo.
for path in graphql graphiql playground api/graphql; do
    curl -s -X POST "https://$TARGET/$path" \
        -H "Content-Type: application/json" \
        -d '{"query":"{__schema{types{name}}}"}' | head -c 200
    echo " → $path"
done

# ---------------------------------------------------------------
# Virtual host discovery
# App diverse sullo stesso IP che rispondono solo con l'Host giusto.
# Non è DNS enumeration: ffuf manda l'header Host, non risolve nomi.
# ---------------------------------------------------------------

# Baseline PRIMA di fuzzare. Un Host header palesemente falso
# mi dice come risponde il server a un vhost inesistente.
# Senza baseline, -fs è un numero inventato.
curl -s -o /dev/null -w "%{size_download}" -H "Host: nonexistent-$(date +%s).$DOMAIN" "https://$TARGET/"

# Fuzzo l'header Host. Il filtro -fs usa la dimensione della baseline.
# Molti server rispondono 200 a ogni Host: senza filtro, l'output
# è rumore identico.
ffuf -u "https://$TARGET/" -H "Host: FUZZ.$DOMAIN" -w /usr/share/dnsrecon/dnsrecon/data/subdomains-top1mil.txt -fs <DIMENSIONE_BASELINE> -c

# SNI-based vhost. Il FUZZ va nell'URL, non nell'header.
# Richiede che il nome risolva (DNS wildcard o /etc/hosts),
# altrimenti la connessione TLS fallisce prima di ffuf.
ffuf -u "https://FUZZ.$DOMAIN/" -w /usr/share/dnsrecon/dnsrecon/data/subdomains-top1mil.txt -mc 200,301,302,403 -fs <DIMENSIONE_BASELINE> -c

# ---------------------------------------------------------------
# Parameter discovery
# Il FUZZ va nel NOME del parametro, non nel valore. Serve a
# trovare parametri nascosti che l'app accetta ma non documenta.
# ---------------------------------------------------------------

# GET. -fs 0 filtra le risposte vuote, che spesso indicano
# "parametro non riconosciuto". Ma non sempre: se il target
# restituisce 200 con corpo vuoto per tutto, questo filtro
# nasconde i finding. Verifico sempre con una richiesta manuale.
ffuf -u "https://$TARGET/api?FUZZ=test" -w /usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt -fs 0 -c

# POST form-encoded. Il FUZZ nel body, non nell'URL.
ffuf -u "https://$TARGET/login" -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "FUZZ=test" -w /usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt -fs <DIMENSIONE_DEFAULT> -c

# Header fuzzing. Alcune app accettano header custom che
# modificano il comportamento (X-Forwarded-For, X-Original-URL).
ffuf -u "https://$TARGET/" -H "FUZZ: test" -w /usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt -fs <DIMENSIONE_DEFAULT> -c

# ---------------------------------------------------------------
# Value fuzzing (GET, POST, JSON)
# Qui il FUZZ è nel valore. Injection testing, IDOR, auth.
# ---------------------------------------------------------------

# GET value. Il wordlist dipende dallo scopo: payload per
# injection, ID list per IDOR.
ffuf -u "https://$TARGET/search?q=FUZZ" -w "<PAYLOAD_LIST>" -c

# Login form. -fc 401 filtra i tentativi falliti.
ffuf -u "https://$TARGET/login" -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=FUZZ" -w /usr/share/seclists/Passwords/Common-Credentials/top-1000.txt -fc 401 -c

# JSON POST. -fr "error" filtra le risposte che contengono
# "error" nel body, che spesso indicano input rifiutato.
ffuf -u "https://$TARGET/api/auth" -X POST \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"FUZZ"}' -w "<PASSWORD_LIST>" -fr "error" -c

# IDOR. Fuzzo l'ID in un endpoint autenticato. -mc 200 mostra
# solo le risposte valide; -ac filtra la pagina "non trovato".
ffuf -u "https://$TARGET/api/users/FUZZ" -w <(seq 1 1000) -mc 200 -ac -c

# ---------------------------------------------------------------
# Multi-wordlist
# Due keyword, due liste. User×pass, endpoint×id.
# ---------------------------------------------------------------

# Clusterbomb: ogni parola della lista 1 con ogni parola della lista 2.
# 100 utenti × 100 password = 10.000 richieste. Rumoroso.
ffuf -u "https://$TARGET/login" -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "user=USER&pass=PASS" \
  -w "<USER_LIST>:USER" -w "<PASS_LIST>:PASS" \
  -mode clusterbomb -fc 401 -c

# Pitchfork: le liste procedono in parallelo. 100 utenti e
# 100 password = 100 richieste (user1+pass1, user2+pass2...).
# Utile quando ho coppie note e voglio testarle in sequenza.
ffuf -u "https://$TARGET/login" -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "user=USER&pass=PASS" \
  -w "<USER_LIST>:USER" -w "<PASS_LIST>:PASS" \
  -mode pitchfork -fc 401 -c

# ---------------------------------------------------------------
# Raw request (autenticazione complessa)
# JWT, CSRF, cookie di sessione, header custom: ricostruire
# la richiesta a mano è un errore. Catturo da Burp, salvo in
# req.txt, metto FUZZ dove serve, lascio fare a ffuf.
# ---------------------------------------------------------------

ffuf --request req.txt -w "<WORDLIST>" -ac -c

# Multi-keyword nel raw request.
ffuf --request req.txt -w "<ENDPOINT_LIST>:ENDPOINT" -w "<ID_LIST>:ID" -mode pitchfork -ac -c

# ---------------------------------------------------------------
# Filtering strategy (la parte che separa un professionista)
# Ogni tipo di rumore ha il suo filtro. Non esiste "il filtro
# giusto" in assoluto: dipende dalla risposta del target.
# ---------------------------------------------------------------

# Status code.
ffuf -u "https://$TARGET/FUZZ" -w "<WORDLIST>" -mc 200,301,302,403 -c

# Dimensione. Il numero lo leggo dall'output, non lo indovino.
ffuf -u "https://$TARGET/FUZZ" -w "<WORDLIST>" -fs 1234 -c

# Parole. Quando la dimensione varia ma il numero di parole è
# costante (soft-404 con contenuto dinamico).
ffuf -u "https://$TARGET/FUZZ" -w "<WORDLIST>" -fw 100 -c

# Regex sul body. Attenzione: se la stringa appare anche in
# una pagina valida, il filtro nasconde un finding.
ffuf -u "https://$TARGET/FUZZ" -w "<WORDLIST>" -fr "not found|error" -c

# Tempo di risposta.
ffuf -u "https://$TARGET/FUZZ" -w "<WORDLIST>" -ft ">5000" -c

# ---------------------------------------------------------------
# Calibrazione: quando -ac funziona e quando mente
# -ac manda path random e impara la risposta "non trovato".
# Controlla nell'ordine: dimensione, parole, righe. Il primo
# attributo identico tra i probe diventa il filtro automatico.
#
# DOVE FALLISCE: se il target restituisce body che cambiano
# a ogni richiesta (timestamp, CSRF token), la dimensione
# varia e -ac non trova un pattern comune. In quel caso
# -ac è inutile e va sostituito.
# ---------------------------------------------------------------

# Calibrazione base.
ffuf -u "https://$TARGET/FUZZ" -w "<WORDLIST>" -ac -c

# Strategia advanced: aggiunge path con e senza trailing slash.
# Utile quando il server tratta diversamente /admin e /admin/.
ffuf -u "https://$TARGET/FUZZ" -w "<WORDLIST>" -acs advanced -c

# Calibrazione custom: se conosco già la stringa "non trovato",
# la passo esplicitamente. Implica -ac.
ffuf -u "https://$TARGET/FUZZ" -w "<WORDLIST>" -acc "nonexistent1" -acc "nonexistent2" -c

# Per-host calibration. Quando fuzzo l'header Host o ricorro
# su più vhost, ogni host ha il suo "non trovato". -ach
# calibra separatamente per ogni host.
ffuf -u "https://$TARGET/" -H "Host: FUZZ.$DOMAIN" -w "<VHOST_LIST>" -ach -c

# Quando -ac fallisce (body dinamico), passo a -fw o -fl
# invece di -fs. Il numero di parole o righe è più stabile
# della dimensione in byte.
ffuf -u "https://$TARGET/FUZZ" -w "<WORDLIST>" -fw 100 -c

# Se anche -fw fallisce, ancora la calibrazione con una
# stringa statica nota e filtro con regex.
ffuf -u "https://$TARGET/FUZZ" -w "<WORDLIST>" -fr 'not\s+found' -c

# ---------------------------------------------------------------
# Rate limiting e performance
# La velocità è nemica dell'affidabilità. Su target reale,
# se prendo 429 o il target rallenta, ho esagerato.
# ---------------------------------------------------------------

# Thread e rate. Default 40 thread. Su produzione reale,
# 10-20 è più sicuro. -rate 2 significa max 2 req/sec.
ffuf -u "https://$TARGET/FUZZ" -w "<WORDLIST>" -t 10 -rate 2 -c

# Delay random. Meno prevedibile di -rate fisso.
ffuf -u "https://$TARGET/FUZZ" -w "<WORDLIST>" -p 0.1-2.0 -c

# Timeout per richiesta. Senza, una singola richiesta lenta
# blocca un thread per sempre.
ffuf -u "https://$TARGET/FUZZ" -w "<WORDLIST>" -timeout 10 -c

# Limite totale. Le richieste in volo vengono abbandonate,
# quindi l'output è incompleto.
ffuf -u "https://$TARGET/FUZZ" -w "<WORDLIST>" -maxtime 300 -c

# ---------------------------------------------------------------
# Proxy e replay
# ---------------------------------------------------------------

ffuf -u "https://$TARGET/FUZZ" -w "<WORDLIST>" -x http://127.0.0.1:8080 -c
ffuf -u "https://$TARGET/FUZZ" -w "<WORDLIST>" -replay-proxy http://127.0.0.1:8080 -c

# ---------------------------------------------------------------
# Encoding
# URL encoding. Utile quando il payload contiene caratteri
# che devono essere codificati prima di essere inviati.
# ---------------------------------------------------------------

ffuf -u "https://$TARGET/FUZZ" -w "<WORDLIST>" -enc 'FUZZ:urlencode' -c

# ---------------------------------------------------------------
# Output
# -noninteractive è OBBLIGATORIO in script: senza, la console
# interattiva di ffuf può ingoiare i comandi successivi.
# ---------------------------------------------------------------

ffuf -u "https://$TARGET/FUZZ" -w "<WORDLIST>" -of json -o "$OUT.json" -noninteractive -c
ffuf -u "https://$TARGET/FUZZ" -w "<WORDLIST>" -of html -o "$OUT.html" -noninteractive -c
ffuf -u "https://$TARGET/FUZZ" -w "<WORDLIST>" -of csv -o "$OUT.csv" -noninteractive -c

# Silenzioso: solo risultati, niente banner/progress.
ffuf -u "https://$TARGET/FUZZ" -w "<WORDLIST>" -s -noninteractive
