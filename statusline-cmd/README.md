# Statusline INEMA para Claude Code

> Não confundir com a skill **`session-statusline`** deste mesmo repo: aquela é um
> checkpoint em texto que o Claude escreve quando você pede; esta aqui é a **barra
> fixa** que o Claude Code desenha abaixo do input, toda vez que renderiza.

Barra de status com contexto, modelo/esforço, limites de uso e tokens do dia:

```
nmaldaner@spark-922b:/home/nmaldaner/projetos/wifi → portal Opus 5.5/medium ctx 24% 5h:30%→03:59 w:62% F:1%→19/10 20:59 d:28.8M
```

| Campo | Significado |
|---|---|
| `user@host:cwd` | usuário, máquina e pasta onde a sessão foi aberta (fica fixa) |
| `→ portal` | **projeto ativo**: aparece em amarelo quando o Claude está mexendo em outro projeto de `~/projetos` pelo caminho completo (lido dos últimos comandos da sessão, sem gastar crédito) |
| `Opus 5.5/medium` | modelo e nível de esforço da sessão (acompanha o `/model`) |
| `ctx 24%` | quanto da janela de contexto já foi usado |
| `5h:30%→03:59` | limite de 5 horas usado e hora do reset |
| `w:62%` | limite semanal geral usado |
| `F:1%→19/10 20:59` | limite semanal **por modelo** (inicial do modelo; `!` se em alerta) e reset |
| `d:28.8M` | tokens somados hoje (todas as sessões locais) |

## Instalar

```bash
git clone https://github.com/inematds/skillmanager3x
bash skillmanager3x/statusline-cmd/install.sh
```

Ou, já dentro da pasta:

```bash
bash install.sh
```

O instalador copia o script para `~/.claude/statusline-command.sh`, registra o bloco
`statusLine` no `~/.claude/settings.json` (com backup `.bak`) e mostra uma prévia.
A barra aparece no próximo render — nenhuma sessão precisa ser reiniciada.

Remover: `bash install.sh --uninstall` (tira só a entrada `statusLine`).

## Trocar de projeto: `cc`

A sessão do Claude Code não muda de pasta depois de aberta (um `cd` para fora volta
sozinho). Trocar de projeto de verdade é abrir o Claude na outra pasta — e o
`cc-projeto.sh` faz isso numa palavra, sem gastar crédito:

```bash
echo "source $HOME/skillmanager3x/statusline-cmd/cc-projeto.sh" >> ~/.bashrc   # ajuste o caminho do clone
```

| Você digita | O que acontece |
|---|---|
| `cc portal` | entra em `~/projetos/portal` e abre o Claude |
| `cc port` | nome parcial: um achado vai direto; vários mostram lista numerada |
| `cc portal -c` | idem, continuando a última conversa daquele projeto |
| `cc` | abre o Claude na pasta atual |

Abre pelo `~/projetos/cc.sh` se ele existir, senão pelo `cc.sh` desta pasta, senão pelo
`claude`. `CC_BASE` e `CC_LAUNCHER` mudam a pasta dos projetos e o lançador.

## Lançadores: `cc` e `cx` (Linux e Windows)

Atalhos de uma palavra para abrir as CLIs na pasta atual com as flags que uso no dia a dia.
Argumentos extras passam adiante (ex.: `cc.sh -c` continua a última conversa).

| Arquivo | Abre | Flags |
|---|---|---|
| `cc.sh` / `cc.bat` | Claude Code | `--chrome --dangerously-skip-permissions --exclude-dynamic-system-prompt-sections`, saída de até 64k tokens |
| `cx.sh` / `cx.bat` | Codex CLI | `--dangerously-bypass-approvals-and-sandbox` |

> **Atenção:** essas flags fazem a CLI rodar comandos e editar arquivos **sem pedir
> permissão**. Use só em máquina e projetos seus.

Linux: copie `cc.sh`/`cx.sh` para a pasta dos projetos (ex.: `~/projetos`) e rode
`../cc.sh` de dentro do projeto — ou use a função `cc` acima. Windows: coloque
`cc.bat`/`cx.bat` numa pasta do `PATH` e digite `cc` ou `cx` no terminal.

## Requisitos

`jq`, `curl`, `python3` e o `date` do GNU (coreutils). No Ubuntu/Debian:

```bash
sudo apt install jq curl python3
```

## Como funciona

- **Contexto**: lê a última `usage` do transcript da sessão e divide pela janela do
  modelo (1M no Opus; 200k nos demais, com heurística pro beta de 1M).
- **Limites 5h e semanal**: `GET https://api.anthropic.com/api/oauth/usage` com o
  `accessToken` de `~/.claude/.credentials.json` e o header
  `anthropic-beta: oauth-2025-04-20`. Cache de 300s em `/tmp/cc_limits_<uid>.json`
  e refetch em background, pra não travar o render nem tomar 429.
- **Tokens do dia**: soma os JSONL de `~/.claude/projects` (cache de 60s).
- **Modelo/esforço**: vêm do payload da statusline (`.model.display_name` e
  `.effort.level`); se faltarem, cai no `model`/`effortLevel` do `settings.json`.

Cada pessoa usa as próprias credenciais — nada de token é embutido no script.

## Personalizar

O script recebe o JSON do Claude Code no stdin e imprime uma linha. Para ver todos
os campos disponíveis (custo da sessão, `fast_mode`, `output_style`, `session_name`,
`context_window`), acrescente no começo:

```bash
printf '%s' "$input" > /tmp/cc_statusline_input.json
```

e leia o arquivo depois de um render.

> Rodar `/statusline` dentro do Claude Code faz ele reescrever esse arquivo do zero —
> use só se quiser abrir mão desta versão.
