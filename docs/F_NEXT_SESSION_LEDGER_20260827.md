# F_NEXT_SESSION_LEDGER_20260826_27_V1

Estado: `APPEND_ONLY / READ_ONLY / claim_allowed=false`

Objetivo: registrar, uma a uma, as mudanças de rota, implementações, evidências, erros, correções e decisões desta sessão até a interação que pediu a incorporação do ledger na API/GitHub/Drive.

Invariantes:

- `VISION != ARTIFACT != EXECUTION != EVIDENCE != CLAIM`
- `TOKEN_VAZIO != 0`
- erro de rota deve ser registrado, não apagado
- ramo superado deve ser marcado como `SUPERSEDED`/`DEFERRED`, não reescrito como se nunca tivesse existido
- ausência de observação física não pode virar claim físico

## Entradas

1. **GNSS_CONTRACT_BOUNDARY — CLOSED_PASS** — contrato do receipt GNSS fechado antes de evidência de runtime.
2. **GNSS_RUNTIME_PROMOTION — SUPERSEDED** — FN-GNSS-002 foi promovido como próximo passo físico; depois reconhecido como ramo superpriorizado.
3. **ANDROID_GNSS_API_REVIEW — RECORDED** — ausência de callback raw não deve ser convertida em claim de falha de hardware.
4. **GNSS_RECEIPT_COLLECTOR — IMPLEMENTED_NOT_CURRENTLY_ACTIVE** — coletor implementado com minimização e TOKEN_VAZIO.
5. **LOCATION_GNSS_DISPATCH — SUPERSEDED_BY_DEFER** — `gnss-receipt` foi ligado ao coletor e depois desativado como execução física.
6. **GNSS_LOCAL_HELPER — IMPLEMENTED_NOT_TO_BE_RUN** — helper local existe, mas não pertence à rota ativa.
7. **GNSS_PERMISSION_DOCS — RECORDED** — fronteiras de privacidade/evidência e não-equivalências documentadas.
8. **CI_BUILD — PASS** — build corrigido do `termux-api_rafcodephi` concluiu para ARM32/ARM64.
9. **BUILD_ARTIFACT_IDENTITY — PASS** — identidade e SHA-256 do bundle de Actions conferidos.
10. **PRODUCER_BINDING — PASS_LIMITED** — fonte/build ligados; runtime físico continuou não observado.
11. **PROVENANCE_SEALER — READY_AND_CI_VALIDATED** — ferramenta de selagem/proveniência pronta e cruzada com contrato genérico.
12. **LEGAL_GOVERNANCE_CI — PASS** — gates de falsificabilidade/F_next/sealer/matriz/drift executados.
13. **GOVERNANCE_RECEIPT_V6 — RECORDED** — V6 registrou build, correções semânticas e gaps de runtime.
14. **PHYSICAL_RUNBOOK — DEFERRED_BY_USER** — runbook preparado, porém removido da rota ativa após rejeição explícita do GNSS físico.
15. **BUILD_ARTIFACT_CATALOG — PASS** — variantes APK, hashes, bundle e signer CI catalogados.
16. **GOVERNANCE_RECEIPT_V7 — RECORDED** — identidade de artefato fechada sem promover ABI/signer/runtime/reprodutibilidade não observados.
17. **RECEIPT_GATE_PATH_COVERAGE — PASS** — mudanças em `data/receipts/legal/**` passaram a disparar gates jurídicos.
18. **DRIVE_INDEX_APPEND — RECORDED** — índice canônico do Drive recebeu deltas V6/V7 em modo append-only.
19. **BUNDLE_DELIVERED — PASS** — ZIP com APKs/checksums/metadados do build CI entregue ao usuário.
20. **TERMUX_DOWNLOAD_PATH — CORRECTED** — foi escrito `~/storage/download`; correção: `~/storage/downloads`.
21. **PRECHECK_PURPOSE — CLARIFIED** — hash/ABI/signer eram somente pré-verificação antes de eventual instalação.
22. **GNSS_RUNTIME_HELPER_PURPOSE — CLARIFIED_THEN_DEFERRED** — helper foi explicado como probe GNSS físico e, em seguida, explicitamente rejeitado.
23. **PHYSICAL_GNSS — DEFERRED_BY_USER** — nenhum probe GPS/GNSS/raw measurement integra a rota ativa.
24. **SCOPE_CORRECTION — PASS** — GNSS reclassificado como ramo lateral/deferido, não como P0 global.
25. **ZIP_PURPOSE — CLARIFIED** — ZIP = build compilado do `termux-api_rafcodephi`; não é dado do usuário, backup ou captura GNSS.
26. **SESSION_LEDGER_API — ACTIVE** — histórico incorporado ao método read-only `FNext` e espelhado nos repositórios/Drive adequados.

## API

`api_method=FNext`

- `subcommand=current`: estado atual.
- `subcommand=ledger`: entradas 1..26.
- `subcommand=entry`, `seq=N`: uma entrada.

O método não solicita localização, não lê sensores, não abre rede e não acessa arquivos pessoais.

## Correção fail-closed do ramo físico

`Location` continua reconhecendo `request=gnss-receipt` apenas para compatibilidade histórica. Nesta versão a resposta é `DEFERRED_BY_USER`, `physical_sensor_access=false`, `claim_allowed=false`; `GnssReceiptCapture.capture(...)` não é chamado por esse request.
