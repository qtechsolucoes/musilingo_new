// FASE 1.4: Headers FFI - Configuração do header principal do plugin Verovio
#pragma once

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#if _WIN32
#include <windows.h>
#else
#include <pthread.h>
#include <unistd.h>
#endif

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#elif defined(__ANDROID__) || defined(ANDROID)
#define FFI_PLUGIN_EXPORT __attribute__((visibility("default"))) __attribute__((used))
#else
#define FFI_PLUGIN_EXPORT __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

// FASE 2.1.1: Inicialização do Verovio Engine
FFI_PLUGIN_EXPORT int verovio_initialize(void);

// FASE 2.1.2: Configuração de opções de renderização
FFI_PLUGIN_EXPORT int verovio_set_options(const char* options_json);

// FASE 2.1.3: Carregamento de MusicXML
FFI_PLUGIN_EXPORT int verovio_load_data(const char* musicxml);

// FASE 2.1.4: Renderização para SVG
FFI_PLUGIN_EXPORT const char* verovio_render_to_svg(int page_number);

// FASE 2.1.5: Obter informações da partitura
FFI_PLUGIN_EXPORT int verovio_get_page_count(void);

// FASE 2.1.6: Coloração de elementos musicais
FFI_PLUGIN_EXPORT const char* verovio_get_element_attr(const char* xml_id);

// FASE 2.1.7: Obter elementos por posição (para interação)
FFI_PLUGIN_EXPORT const char* verovio_get_elements_at_time(int time_ms);

// FASE 2.1.8: Obter informações MIDI
FFI_PLUGIN_EXPORT const char* verovio_render_to_midi(void);

// FASE 2.1.9: Validação de MusicXML
FFI_PLUGIN_EXPORT int verovio_validate_musicxml(const char* musicxml);

// FASE 2.1.10: Conversão de formatos
FFI_PLUGIN_EXPORT const char* verovio_convert_file(const char* data, const char* from_format);

// FASE 2.1.11: Limpeza de recursos
FFI_PLUGIN_EXPORT void verovio_cleanup(void);

// FASE 2.1.12: Obter versão do Verovio
FFI_PLUGIN_EXPORT const char* verovio_get_version(void);

#ifdef __cplusplus
}
#endif
