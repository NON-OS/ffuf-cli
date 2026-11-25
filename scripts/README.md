# Script

`ffuf_workflow.sh` è il cheatsheet da cui è nato il progetto: i comandi di ffuf in ordine di lavoro, con una nota su ciascuno che spiega perché e quando usarlo.

Non va eseguito così com'è. I target sono segnaposto e molti comandi sono pensati per essere lanciati uno alla volta, leggendo il risultato del precedente. Per lanciare davvero usa `ffuf-cli`, che controlla lo scope prima di partire.

## Cosa non copre il programma

Il cheatsheet include sezioni sul brute force di credenziali (POST con `-d`, `-mode clusterbomb`). `ffuf-cli` le lascia fuori di proposito: sono attività con regole d'ingaggio proprie (blocco degli account, soglie, orari) e vanno concordate per iscritto. Se le usi, usa ffuf direttamente.
