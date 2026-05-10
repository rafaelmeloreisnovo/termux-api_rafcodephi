# Native lowlevel (C/ASM) utilitário opcional

Sem alterar comportamento funcional do app Android, este repositório agora inclui um utilitário nativo opcional para validação/diagnóstico local.

## O que foi adicionado

- `native/checksum/fast_checksum.c`: rotina de checksum com caminho C puro + trechos inline ASM para ARM32/ARM64.
- `native/checksum/checksum_tool.c`: CLI para calcular checksum de arquivos.
- `scripts/build-native-tools.sh`: compila o binário local (`native/out/checksum_tool`).

## Build

```bash
bash scripts/build-native-tools.sh
```

## Uso

```bash
native/out/checksum_tool app/build/outputs/apk/debug/<apk>.apk
```

## Observações

- Caminho experimental e opcional, fora da trilha de release oficial Android.
- Não modifica `applicationId`, `TERMUX_PACKAGE_NAME`, `sharedUserId` ou fluxos de assinatura do APK.
