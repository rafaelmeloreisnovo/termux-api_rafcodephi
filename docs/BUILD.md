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
