# Build do Termux:API

Este guia reduz fricção para build local sem alterar identidade do app oficial.

## Requisitos locais

- Linux/macOS (ou ambiente compatível com shell POSIX).
- JDK 11+ disponível no `PATH`.
- Android SDK instalado (preferencialmente via Android Studio) com platform e build-tools compatíveis com `compileSdk` do projeto.
- Permissão de execução no wrapper: `chmod +x ./gradlew`.

## Build debug

```bash
./gradlew assembleDebug
```

Uso recomendado: validação local, CI e testes rápidos.

## Build release

```bash
./gradlew assembleRelease
```

Uso recomendado: fluxo de release. Em produção, exige assinatura segura da trilha oficial.

## Diferença entre debug e release

- **debug**:
  - assinado com chave de debug/teste;
  - usado para validação e desenvolvimento;
  - não substitui release oficial para cenários de permissões de produção.
- **release**:
  - otimizações/proguard de release;
  - destinado a distribuição;
  - deve usar assinatura oficial fora de ambiente de teste.

## Assinatura compatível com Termux oficial

Para uso real integrado com o ecossistema Termux, o app precisa estar assinado com a **mesma chave** do Termux oficial. Sem isso, integrações protegidas por assinatura (shared UID/permissões signature) não funcionam como no canal oficial.

## Localização dos APKs

Após build:

- Debug: `app/build/outputs/apk/debug/`
- Release: `app/build/outputs/apk/release/`

O projeto gera APKs por ABI (ex.: `armeabi-v7a` e `arm64-v8a`).


## Menor fricção com Java (preflight)

Se houver múltiplos JDKs no host, use:

```bash
./scripts/gradlew-safe.sh assembleDebug
```

O script tenta usar uma JVM compatível (17..22) via `JAVA17_HOME`, `JAVA21_HOME` ou `JAVA_HOME` antes de chamar `./gradlew`.

## Diagnóstico de instalação por ABI/assinatura

Após gerar APK, rode diagnóstico antes de instalar em aparelho físico:

```bash
./scripts/diagnose-install-android.sh app/build/outputs/apk/debug/<apk>.apk
```

Esse passo reduz falha mascarada em ARM32/ARM64 (incluindo Moto E7 Power) e detecta conflito de assinatura com instalação prévia.

## Compatibilidade alvo (Termux)

- Android API 28+
- `armeabi-v7a` (ARM32)
- `arm64-v8a` (ARM64)

## CI de integridade (build + artefatos)

O workflow `.github/workflows/advanced_hardcoded_ci.yml` executa:

1. `assembleDebug` e `assembleRelease` (sem alterar o fluxo oficial de release).
2. Validação de compatibilidade ABI ARM32/ARM64 via `ci/validate-apk-abis.sh`.
3. Assinatura **interna de validação** de um APK release (`*-ci-signed.apk`) com keystore efêmera de CI.
4. Upload de artefatos debug, release, release assinado internamente e checksums SHA-256.

Isso mantém dois trilhos explícitos:

- **Trilho oficial**: release oficial (chave real) permanece intacto.
- **Trilho interno de validação**: signed CI transitório para testes automatizados.
