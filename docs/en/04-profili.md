# Profiles and forbidden flags

🌐 [Italiano](../04-profili.md) · **English** · [中文](../zh/04-profili.md)

| Profile | What it does | Noise | Root |
|---|---|---|---|
| `triage` | Small wordlist to see how the target responds. | medium | no |
| `cartelle` | Directory discovery with auto-calibration. | high | no |
| `ricorsivo` | Like cartelle, it descends into the directories it finds. | high | no |
| `file` | Files with common extensions. | high | no |
| `backup` | Backup files and editor leftovers. | high | no |
| `api` | API endpoints. | high | no |
| `parametri` | Parameter names. | high | no |
| `prudente` | Directories with 10 threads and 2 requests per second. | medium | no |

`ffuf-cli profili` prints the exact flags of each one.

## What each profile does

**triage** (`no extra flags`). Small wordlist to see how the target responds. Before any long scan: see what kind of responses the server gives. URL: `{origine}/FUZZ`, default wordlist: `/usr/share/seclists/Discovery/Web-Content/common.txt`.

**cartelle** (`-ac`). Directory discovery with auto-calibration. The main job: typical structure of a modern application. URL: `{origine}/FUZZ`, default wordlist: `/usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt`.

**ricorsivo** (`-ac -recursion -recursion-depth 2`). Like cartelle, it descends into the directories it finds. After finding /admin, search inside /admin. Depth is capped at 2: without it, the queue explodes. URL: `{origine}/FUZZ`, default wordlist: `/usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt`.

**file** (`-e .php,.bak,.old,.txt,.zip`). Files with common extensions. To find forgotten scripts and archives. URL: `{origine}/FUZZ`, default wordlist: `/usr/share/seclists/Discovery/Web-Content/raft-medium-files.txt`.

**backup** (`-e .bak,.old,.backup,.copy,.orig,.save,.swp,.tmp -mc 200`). Backup files and editor leftovers. Looks for copies of the code left on the server: they often contain credentials. URL: `{origine}/FUZZ`, default wordlist: `/usr/share/seclists/Discovery/Web-Content/raft-medium-files.txt`.

**api** (`-mc 200,201,401,403,405`). API endpoints. A 401 or 403 on an existing endpoint is as useful a result as a 200. URL: `{origine}/api/FUZZ`, default wordlist: `/usr/share/seclists/Discovery/Web-Content/api-endpoints.txt`.

**parametri** (`-fs 0`). Parameter names. To discover undocumented parameters of an endpoint. URL: `{origine}/api?FUZZ=test`, default wordlist: `/usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt`.

**prudente** (`-ac -t 10 -rate 2`). Directories with 10 threads and 2 requests per second. The default profile on client infrastructure. URL: `{origine}/FUZZ`, default wordlist: `/usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt`.

## Passing flags by hand

Everything you write after `--` goes to ffuf, after the profile flags, provided it is not on the forbidden list. The check is case-insensitive and accepts both `-flag valore` and `-flag=valore`, with one or two dashes.

```sh
ffuf-cli lancia prudente https://app.example.org --scope scope.toml -- -timeout 5
```

## Forbidden list

| Flag | Why |
|---|---|
| `-u` | the URL is built by the profile from the validated target |
| `-w` | the wordlist is passed with --wordlist |
| `-o`, `-of` | output is handled by ffuf-cli |
| `-d` | credential attempts (POST, data, brute force) aren't part of this tool |
| `-x` | HTTP method or proxy: credential attempts (POST, data, brute force) aren't part of this tool |
| `-request`, `-request-proto` | a saved request can contain a host different from the validated target |
| `-mode` | multi-wordlist modes are for credential brute force |
| `-replay-proxy` | resends the requests to a third party |
| `-input-cmd` | runs a command to generate the input |
| `-r` | following redirects can lead to out-of-scope hosts |
| `-preflight`, `-postflight` | a saved request can point to a different host |
| `-config` | a config file can change URL, method and proxy |

## What the filter does not do

It is not a sandbox. If you want to get around it you can, for example by calling `ffuf` directly. It is there to stop mistakes and bad habits, not an attacker who already has access to your terminal. If you need a forbidden flag for an activity agreed with the client, use ffuf directly and record the decision in the engagement.
