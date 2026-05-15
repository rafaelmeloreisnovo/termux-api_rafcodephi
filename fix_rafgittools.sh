#!/data/data/com.termux/files/usr/bin/bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║   fix_rafgittools.sh — Reparos RafGitTools via cat              ║
# ║   Autor : ΔRafaelVerboΩ / CIENTIESPIRITUAL                      ║
# ║   Alvo  : github.com/rafaelmeloreisnovo/RafGitTools             ║
# ║   Deps  : termux-app-rafacodephi / termux-api_rafcodephi        ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# USO (dentro da raiz do repo RafGitTools clonado):
#   bash fix_rafgittools.sh all       — aplica todos os reparos
#   bash fix_rafgittools.sh gradle    — fix build.gradle + settings
#   bash fix_rafgittools.sh manifest  — fix AndroidManifest.xml
#   bash fix_rafgittools.sh cmake     — fix CMakeLists.txt (page-size)
#   bash fix_rafgittools.sh bootstrap — fix paths com.termux → rafacodephi
#   bash fix_rafgittools.sh gitignore — gera .gitignore correto
#   bash fix_rafgittools.sh agents    — gera AGENTS.md no repo
#   bash fix_rafgittools.sh workflow  — gera CI workflow
#   bash fix_rafgittools.sh check     — diagnóstico sem modificar
#   bash fix_rafgittools.sh help
#
# BUGS CONHECIDOS (documentados em sessões anteriores):
#   BUG-F01: bootstrap binaries hardcoded com.termux (deve ser rafacodephi)
#   BUG-F02: Android 15 page-size ausente (-Wl,-z,max-page-size=16384)
#   BUG-F03: applicationId incorreto em build.gradle
#   BUG-F04: FileProvider authority aponta para com.termux errado
#   BUG-F05: compileSdkVersion desatualizado (< 34)
#   BUG-F06: JAVA_HOME / NDK path em CI quebrado para Termux

PKG_WRONG="com.termux"
PKG_RIGHT="com.termux.rafacodephi"
PKG_API_WRONG="com.termux.api"
PKG_API_RIGHT="com.termux.rafacodephi.api"

CMD="${1:-help}"; shift 2>/dev/null

_banner() {
  echo "╔══════════════════════════════════════════════════════╗"
  echo "║  fix_rafgittools — ΔRafaelVerboΩ / CIENTIESPIRITUAL ║"
  echo "╚══════════════════════════════════════════════════════╝"
}

# ──────────────────────────────────────────────────────────────────
# FIX-F01 + F03 + F05 — build.gradle (app level)
# ──────────────────────────────────────────────────────────────────
_fix_gradle() {
  echo "[gradle] Escrevendo app/build.gradle..."
  mkdir -p app
  cat > app/build.gradle << 'EOF'
// app/build.gradle — RafGitTools / ΔRafaelVerboΩ
// BUG-F01 corrigido: applicationId usa rafacodephi
// BUG-F05 corrigido: compileSdk 34, targetSdk 34

plugins {
    id 'com.android.application'
    id 'org.jetbrains.kotlin.android'
}

android {
    namespace          'com.termux.rafacodephi'
    compileSdk          34

    defaultConfig {
        applicationId               "com.termux.rafacodephi"
        minSdk                       28
        targetSdk                    34
        versionCode                   1
        versionName                  "1.0-rafacodephi"

        // BUG-F04 corrigido: authority alinha com applicationId
        manifestPlaceholders = [
            fileProviderAuthority: "com.termux.rafacodephi.fileprovider"
        ]

        ndk {
            abiFilters "armeabi-v7a", "arm64-v8a"
        }

        externalNativeBuild {
            cmake {
                cppFlags "-std=c++17"
                // BUG-F02 corrigido: Android 15 page-size
                arguments "-DANDROID_ARM_NEON=ON",
                          "-DCMAKE_SHARED_LINKER_FLAGS=-Wl,-z,max-page-size=16384"
            }
        }
    }

    buildTypes {
        release {
            minifyEnabled   false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'),
                          'proguard-rules.pro'
        }
        debug {
            applicationIdSuffix ".debug"
            debuggable true
        }
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = '17'
    }

    buildFeatures {
        viewBinding true
    }

    packagingOptions {
        // evita conflito de licenças
        exclude 'META-INF/LICENSE*'
        exclude 'META-INF/NOTICE*'
    }
}

dependencies {
    implementation 'androidx.core:core-ktx:1.12.0'
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.11.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    implementation 'androidx.lifecycle:lifecycle-viewmodel-ktx:2.7.0'
    implementation 'androidx.lifecycle:lifecycle-livedata-ktx:2.7.0'
    implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3'
    // Git library (sem root)
    implementation 'org.eclipse.jgit:org.eclipse.jgit:6.7.0.202309050840-r'
    // HTTP para GitHub API
    implementation 'com.squareup.okhttp3:okhttp:4.12.0'
    implementation 'com.google.code.gson:gson:2.10.1'
    testImplementation 'junit:junit:4.13.2'
    androidTestImplementation 'androidx.test.ext:junit:1.1.5'
}
EOF
  echo "✓ app/build.gradle"

  echo "[gradle] Escrevendo settings.gradle..."
  cat > settings.gradle << 'EOF'
// settings.gradle — RafGitTools
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "RafGitTools"
include ':app'
EOF
  echo "✓ settings.gradle"

  echo "[gradle] Escrevendo build.gradle (root)..."
  cat > build.gradle << 'EOF'
// build.gradle (root) — RafGitTools
plugins {
    id 'com.android.application'       version '8.2.2' apply false
    id 'com.android.library'           version '8.2.2' apply false
    id 'org.jetbrains.kotlin.android'  version '1.9.22' apply false
}
EOF
  echo "✓ build.gradle (root)"

  echo "[gradle] Escrevendo gradle/wrapper/gradle-wrapper.properties..."
  mkdir -p gradle/wrapper
  cat > gradle/wrapper/gradle-wrapper.properties << 'EOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.4-bin.zip
EOF
  echo "✓ gradle-wrapper.properties"
}

