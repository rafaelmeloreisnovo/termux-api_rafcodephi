# Permissões do Termux:API

Tabela prática: API, permissão Android principal, exigência de runtime e risco/limitação.

| API | Permissão Android necessária | Runtime permission | Risco/limitação |
|---|---|---|---|
| Brightness | `WRITE_SETTINGS` | Especial (tela de settings) | Falha sem liberação manual em “Modificar configurações do sistema”. |
| CameraPhoto | `CAMERA` | Sim | Sem câmera física ou permissão negada => erro. |
| CallLog | `READ_CALL_LOG` | Sim | Dados sensíveis; Android pode restringir em versões recentes. |
| ContactList | `READ_CONTACTS` | Sim | Privacidade; retorno vazio com permissão negada. |
| InfraredFrequencies / InfraredTransmit | `TRANSMIT_IR` | Não (normal) | Só funciona em hardware com IR emissor. |
| Location | `ACCESS_FINE_LOCATION` | Sim | Pode expor localização precisa conforme implementação; permissão Android não prova quais campos são coletados nem qual base jurídica se aplica. |
| MicRecorder / SpeechToText | `RECORD_AUDIO` | Sim | Sem microfone/permissão => indisponível. |
| SmsInbox | `READ_SMS`, `READ_CONTACTS` | Sim | Alto impacto de privacidade; pode ser bloqueado por política OEM. |
| SmsSend | `SEND_SMS`, `READ_PHONE_STATE` | Sim | Pode gerar custo financeiro e bloqueios da operadora. |
| TelephonyCall | `CALL_PHONE` | Sim | Inicia ligação real; depende de suporte de telefonia/SIM. |
| TelephonyCellInfo | `ACCESS_COARSE_LOCATION` | Sim | Pode retornar incompleto sem localização ativa; dados de célula podem permitir inferência de localização. |
| TelephonyDeviceInfo | `READ_PHONE_STATE` | Sim | Identificadores podem ser mascarados por versão/política Android. |
| WifiScanInfo | `ACCESS_FINE_LOCATION` | Sim | Scans dependem de localização e políticas de scan do Android; BSSID/SSID podem ter valor de localização/contexto. |
| NotificationList | Acesso de notificação (`BIND_NOTIFICATION_LISTENER_SERVICE`) | Configuração especial | Requer ativação manual de Notification Listener. |
| Sensor | `BODY_SENSORS` (quando aplicável) | Sim | Sensores variam por dispositivo; pode não haver hardware. |

## Permissões declaradas no manifest

O app também declara permissões amplas no `AndroidManifest.xml` para manter compatibilidade funcional com APIs disponíveis (ex.: storage, rede, NFC, áudio, vibração, etc.). Nem toda permissão declarada é requisitada diretamente no switch de `api_method`, mas pode ser usada por componentes específicos da aplicação.

## Fronteira jurídica e de evidência — dados ≠ permissão

Este arquivo descreve **capacidade técnica Android**, não conformidade jurídica. Para qualquer
API que trate dados pessoais, sensíveis, identificadores, comunicação, áudio, localização ou
telemetria, aplicar os seguintes invariantes:

```text
permissão_declarada != permissão_concedida
permissão_concedida != dado_coletado
capacidade_do_hardware != campo_retornado_pela_API
campo_retornado != campo_persistido
campo_persistido != campo_transferido
OS_PERMISSION != LAWFUL_BASIS
```

A camada jurídica/semântica federada de referência está no Mapa:

- `rafaelmeloreisnovo/Mapa/docs/legal/GLOBAL_DATA_PRIVACY_GNSS_AI_GOVERNANCE_V1.md`
- `rafaelmeloreisnovo/Mapa/data/normative-graph/GLOBAL_DATA_PRIVACY_GNSS_AI_SEMANTIC_ATLAS_V1.json`
- `rafaelmeloreisnovo/Mapa/data/receipts/legal/GLOBAL_DATA_PRIVACY_GNSS_AI_GOVERNANCE_RECEIPT_20260826_V2.json`

## Location / GNSS — não colapsar superfícies diferentes

A API `Location` não deve ser documentada como sinônimo de “GNSS bruto”. Em Android, quando
hardware, versão, API e permissões permitem, existem superfícies distintas como:

- posição final: latitude/longitude, altitude, velocidade, bearing, acurácia e timestamp;
- provider/status/fix;
- status de constelação/satélite;
- NMEA;
- medições GNSS brutas, em APIs/dispositivos suportados.

A presença de `ACCESS_FINE_LOCATION` não prova que este projeto exponha PRN/SVID, C/N0,
azimute, elevação, pseudorange, Doppler, carrier phase, relógio do receptor ou outros campos
engenheirísticos. Qualquer claim dessa natureza exige inspeção de implementação + execução
em dispositivo e receipt de campo.

### Gate mínimo para `Location`

Antes de promover qualquer afirmação sobre coleta/uso de localização:

```yaml
api: Location
android_version: TOKEN_VAZIO
device: TOKEN_VAZIO
permission_state: TOKEN_VAZIO
provider: TOKEN_VAZIO
fields_returned: TOKEN_VAZIO
raw_gnss_measurements: TOKEN_VAZIO
purpose: TOKEN_VAZIO
retention: TOKEN_VAZIO
recipient_or_transfer: TOKEN_VAZIO
jurisdiction: TOKEN_VAZIO
legal_basis_or_authority: TOKEN_VAZIO
runtime_receipt: TOKEN_VAZIO
claim_allowed: false
```

`TOKEN_VAZIO` significa “ainda não demonstrado”, não `false`.
