# Skills de gestão de sessão

Quatro skills separadas, cada uma com um job claro e gatilhos disjuntos. `session-handoff` e `prime` formam o par grava → retoma. Substituem o
`session-handoff` monolítico antigo e o pacote combinado `session-memory-manager`.

## Estrutura

```
skill\
├── session-handoff\SKILL.md       fim de sessão (antes de /clear ou troca de agente)
│   └── scripts\handoff-grava.py   grava o snapshot e o índice handoffs/latest.md
├── prime\SKILL.md                 início de sessão: lê o handoff e o contexto do projeto
├── session-statusline\SKILL.md    checkpoint operacional durante o trabalho
└── memory-audit\SKILL.md          auditoria profunda de memória / CLAUDE.md
```

## Quando usar qual

| Skill | Quando | Gatilhos típicos |
|---|---|---|
| `session-handoff` | vai limpar contexto ou trocar de agente | "handoff", "wrap up", "vou dar /clear", "encerrar sessão", "passar para outro agente", "resumo final antes de limpar" |
| `prime` | começou sessão nova (depois do `/clear`) ou entrou num projeto com `handoffs/latest.md` | "prime", "retoma", "continua de onde parou", "lê o handoff" |
| `session-statusline` | quer um diagnóstico rápido durante o trabalho | "statusline", "checkpoint", "onde estamos", "organiza a sessão", "otimiza a sessão", "limpa a sessão", "próximos passos" |
| `memory-audit` | quer revisar o que está/deveria estar na memória | "analise a memória", "analise CLAUDE.md", "o que foi guardado", "contexto grande", "memória inchada", "limpa memória" |

Regra geral: **se for fim de sessão → handoff. Se for começo de sessão → prime. Se for "como estamos agora" → statusline. Se for "o que tem na memória" → audit.**

## O que mudou em `session-handoff` vs versão original

### Triggers (description)
- **Removidos:** "otimiza a sessão", "organiza a sessão", "limpa a sessão" — agora vão pra `session-statusline`.
- **Adicionados:** "vou dar /clear", "encerrar sessão", "passar para outro agente", "resumo final antes de limpar".
- **Novo:** bloco "Do NOT invoke for X" deixando a fronteira com as outras duas skills explícita.

### Comportamento `/clear`
- Intenção clara ("vou dar /clear", "vou limpar agora") → roda handoff direto.
- Intenção vaga ("talvez eu limpe") → pergunta uma vez antes.

Antes a regra era genérica ("invoke proactively if user says they're about to /clear"); agora distingue claro vs vago e evita fricção desnecessária.

### Conversas longas
- Nova regra: para >50 turns, focar em **pontos de inflexão** (mudanças de direção, decisões revertidas, estado atual) em vez de narração cronológica.

### Marcadores de confiança
Nova seção. Em vez de só "none" ou afirmação confiante, prefixar items incertos:

- `[confirmed]` — fato verificado nesta sessão
- `[unverified]` — provável, mas não confirmado
- `[?]` — incerto, depende de checagem

### Template de saída
A seção `Decisions locked + what shipped` foi **dividida em duas**:

- `## Applied / shipped` — o que foi efetivamente aplicado
- `## Proposed / attempted but not confirmed` — proposto ou parcial, com motivo

Isso evita que o próximo agente trate proposta como fato.

`Pick up here` mudou de "1-2 sentences" para "1-3 lines" com ramificação explícita quando aplicável (ex: "A se teste passar, B se falhar").

### Fontes a consultar
- "TodoWrite state" → "Task list state" (TodoWrite foi renomeado para o sistema de tasks atual).
- Adicionado: "Don't include exploration noise" — greps falhos, tentativas descartadas, contexto que o próximo agente reconstrói lendo os arquivos listados.

### Estrutura
- Hard rules + Anti-patterns **fundidos** numa lista só (`## Rules`). A versão antiga tinha sobreposição entre as duas seções.

### Paths
- `C:\Users\nateh\...` → `C:\Users\neima\...` (resíduo da skill original, agora corrigido).