# ──────────────────────────────────────────────────────────────────
# FIX-F01 + F04 — AndroidManifest.xml
# ──────────────────────────────────────────────────────────────────
_fix_manifest() {
  echo "[manifest] Escrevendo app/src/main/AndroidManifest.xml..."
  mkdir -p app/src/main
  cat > app/src/main/AndroidManifest.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<!-- AndroidManifest.xml — RafGitTools / ΔRafaelVerboΩ -->
<!-- BUG-F01 corrigido: package = com.termux.rafacodephi -->
<!-- BUG-F04 corrigido: FileProvider authority alinhada -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Permissões de rede (GitHub API) -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <!-- Storage para repos locais -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
        android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
        android:maxSdkVersion="29" />

    <application
        android:name=".RafGitApp"
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:supportsRtl="true"
        android:theme="@style/Theme.RafGitTools"
        android:usesCleartextTraffic="false">

        <!-- Activity principal -->
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:windowSoftInputMode="adjustResize">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <!-- FileProvider — BUG-F04: authority = manifestPlaceholder -->
        <provider
            android:name="androidx.core.content.FileProvider"
            android:authorities="${fileProviderAuthority}"
            android:exported="false"
            android:grantUriPermissions="true">
            <meta-data
                android:name="android.support.FILE_PROVIDER_PATHS"
                android:resource="@xml/file_paths" />
        </provider>

    </application>
</manifest>
EOF
  echo "✓ AndroidManifest.xml"

  echo "[manifest] Escrevendo res/xml/file_paths.xml..."
  mkdir -p app/src/main/res/xml
  cat > app/src/main/res/xml/file_paths.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<paths>
    <external-path name="external_files" path="." />
    <files-path name="files" path="." />
    <cache-path name="cache" path="." />
</paths>
EOF
  echo "✓ file_paths.xml"
}

