# Permissões do Termux:API

Tabela prática: API, permissão Android principal, exigência de runtime e risco/limitação.

| API | Permissão Android necessária | Runtime permission | Risco/limitação |
|---|---|---|---|
| Brightness | `WRITE_SETTINGS` | Especial (tela de settings) | Falha sem liberação manual em “Modificar configurações do sistema”. |
| CameraPhoto | `CAMERA` | Sim | Sem câmera física ou permissão negada => erro. |
| CallLog | `READ_CALL_LOG` | Sim | Dados sensíveis; Android pode restringir em versões recentes. |
| ContactList | `READ_CONTACTS` | Sim | Privacidade; retorno vazio com permissão negada. |
| InfraredFrequencies / InfraredTransmit | `TRANSMIT_IR` | Não (normal) | Só funciona em hardware com IR emissor. |
| Location | `ACCESS_FINE_LOCATION` | Sim | Depende de localização global ligada no Android. |
| MicRecorder / SpeechToText | `RECORD_AUDIO` | Sim | Sem microfone/permissão => indisponível. |
| SmsInbox | `READ_SMS`, `READ_CONTACTS` | Sim | Alto impacto de privacidade; pode ser bloqueado por política OEM. |
| SmsSend | `SEND_SMS`, `READ_PHONE_STATE` | Sim | Pode gerar custo financeiro e bloqueios da operadora. |
| TelephonyCall | `CALL_PHONE` | Sim | Inicia ligação real; depende de suporte de telefonia/SIM. |
| TelephonyCellInfo | `ACCESS_COARSE_LOCATION` | Sim | Pode retornar incompleto sem localização ativa. |
| TelephonyDeviceInfo | `READ_PHONE_STATE` | Sim | Identificadores podem ser mascarados por versão/política Android. |
| WifiScanInfo | `ACCESS_FINE_LOCATION` | Sim | Scans dependem de localização e políticas de scan do Android. |
| NotificationList | Acesso de notificação (`BIND_NOTIFICATION_LISTENER_SERVICE`) | Configuração especial | Requer ativação manual de Notification Listener. |
| Sensor | `BODY_SENSORS` (quando aplicável) | Sim | Sensores variam por dispositivo; pode não haver hardware. |

## Permissões declaradas no manifest

O app também declara permissões amplas no `AndroidManifest.xml` para manter compatibilidade funcional com APIs disponíveis (ex.: storage, rede, NFC, áudio, vibração, etc.). Nem toda permissão declarada é requisitada diretamente no switch de `api_method`, mas pode ser usada por componentes específicos da aplicação.
