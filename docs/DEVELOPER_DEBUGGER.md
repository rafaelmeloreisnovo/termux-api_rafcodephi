# Developer Mode + Debugger App (Termux:API)

Objetivo: reduzir fricção para usar o Termux:API com ferramentas de depuração do Android **sem mudar identidade/pacote/arquitetura do app**.

## Pré-condições

- Opções de desenvolvedor ativas no Android.
- Depuração USB ativa.
- `adb` disponível na máquina host.
- APK debug instalado no dispositivo.

## Fluxo rápido

1. Verifique conexão:

```bash
adb devices
```

2. Garanta que o app existe no device:

```bash
adb shell pm list packages | grep com.termux.api
```

3. Ative wait-for-debugger para o processo do app:

```bash
adb shell am set-debug-app -w com.termux.api
```

4. Abra o app e conecte debugger via Android Studio.

5. Para remover a marcação de debug-app:

```bash
adb shell am clear-debug-app
```

## Seleção manual via UI do Android

- Configurações → Sistema → Opções do desenvolvedor
- **Selecionar aplicativo de depuração** → `Termux:API`
- (Opcional) habilitar **Aguardar depurador**

## Observações de segurança e compatibilidade

- Este fluxo é apenas para desenvolvimento/validação.
- Não altera `applicationId`, `sharedUserId`, `TERMUX_PACKAGE_NAME` nem regras de assinatura oficial.
- Não substitui trilha de release assinada oficialmente.
