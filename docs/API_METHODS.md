# API methods (`api_method`) do Termux:API

Fonte: `TermuxApiReceiver.java` (switch de `api_method`).

## Sistema
- BatteryStatus
- Brightness
- Clipboard
- Download
- Fingerprint
- FNext
- JobScheduler
- Keystore
- Notification
- NotificationChannel
- NotificationList
- NotificationRemove
- NotificationReply
- SAF
- Share
- StorageGet
- Toast
- Usb
- Vibrate
- Volume
- Wallpaper

### FNext — ledger read-only da sessão

`FNext` expõe somente o ledger append-only empacotado no código. Não lê localização, sensores, rede, arquivos pessoais, contas ou identificadores do aparelho.

Subcomandos:

| `subcommand` | efeito |
|---|---|
| `current` | estado atual, rota ativa e invariantes |
| `ledger` | todas as entradas cronológicas da sessão |
| `entry` | uma entrada; usar extra inteiro `seq` |

Estado canônico desta versão:

- `physical_sensor_access=false`;
- `network_access=false`;
- `claim_allowed=false`;
- `physical_gnss=DEFERRED_BY_USER`;
- GNSS não é o P0 global;
- o ZIP entregue é `CI_BUILD_ARTIFACT_PACKAGE`;
- shortcut Termux de armazenamento compartilhado: `~/storage/downloads`;
- `VISION!=ARTIFACT!=EXECUTION!=EVIDENCE!=CLAIM`;
- `TOKEN_VAZIO!=0`.

O request legado `Location --es request gnss-receipt` é reconhecido, mas nesta versão retorna `DEFERRED_BY_USER` e não chama o coletor físico.

## Mídia
- AudioInfo
- CameraInfo
- CameraPhoto
- MediaPlayer
- MediaScanner
- MicRecorder
- SpeechToText
- TextToSpeech
- Torch

## Sensores
- Sensor
- RafSensor
- InfraredFrequencies
- InfraredTransmit

### Análise espectral RAFAELIA

A análise espectral usa o método `Sensor` ou `RafSensor` com a ação `spectrum`. Ela coleta uma janela limitada no aplicativo `com.termux.rafacodephi`, calcula um periodograma local e retorna JSON.

Parâmetros:

| Extra | Padrão | Limite |
|---|---:|---:|
| `sensor_name` | obrigatório | acelerometer, gyroscope, magnetometer, light, proximity, pressure, gravity ou rotation_vector |
| `spectral_axis` | `magnitude` | magnitude, x, y, z ou w |
| `sample_count` | 128 | 16–512 |
| `sampling_period_us` | 20000 | 5000–200000 |
| `raf_timeout_ms` | 5000 | 1000–30000 |
| `window` | `hann` | hann ou rectangular |

Saída principal:

- frequência dominante;
- centroide espectral;
- RMS após remoção da média;
- resolução em frequência;
- taxa de amostragem efetiva;
- jitter temporal;
- bins de frequência e potência;
- `quality_state`;
- `claim_allowed=false`.

Estados de cautela:

- `TOKEN_VAZIO_FLAT_SIGNAL`: não há potência não-DC suficiente;
- `TOKEN_VAZIO_TIMING_JITTER`: a irregularidade temporal excede a régua do analisador;
- `EVIDENCIADO_COMPUTACIONAL`: cálculo completado dentro dos limites sintáticos e temporais, sem alegação causal ou física.

A operação não ativa microfone, não persiste amostras brutas e não executa em agenda automática.

## Rede
- WifiConnectionInfo
- WifiEnable
- WifiScanInfo

## Telefonia
- CallLog
- ContactList
- SmsInbox
- SmsSend
- TelephonyCall
- TelephonyCellInfo
- TelephonyDeviceInfo

## Storage
- SAF
- StorageGet
- MediaScanner

## UI / interação
- Dialog
- Nfc
- Toast
- Notification
- NotificationChannel
- NotificationRemove
- NotificationReply
