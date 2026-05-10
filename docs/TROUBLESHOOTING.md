# Troubleshooting do Termux:API

## 1) App assinado com chave diferente

**Sintoma:** APIs falham com erro de permissão/integração entre plugins.

**Causa:** assinatura diferente da usada pelo Termux principal.

**Ação:** reinstalar conjunto coerente (Termux + plugins) ou usar trilha oficial com mesma assinatura.

## 2) Termux:API instalado sem pacote `termux-api`

**Sintoma:** comandos CLI não encontrados ou não disparam chamadas esperadas.

**Causa:** app Android instalado, mas utilitário de linha de comando ausente no ambiente Termux.

**Ação:** instalar também o pacote `termux-api` dentro do Termux.

## 3) Permissão Android negada

**Sintoma:** API retorna erro/resultado vazio para câmera, áudio, SMS, contatos, etc.

**Ação:** conceder runtime permissions manualmente em Configurações do Android e repetir o comando.

## 4) Notification Listener desativado

**Sintoma:** `NotificationList` sem resultados.

**Ação:** habilitar acesso de notificação para Termux:API em:
- Configurações Android → Acesso a notificações.

## 5) `WRITE_SETTINGS` não liberado

**Sintoma:** API `Brightness` falha.

**Causa:** `WRITE_SETTINGS` é permissão especial (não é runtime comum).

**Ação:** liberar em tela específica de “Modificar configurações do sistema” para Termux:API.

## 6) Localização bloqueada

**Sintoma:** `Location`, `WifiScanInfo` e parte de `TelephonyCellInfo` sem dados.

**Ação:**
- conceder permissão de localização;
- habilitar localização global no dispositivo.

## 7) Problemas de ABI

**Sintoma:** APK não instala no dispositivo.

**Causa:** ABI incompatível com a CPU do aparelho.

**Ação:** usar o APK correto para `armeabi-v7a` (ARM32) ou `arm64-v8a` (ARM64).