### Cosmético
- Removidos os escapes markdown errados do original (`\---`, `run\_in\_background`, `\~/.claude`, `\\` duplicados em paths).

## O que NÃO foi incluído (e por quê)

- **Cota diária/semanal** (estava no `session-memory-manager`): Claude Code não expõe uso de cota pro modelo. Linhas tipo "Dia 5h: ok | atenção | crítico" só podem ser `unknown` sempre. Pra rastrear cota use a statusline do próprio Claude Code (`update-config` skill), não uma skill de gestão de sessão.
- **4ª skill `ai-session-discipline`** (proposta numa iteração): skill que nunca dispara é só markdown com frontmatter inflando o registro. Filosofia geral vai pra `CLAUDE.md` do projeto, não pra skill.
- **Path parametrizado `<usuario>`**: skills aqui são pessoais e locais. Hardcoding `neima` é mais útil — o agente usa direto sem substituir variável.

## Dicas de uso

### Para handoff funcionar bem
1. **Diga claramente** quando estiver encerrando: "vou dar /clear" ou "faz handoff" — evita disparo errado.
2. **Mencione o plano** se houver um: "fizemos handoff do plano X" — a skill prioriza listar o plano primeiro em "Key files".
3. **Confira shell IDs** no output: se você rodou processos em background, eles têm que aparecer em "Running state" com kill command — sem isso o próximo agente não consegue gerenciá-los.
4. **Grava em arquivo** (desde out/2026) — além do chat, o script `scripts/handoff-grava.py` salva `handoffs/history/<UTC>-<assunto>.md` (nunca sobrescreve), reescreve `handoffs/latest.md` como **índice dos trabalhos abertos** por assunto + cópia do mais novo, e faz commit só desses arquivos (sem push). Reuse o mesmo assunto ao atualizar um trabalho; `--fechado` tira do índice. A versão antiga era só chat.

### Para prime funcionar bem
1. Rode **logo no início** da sessão nova, antes de pedir qualquer coisa: `/clear` → `/prime`.
2. Ele **só lê**: não roda teste nem código e nunca retoma deploy, publicação ou envio sozinho. O handoff é tratado como dado, não como ordem.
3. Com vários trabalhos abertos no índice, ele lista todos; se o pedido não disser qual, faz o briefing do mais recente e pergunta qual retomar.
4. Confira o campo **"Verificado agora x relatado antes"**: o que só consta do handoff ainda precisa ser conferido no projeto (código, `git status`, testes).

### Para statusline funcionar bem
1. Use **durante** o trabalho, não no fim. Se você já decidiu encerrar, use handoff direto.
2. A "Recomendação" no final aponta o próximo movimento (continuar / compactar / auditar / handoff / limpar) — use isso pra decidir, não ignore.
3. Se aparecer muito "candidato para memória" e pouca coisa "guardado confirmado", considere rodar `memory-audit` em seguida.

### Para memory-audit funcionar bem
1. **Aponte o arquivo** se for específico: "analise meu CLAUDE.md em <path>" — sem path explícito ela só audita o que está visível na conversa.
2. A saída é recomendação, não execução. Se quiser que ela aplique os cortes ("salva isso", "remove aquilo"), peça explicitamente em uma segunda etapa.
3. Use periodicamente, não em toda sessão. Audit serve pra revisar acúmulo — fazer audit toda hora é o ruído que ele tenta evitar.

## Instalação

Para o harness do Claude Code reconhecer as skills, elas precisam estar em uma das pastas reconhecidas:

- **Global (todas as sessões):** `C:\Users\neima\.claude\skills\`
- **Por projeto:** `<projeto>\.claude\skills\`

Copie as quatro pastas (`session-handoff`, `prime`, `session-statusline`, `memory-audit`) para o destino escolhido. Cada pasta com seu `SKILL.md` dentro — não achatar.

Para verificar se foram registradas, use `/skills` no Claude Code (ou veja o registro no início da conversa).
