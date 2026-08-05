# Statusline INEMA para Claude Code

> Não confundir com a skill **`session-statusline`** deste mesmo repo: aquela é um
> checkpoint em texto que o Claude escreve quando você pede; esta aqui é a **barra
> fixa** que o Claude Code desenha abaixo do input, toda vez que renderiza.

Barra de status com contexto, modelo/esforço, limites de uso e tokens do dia:

```
nmaldaner@spark-922b:/home/nmaldaner/projetos/wifi Opus 5/low ctx 10% 5h:24%→00:10 w:29%→10/08 21:00 d:109.6M
```

| Campo | Significado |
|---|---|
| `user@host:cwd` | usuário, máquina e diretório atual |
| `Opus 5/low` | modelo e nível de esforço da sessão (acompanha o `/model`) |
| `ctx 10%` | quanto da janela de contexto já foi usado |
| `5h:24%→00:10` | limite de 5 horas usado e hora do reset |
| `w:29%→10/08 21:00` | limite semanal usado e reset |
| `d:109.6M` | tokens somados hoje (todas as sessões locais) |

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