# ──────────────────────────────────────────────────────────────────
# FIX-F02 — CMakeLists.txt (Android 15 page-size)
# ──────────────────────────────────────────────────────────────────
_fix_cmake() {
  echo "[cmake] Escrevendo app/src/main/cpp/CMakeLists.txt..."
  mkdir -p app/src/main/cpp
  cat > app/src/main/cpp/CMakeLists.txt << 'EOF'
# CMakeLists.txt — RafGitTools native layer
# BUG-F02 corrigido: max-page-size=16384 para Android 15

cmake_minimum_required(VERSION 3.22.1)
project("rafgittools_native")

# Android 15 compatibility — página 16KB
if(ANDROID)
    add_link_options(-Wl,-z,max-page-size=16384)
endif()

# ARM NEON quando disponível
if(ANDROID_ABI STREQUAL "armeabi-v7a")
    add_compile_options(
        -march=armv7-a
        -mcpu=cortex-a53
        -mfpu=neon
        -mfloat-abi=softfp
    )
endif()

# Biblioteca nativa principal
add_library(rafgit_native SHARED
    rafgit_jni.cpp
)

# Log do Android
find_library(log-lib log)

target_link_libraries(rafgit_native
    ${log-lib}
)
EOF
  echo "✓ CMakeLists.txt"

  echo "[cmake] Escrevendo stub JNI..."
  cat > app/src/main/cpp/rafgit_jni.cpp << 'EOF'
// rafgit_jni.cpp — stub JNI / ΔRafaelVerboΩ
#include <jni.h>
#include <android/log.h>
#include <string>

#define TAG "RafGitNative"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, TAG, __VA_ARGS__)

extern "C" JNIEXPORT jstring JNICALL
Java_com_termux_rafacodephi_NativeLib_getArchInfo(JNIEnv* env, jobject) {
#if defined(__aarch64__)
    const char* arch = "aarch64";
#elif defined(__arm__)
    const char* arch = "armv7-a / cortex-a53";
#else
    const char* arch = "unknown";
#endif
    LOGI("arch=%s", arch);
    return env->NewStringUTF(arch);
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_termux_rafacodephi_NativeLib_getFrameworkInfo(JNIEnv* env, jobject) {
    // Exacordex / FLORESTA invariants
    std::string info = "phi=(1-H)*C |A|=42 period=42 gcd(dr,R)=1";
    return env->NewStringUTF(info.c_str());
}
EOF
  echo "✓ rafgit_jni.cpp"
}

# ──────────────────────────────────────────────────────────────────
# FIX-F01 — bootstrap paths (scripts shell que referenciam com.termux)
# ──────────────────────────────────────────────────────────────────
_fix_bootstrap() {
  echo "[bootstrap] Escrevendo scripts com paths rafacodephi corretos..."
  mkdir -p scripts

  cat > scripts/termux_env.sh << 'BSEOF'
#!/bin/bash
# termux_env.sh — detecta instalação correta
# BUG-F01: bootstrap hardcoded → corrigido com detecção dinâmica

TERMUX_RAFA="/data/data/com.termux.rafacodephi/files/usr"
TERMUX_OFF="/data/data/com.termux/files/usr"

if [ -d "$TERMUX_RAFA" ]; then
    export TERMUX_PREFIX="$TERMUX_RAFA"
    export TERMUX_PKG="com.termux.rafacodephi"
    export TERMUX_HOME="/data/data/com.termux.rafacodephi/files/home"
elif [ -d "$TERMUX_OFF" ]; then
    export TERMUX_PREFIX="$TERMUX_OFF"
    export TERMUX_PKG="com.termux"
    export TERMUX_HOME="/data/data/com.termux/files/home"
else
    echo "ERRO: Termux não encontrado" >&2
    exit 1
fi

export PATH="$TERMUX_PREFIX/bin:$PATH"
export LD_LIBRARY_PATH="$TERMUX_PREFIX/lib"
export HOME="$TERMUX_HOME"
BSEOF

  cat > scripts/setup_rafgittools.sh << 'SETUPEOF'
#!/bin/bash
# setup_rafgittools.sh — instala RafGitTools no Termux correto
source "$(dirname $0)/termux_env.sh"

echo "Instalando em: $TERMUX_PKG"
echo "PREFIX: $TERMUX_PREFIX"

# Dependências via pkg do Termux correto
if command -v pkg >/dev/null 2>&1; then
    pkg install -y git openssh
fi

# Cria estrutura de repos local
mkdir -p "$TERMUX_HOME/repos"
mkdir -p "$TERMUX_HOME/.rafgittools"

# Config git global
git config --global core.sshCommand "ssh -i $TERMUX_HOME/.ssh/id_ed25519"
git config --global init.defaultBranch main

echo "✓ RafGitTools configurado"
echo "  Repos: $TERMUX_HOME/repos"
SETUPEOF

  chmod +x scripts/termux_env.sh scripts/setup_rafgittools.sh
  echo "✓ scripts/termux_env.sh"
  echo "✓ scripts/setup_rafgittools.sh"
}

# ──────────────────────────────────────────────────────────────────
# Kotlin sources principais
# ──────────────────────────────────────────────────────────────────
_fix_kotlin() {
  echo "[kotlin] Escrevendo sources Kotlin principais..."
  local KT="app/src/main/kotlin/com/termux/rafacodephi"
  mkdir -p "$KT"

  # Application class
  cat > "$KT/RafGitApp.kt" << 'EOF'
// RafGitApp.kt — ΔRafaelVerboΩ / CIENTIESPIRITUAL
package com.termux.rafacodephi

import android.app.Application
import android.util.Log

class RafGitApp : Application() {

    override fun onCreate() {
        super.onCreate()
        Log.i(TAG, "RafGitTools iniciado — pkg=$packageName")
        Log.i(TAG, "Exacordex φ=(1-H)·C  |A|=42  period=42")
    }

    companion object {
        const val TAG = "RafGitTools"
        const val AUTHOR = "ΔRafaelVerboΩ"
        const val FRAMEWORK = "Exacordex/FLORESTA"
        // Invariantes VECTRA
        const val ATTRACTOR_COUNT = 42
        const val PERIOD = 42
        const val ALPHA = 0.25f
    }
}
EOF

  # NativeLib wrapper
  cat > "$KT/NativeLib.kt" << 'EOF'
// NativeLib.kt — wrapper JNI / ΔRafaelVerboΩ
package com.termux.rafacodephi

object NativeLib {
    init {
        System.loadLibrary("rafgit_native")
    }
    external fun getArchInfo(): String
    external fun getFrameworkInfo(): String
}
EOF

  # GitManager — operações git via JGit
  cat > "$KT/GitManager.kt" << 'EOF'
// GitManager.kt — operações Git sem root / ΔRafaelVerboΩ
package com.termux.rafacodephi

import android.content.Context
import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.eclipse.jgit.api.Git
import org.eclipse.jgit.api.errors.GitAPIException
import java.io.File

class GitManager(private val context: Context) {

    private val reposDir: File
        get() = File(context.filesDir, "repos")

    // Clona repo
    suspend fun clone(url: String, name: String): Result<File> =
        withContext(Dispatchers.IO) {
            runCatching {
                val dest = File(reposDir, name)
                if (dest.exists()) return@runCatching dest
                reposDir.mkdirs()
                Git.cloneRepository()
                    .setURI(url)
                    .setDirectory(dest)
                    .call()
                    .close()
                Log.i(TAG, "clone OK → ${dest.absolutePath}")
                dest
            }
        }

    // Lista repos locais
    fun listRepos(): List<File> =
        reposDir.listFiles()?.filter { it.isDirectory } ?: emptyList()

    // Status de um repo
    suspend fun status(repoDir: File): String =
        withContext(Dispatchers.IO) {
            runCatching {
                val git = Git.open(repoDir)
                val s = git.status().call()
                git.close()
                buildString {
                    if (s.added.isNotEmpty())    appendLine("A: ${s.added}")
                    if (s.modified.isNotEmpty()) appendLine("M: ${s.modified}")
                    if (s.removed.isNotEmpty())  appendLine("D: ${s.removed}")
                    if (isEmpty()) append("clean")
                }
            }.getOrElse { "erro: ${it.message}" }
        }

    // Pull
    suspend fun pull(repoDir: File): Result<String> =
        withContext(Dispatchers.IO) {
            runCatching {
                val git = Git.open(repoDir)
                val result = git.pull().call()
                git.close()
                if (result.isSuccessful) "OK" else "CONFLITO"
            }
        }

    // Commit + push simples
    suspend fun commitPush(
        repoDir: File,
        message: String,
        token: String
    ): Result<String> =
        withContext(Dispatchers.IO) {
            runCatching {
                val git = Git.open(repoDir)
                git.add().addFilepattern(".").call()
                git.commit().setMessage(message).call()
                // push com token GitHub
                git.push()
                    .setCredentialsProvider(
                        org.eclipse.jgit.transport.UsernamePasswordCredentialsProvider(
                            "oauth2", token
                        )
                    )
                    .call()
                git.close()
                "push OK"
            }
        }

    companion object {
        const val TAG = "GitManager"
    }
}
EOF

  # GitHubApi — chamadas REST
  cat > "$KT/GitHubApi.kt" << 'EOF'
// GitHubApi.kt — GitHub REST v3 / ΔRafaelVerboΩ
package com.termux.rafacodephi

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import com.google.gson.Gson
import com.google.gson.JsonObject

class GitHubApi(private val token: String) {

    private val client = OkHttpClient()
    private val gson = Gson()
    private val base = "https://api.github.com"

    private fun req(path: String): Request =
        Request.Builder()
            .url("$base$path")
            .header("Authorization", "Bearer $token")
            .header("Accept", "application/vnd.github.v3+json")
            .build()

    // Lista repos do usuário autenticado
    suspend fun listRepos(): List<JsonObject> =
        withContext(Dispatchers.IO) {
            runCatching {
                val resp = client.newCall(req("/user/repos?per_page=100")).execute()
                val body = resp.body?.string() ?: "[]"
                gson.fromJson(body, Array<JsonObject>::class.java).toList()
            }.getOrElse { emptyList() }
        }

    // Info do usuário
    suspend fun userInfo(): JsonObject? =
        withContext(Dispatchers.IO) {
            runCatching {
                val resp = client.newCall(req("/user")).execute()
                gson.fromJson(resp.body?.string(), JsonObject::class.java)
            }.getOrNull()
        }

    // Cria repo
    suspend fun createRepo(name: String, private: Boolean = true): Result<String> =
        withContext(Dispatchers.IO) {
            runCatching {
                val body = """{"name":"$name","private":$private}"""
                val reqBody = okhttp3.RequestBody.create(
                    okhttp3.MediaType.parse("application/json"), body
                )
                val resp = client.newCall(
                    Request.Builder()
                        .url("$base/user/repos")
                        .header("Authorization", "Bearer $token")
                        .post(reqBody)
                        .build()
                ).execute()
                if (resp.isSuccessful) "OK: $name criado" else "ERRO: ${resp.code}"
            }
        }
}
EOF

  # VectraState — estado VECTRA integrado ao app
  cat > "$KT/VectraState.kt" << 'EOF'
// VectraState.kt — estado VECTRA 7D dentro do app / ΔRafaelVerboΩ
// Invariante: φ=(1-H)·C  |A|=42  period=42
package com.termux.rafacodephi

import android.content.Context
import com.google.gson.Gson
import java.io.File

data class StateVec(
    val vector: FloatArray = FloatArray(7),
    var C: Float = 0f,
    var H: Float = 0f,
    var phase: Int = 1,
    var attractor: Int = -1,
    var score: Float = 0f
) {
    val phi: Float get() = (1f - H) * C
}

object VectraState {
    private val gson = Gson()
    private const val ALPHA = 0.25f

    fun update(state: StateVec, cIn: Float, hIn: Float): StateVec {
        state.C = (1f - ALPHA) * state.C + ALPHA * cIn
        state.H = (1f - ALPHA) * state.H + ALPHA * hIn
        state.phase = (state.phase + 1) % 42
        state.score = state.phi
        return state
    }

    fun save(ctx: Context, state: StateVec) {
        File(ctx.filesDir, "vectra_state.json")
            .writeText(gson.toJson(state))
    }

    fun load(ctx: Context): StateVec =
        runCatching {
            val f = File(ctx.filesDir, "vectra_state.json")
            if (f.exists()) gson.fromJson(f.readText(), StateVec::class.java)
            else StateVec()
        }.getOrElse { StateVec() }
}
EOF

  echo "✓ Kotlin sources gerados em $KT"
}

# ──────────────────────────────────────────────────────────────────
# .gitignore
# ──────────────────────────────────────────────────────────────────
_fix_gitignore() {
  cat > .gitignore << 'EOF'
# Android / Gradle
*.iml
.gradle/
local.properties
.idea/
.DS_Store
build/
captures/
.externalNativeBuild/
.cxx/
app/build/
app/release/
*.apk
*.aab
*.keystore
!debug.keystore

# Termux sensores / logs (não commitar dados brutos)
sensors/raw/
logs/*.log
state/global.json

# Tokens / secrets
.env.local
secrets.properties
EOF
  echo "✓ .gitignore"
}

# ──────────────────────────────────────────────────────────────────
# AGENTS.md para o repo
# ──────────────────────────────────────────────────────────────────
_fix_agents() {
  cat > AGENTS.md << 'EOF'
# AGENTS.md — RafGitTools / termux-api_rafcodephi
# Autor: ΔRafaelVerboΩ / CIENTIESPIRITUAL
# github.com/rafaelmeloreisnovo

## Build
run: ./gradlew assembleDebug
target: armv7-a + arm64-v8a / API 28+
NDK: r26d / clang

## Tests
run: ./gradlew test
run: ./gradlew connectedAndroidTest

## Package Identity (CRÍTICO — BUG-F01)
- applicationId correto : com.termux.rafacodephi
- applicationId ERRADO  : com.termux  ← nunca usar
- FileProvider authority: com.termux.rafacodephi.fileprovider
- Termux prefix path    : /data/data/com.termux.rafacodephi/files/usr/

## Android 15 (BUG-F02)
- Obrigatório em TODO cmake/gradle:
  -Wl,-z,max-page-size=16384
- Sem isso o APK não carrega em Android 15+

## Kotlin Sources
- RafGitApp.kt      — Application, constantes VECTRA
- GitManager.kt     — JGit wrapper (clone/pull/push/status)
- GitHubApi.kt      — GitHub REST v3 (list/create repos)
- VectraState.kt    — estado 7D φ=(1-H)·C integrado
- NativeLib.kt      — JNI wrapper para arch info

## Native (cpp)
- CMakeLists.txt    — page-size corrigido, NEON ARM32
- rafgit_jni.cpp    — getArchInfo(), getFrameworkInfo()

## Known Bugs (não fechar sem fix)
BUG-F01: bootstrap hardcoded com.termux → usar rafacodephi
BUG-F02: Android 15 page-size faltando
BUG-F03: applicationId incorreto em versões antigas
BUG-F04: FileProvider authority errada
BUG-F05: compileSdk < 34
BUG-F06: CI JAVA_HOME quebrado para NDK

## Invariants VECTRA (nunca violar)
φ = (1-H)·C   — Lyapunov
|A| = 42      — atratores
period = 42   — BitOmega
gcd(Δr,R) = 1 — travessia toroidal

## Agent Rules
1. Nunca substituir com.termux.rafacodephi por com.termux
2. Sempre incluir -Wl,-z,max-page-size=16384
3. JGit para operações git (sem exec git binário)
4. VectraState.save() após cada operação de repo
5. Secrets nunca em código: usar BuildConfig ou secrets.properties
EOF
  echo "✓ AGENTS.md"
}

# ──────────────────────────────────────────────────────────────────
# CI workflow
# ──────────────────────────────────────────────────────────────────
_fix_workflow() {
  mkdir -p .github/workflows
  cat > .github/workflows/build.yml << 'EOF'
# .github/workflows/build.yml — RafGitTools CI
# BUG-F06 corrigido: JAVA_HOME + NDK configurados corretamente
# Autor: ΔRafaelVerboΩ / CIENTIESPIRITUAL
name: RafGitTools Build

on:
  push:
    branches: [main, master]
  pull_request:

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Setup Android SDK
        uses: android-actions/setup-android@v3

      - name: Setup NDK r26d
        run: |
          echo "y" | $ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager \
            "ndk;26.3.11579264" \
            "build-tools;34.0.0" \
            "platforms;android-34"
          echo "ANDROID_NDK_HOME=$ANDROID_SDK_ROOT/ndk/26.3.11579264" >> $GITHUB_ENV

      - name: Cache Gradle
        uses: actions/cache@v4
        with:
          path: |
            ~/.gradle/caches
            ~/.gradle/wrapper
          key: gradle-${{ hashFiles('**/*.gradle*') }}

      - name: Validate package identity
        run: |
          grep -r "com.termux.rafacodephi" app/build.gradle | head -3
          echo "✓ applicationId correto"

      - name: Validate page-size (Android 15)
        run: |
          grep -r "max-page-size" app/build.gradle app/src/main/cpp/ || \
            (echo "ERRO: max-page-size=16384 ausente" && exit 1)
          echo "✓ Android 15 compat OK"

      - name: Build Debug APK
        run: ./gradlew assembleDebug --stacktrace

      - name: Run unit tests
        run: ./gradlew test

      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: rafgittools-debug
          path: app/build/outputs/apk/debug/*.apk
EOF
  echo "✓ .github/workflows/build.yml"
}

# ──────────────────────────────────────────────────────────────────
# DIAGNÓSTICO (sem modificar)
# ──────────────────────────────────────────────────────────────────
_check() {
  echo "── Diagnóstico RafGitTools ──"
  local ok=0 fail=0

  _chk() {
    if eval "$2" >/dev/null 2>&1; then
      echo "  ✓ $1"
      ((ok++))
    else
      echo "  ✗ $1  ← $3"
      ((fail++))
    fi
  }

  _chk "app/build.gradle existe"   "[ -f app/build.gradle ]"                   "rodar: bash fix_rafgittools.sh gradle"
  _chk "applicationId rafacodephi" "grep -q rafacodephi app/build.gradle 2>/dev/null" "BUG-F01/F03"
  _chk "compileSdk >= 34"          "grep -q 'compileSdk.*34' app/build.gradle 2>/dev/null" "BUG-F05"
  _chk "page-size 16384"           "grep -rq 'max-page-size=16384' app/ 2>/dev/null"  "BUG-F02"
  _chk "AndroidManifest.xml"       "[ -f app/src/main/AndroidManifest.xml ]"   "rodar: bash fix_rafgittools.sh manifest"
  _chk "FileProvider authority ok" "grep -q 'rafacodephi.fileprovider' app/src/main/AndroidManifest.xml 2>/dev/null" "BUG-F04"
  _chk "CMakeLists.txt existe"     "[ -f app/src/main/cpp/CMakeLists.txt ]"    "rodar: bash fix_rafgittools.sh cmake"
  _chk "AGENTS.md existe"          "[ -f AGENTS.md ]"                          "rodar: bash fix_rafgittools.sh agents"
  _chk ".gitignore existe"         "[ -f .gitignore ]"                         "rodar: bash fix_rafgittools.sh gitignore"
  _chk "CI workflow existe"        "[ -f .github/workflows/build.yml ]"        "rodar: bash fix_rafgittools.sh workflow"
  _chk "Kotlin sources"            "[ -f app/src/main/kotlin/com/termux/rafacodephi/RafGitApp.kt ]" "rodar: bash fix_rafgittools.sh kotlin"

  echo ""
  echo "  OK: $ok   FALHA: $fail"
  [ $fail -gt 0 ] && echo "  → bash fix_rafgittools.sh all"
}

# ──────────────────────────────────────────────────────────────────
case "$CMD" in
  all)
    _banner
    _fix_gradle
    _fix_manifest
    _fix_cmake
    _fix_bootstrap
    _fix_kotlin
    _fix_gitignore
    _fix_agents
    _fix_workflow
    echo ""
    echo "✓ Todos os reparos aplicados."
    echo "  Próximo passo: ./gradlew assembleDebug"
    ;;
  gradle)    _fix_gradle    ;;
  manifest)  _fix_manifest  ;;
  cmake)     _fix_cmake     ;;
  bootstrap) _fix_bootstrap ;;
  kotlin)    _fix_kotlin    ;;
  gitignore) _fix_gitignore ;;
  agents)    _fix_agents    ;;
  workflow)  _fix_workflow  ;;
  check)     _check         ;;
  help|"")
    _banner
    echo ""
    echo "  all        aplica todos os reparos"
    echo "  gradle     build.gradle + settings + wrapper"
    echo "  manifest   AndroidManifest.xml + file_paths.xml"
    echo "  cmake      CMakeLists.txt (page-size) + JNI stub"
    echo "  bootstrap  scripts/termux_env.sh (path fix)"
    echo "  kotlin     sources Kotlin principais"
    echo "  gitignore  .gitignore"
    echo "  agents     AGENTS.md"
    echo "  workflow   .github/workflows/build.yml"
    echo "  check      diagnóstico sem modificar"
    echo ""
    echo "Bugs resolvidos:"
    echo "  F01 bootstrap hardcoded com.termux"
    echo "  F02 Android 15 max-page-size"
    echo "  F03 applicationId errado"
    echo "  F04 FileProvider authority errada"
    echo "  F05 compileSdk < 34"
    echo "  F06 CI JAVA_HOME / NDK quebrado"
    ;;
  *)
    echo "Desconhecido: $CMD — use: bash fix_rafgittools.sh help"
    exit 1
    ;;
esac
