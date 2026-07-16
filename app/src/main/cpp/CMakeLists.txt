cmake_minimum_required(VERSION 3.22.1)
project(vectra_pulse C ASM)

add_library(vectra_pulse SHARED
    ${CMAKE_CURRENT_SOURCE_DIR}/../../../native/vectra_pulse.S
    vectra_pulse_jni.c
)

# ABI-specific assembler flags
if(ANDROID_ABI STREQUAL "arm64-v8a")
    target_compile_options(vectra_pulse PRIVATE
        $<$<COMPILE_LANGUAGE:ASM>:-march=armv8-a+crc+simd>
    )
elseif(ANDROID_ABI STREQUAL "armeabi-v7a")
    target_compile_options(vectra_pulse PRIVATE
        $<$<COMPILE_LANGUAGE:ASM>:-march=armv7-a -mfpu=neon>
    )
endif()

target_compile_options(vectra_pulse PRIVATE
    $<$<COMPILE_LANGUAGE:C>:-std=c11 -O3 -fvisibility=hidden -ffunction-sections -fdata-sections>
)

target_link_options(vectra_pulse PRIVATE -Wl,--gc-sections)

target_link_libraries(vectra_pulse log)
